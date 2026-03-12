function target_message = parse_dbc_file(filename, message_id)
    % 解析DBC文件，提取指定message的信息
    
    % 读取DBC文件内容
    fid = fopen(filename, 'r');
    if fid == -1
        error('无法打开文件: %s', filename);
    end
    content = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    lines = content{1};
    
    % 初始化目标消息结构体
    target_message.message_name = '';
    target_message.message_id = message_id;
    target_message.message_dlc = 0;
    target_message.message_cycle_time = 0;
    target_message.message_comments = '';
    target_message.message_type = '';
    target_message.message_GenMsgCycleTime = 0;
    target_message.signals = {};
    
    % 提取所有信号初始值定义
    signal_initial_values = extract_all_signal_initial_values(lines);
    
    % 寻找目标消息
    target_found = false;
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        % 匹配消息定义行
        if startsWith(line, sprintf('BO_ %d ', message_id))
            % 提取消息信息
            tokens = regexp(line, 'BO_\s+(\d+)\s+([A-Za-z0-9_]+):\s+(\d+)\s+([A-Za-z0-9_]+)', 'tokens');
            if ~isempty(tokens)
                token = tokens{1};
                target_message.message_name = token{2};
                target_message.message_dlc = str2double(token{3});
                target_message.message_type = token{4};
                target_found = true;
            end
            
            % 继续处理该消息下的信号
            j = i + 1;
            while j <= length(lines)
                signal_line = strtrim(lines{j});
                
                % 如果遇到下一个消息定义或空行，则停止
                if startsWith(signal_line, 'BO_ ') || isempty(signal_line)
                    break;
                end
                
                % 匹配信号定义行
                if startsWith(signal_line, 'SG_ ')
                    signal_info = extract_signal_info(signal_line, message_id);
                    if ~isempty(signal_info)
                        % 从预提取的初始值中查找当前信号的初始值
                        % 在查找时结合消息ID和信号名称
                        initial_value = find_signal_initial_value(signal_initial_values, message_id, signal_info.signal_name);
                        signal_info.initial_value = initial_value;
                        
                        % 将信号结构体添加到信号数组中
                        target_message.signals{end+1} = signal_info;
                    end
                end
                
                j = j + 1;
            end
        end
        
        % 查找消息注释
        if contains(line, sprintf('CM_ BO_ %d "', message_id))
            comment_tokens = regexp(line, sprintf('CM_ BO_ %d "(.*)"', message_id), 'tokens');
            if ~isempty(comment_tokens)
                target_message.message_comments = comment_tokens{1}{1};
            end
        end
        
        % 查找消息周期时间
        if contains(line, sprintf('BA_ "GenMsgCycleTime" BO_ %d', message_id))
            cycle_time_pattern = sprintf('BA_ "GenMsgCycleTime" BO_ %d (\\d+)', message_id);
            cycle_time_match = regexp(line, cycle_time_pattern, 'tokens');
            if ~isempty(cycle_time_match)
                target_message.message_GenMsgCycleTime = str2double(cycle_time_match{1}{1});
            end
        end
    end
    
    if ~target_found
        warning('未找到ID为%d的消息', message_id);
        return;
    end
    
    % 设置默认的message_cycle_time
    target_message.message_cycle_time = target_message.message_GenMsgCycleTime;
end

function signal_info = extract_signal_info(signal_line, message_id)
    % 提取信号信息
    signal_info = struct(...
        'signal_name', '', ...
        'start_bit', 0, ...
        'length', 0, ...
        'byte_order', 0, ...
        'value_type', '', ...
        'factor', 0, ...
        'offset', 0, ...
        'min_value', 0, ...
        'max_value', 0, ...
        'unit', '', ...
        'receiver', '', ...
        'initial_value', 0, ...
        'comment', '');
    
    % 正则表达式匹配信号格式: SG_ name : startBit|length@byteOrder (factor,offset) [min|max] "unit" receiver
    pattern = 'SG_\s+([A-Za-z0-9_]+)\s*:\s*(\d+)\|(\d+)@([01])([+-])\s*\(([^,]+),([^)]+)\)\s*\[([^\]]+)\]\s*"([^"]*)"\s+([A-Za-z0-9_]+)';
    matches = regexp(signal_line, pattern, 'tokens');
    
    if isempty(matches)
        % 尝试另一种格式（空单位）
        pattern = 'SG_\s+([A-Za-z0-9_]+)\s*:\s*(\d+)\|(\d+)@([01])([+-])\s*\(([^,]+),([^)]+)\)\s*\[([^\]]+)\]\s*""\s+([A-Za-z0-9_]+)';
        matches = regexp(signal_line, pattern, 'tokens');
    end
    
    if ~isempty(matches)
        match = matches{1};
        signal_info.signal_name = match{1};
        signal_info.start_bit = str2double(match{2});
        signal_info.length = str2double(match{3});
        signal_info.byte_order = str2double(match{4}); % 0=Motorola, 1=Intel
        signal_info.value_type = match{5}; % + or -
        signal_info.factor = str2double(match{6});
        signal_info.offset = str2double(match{7});
        
        % 解析最小值和最大值
        min_max_str = match{8};
        min_max_parts = strsplit(min_max_str, '|');
        if length(min_max_parts) >= 2
            signal_info.min_value = str2double(min_max_parts{1});
            signal_info.max_value = str2double(min_max_parts{2});
        else
            signal_info.min_value = 0;
            signal_info.max_value = 0;
        end
        
        if length(match) >= 9
            signal_info.unit = match{9};
        else
            signal_info.unit = '';
        end
        
        signal_info.receiver = match{end};
        
        % 初始化其他字段
        signal_info.initial_value = 0; % 会在主函数中更新
        
        % 查找信号注释
        signal_info.comment = get_signal_comment(signal_line, signal_info.signal_name, message_id);
    end
end

function signal_initial_values = extract_all_signal_initial_values(lines)
    % 提取所有信号的初始值定义，返回一个结构体数组
    signal_initial_values = {};
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        % 匹配信号初始值定义 BA_ "GenSigStartValue" SG_ msgId signalName value
        if startsWith(line, 'BA_ "GenSigStartValue" SG_')
            pattern = 'BA_ "GenSigStartValue" SG_ (\d+) ([A-Za-z0-9_]+) ([0-9.-]+)';
            matches = regexp(line, pattern, 'tokens');
            
            if ~isempty(matches)
                match = matches{1};
                msg_id = str2double(match{1});
                signal_name = match{2};
                initial_value = str2double(match{3});
                
                % 创建包含消息ID、信号名称和初始值的结构体
                new_entry = struct('message_id', msg_id, 'signal_name', signal_name, 'initial_value', initial_value);
                signal_initial_values{end+1} = new_entry;
            end
        end
    end
end

function initial_value = find_signal_initial_value(signal_initial_values, message_id, signal_name)
    % 根据消息ID和信号名称查找初始值
    initial_value = 0; % 默认值
    
    for i = 1:length(signal_initial_values)
        if signal_initial_values{i}.message_id == message_id && ...
           strcmp(signal_initial_values{i}.signal_name, signal_name)
            initial_value = signal_initial_values{i}.initial_value;
            return;
        end
    end
end

function comment = get_signal_comment(signal_line, signal_name, message_id)
    % 查找信号注释
    comment = '';
end
