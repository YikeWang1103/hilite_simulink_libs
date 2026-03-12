function subsystemHandle = create_can_message_parser_block(target_message, model_name, can_message_parser_block_position)
    % 根据DBC消息结构体创建Simulink子系统
    % 输入:
    %   target_message - DBC消息结构体
    %   model_name - 目标模型名称
        
    % 检查函数输入合理性
    model_name = check_function_inputs(target_message, model_name);

    % 检查模型是否存在，如果不存在则创建
    check_model_existency(model_name);
    
    % 获得model workspace
    mdlWks = get_param('can_message_parser_block', 'ModelWorkspace');

    % 创建can_message_parser子模块
    subsystem_name = ['CAN_Message_' num2str(target_message.message_id)];
    add_can_parser_subsystem(model_name, subsystem_name, can_message_parser_block_position);
            
    % 添加Inport
    subsystem_path = [model_name '/' subsystem_name];
    % inport_name = 'input_data';
    % inport_position = [30, 190, 50, 200];
    % add_inport(subsystem_path, inport_name, inport_position);

    % 计算输出端口数量和位置
    num_signals = length(target_message.signals);

    % 定义block的尺寸
    block_height = 400;  % Signal Parser模块的高度为400
    block_distance = 80;  % 模块间的距离为80
    
    % 为每个信号添加Signal Parser模块
    for i = 1:num_signals
        % 检查信号是否是结构体
        if isstruct(target_message.signals{i})
            signal_info = target_message.signals{i};
        else
            error(['信号 ', num2str(i), ' 不是有效的结构体']);
        end
        
        % 创建Signal Parser模块 - 宽度200，高度400, 间距80
        signal_parser_block_name = signal_info.signal_name;
        y_pos = block_height + (i-1) * (block_height + block_distance);  % 从初始位置开始，每个模块占用高度+距离的空间
        signal_parser_block_position = [70 y_pos 270 y_pos+block_height];
        add_signal_parser_block(subsystem_path, signal_parser_block_name, signal_parser_block_position);
        % connect_ports(subsystem_path, inport_name, 1, signal_parser_block_name, 1)
                
        % 创建Outport - 创建Outport模块高度为10，居中对齐Signal Parser模块
        port_number = i;
        outport_name = [num2str(target_message.message_id) '_' signal_info.signal_name];
        out_center_y = y_pos + block_height/2;
        outport_position = [320 out_center_y-5 340 out_center_y+5];
        add_outport(subsystem_path, port_number, outport_name, outport_position);
        connect_ports(subsystem_path, signal_parser_block_name, 1, outport_name, 1)

        add_signal_param_blocks(subsystem_path, mdlWks, signal_parser_block_name, target_message.message_id, signal_info);
        Simulink.BlockDiagram.arrangeSystem(subsystem_path, FullLayout='true');
    end

    inport_name = 'input_data';
    inport_position = [-230, 220, -210, 230];
    add_inport(subsystem_path, inport_name, inport_position);

     for i = 1:num_signals
        % 检查信号是否是结构体
        if isstruct(target_message.signals{i})
            signal_info = target_message.signals{i};
        else
            error(['信号 ', num2str(i), ' 不是有效的结构体']);
        end

        signal_parser_block_name = signal_info.signal_name;
        connect_ports(subsystem_path, inport_name, 1, signal_parser_block_name, 1);
    end

    Simulink.BlockDiagram.arrangeSystem(subsystem_path);

    fprintf('成功创建CAN消息解析器子系统: %s\n', subsystem_path);
    fprintf('消息ID: %d\n', target_message.message_id);
    
    if isfield(target_message, 'message_name')
        fprintf('消息名称: %s\n', target_message.message_name);
    end
    
    fprintf('信号数量: %d\n', num_signals);
    
    for i = 1:num_signals
        if isstruct(target_message.signals{i})
            signal_info = target_message.signals{i};
            if isfield(signal_info, 'signal_name') && isfield(signal_info, 'start_bit') && isfield(signal_info, 'length')
                fprintf('  信号 %d: %s (起始位: %d, 长度: %d)', ...
                    i, signal_info.signal_name, signal_info.start_bit, signal_info.length);
                
                if isfield(signal_info, 'factor') && isfield(signal_info, 'offset')
                    fprintf(', 因子: %g, 偏移: %g', signal_info.factor, signal_info.offset);
                end
                fprintf('\n');
            else
                fprintf('  信号 %d: 信号%d (缺少详细信息)\n', i, i);
            end
        else
            fprintf('  信号 %d: 信号%d (非结构体格式)\n', i, i);
        end
    end
end

function model_name = check_function_inputs(target_message, model_name)
    if nargin < 2
        model_name = 'untitled'; % 默认模型名
    end
    
    % 检查输入参数的有效性
    if ~isstruct(target_message)
        error('target_message 必须是一个结构体');
    end
    
    % 检查必需字段是否存在
    if ~isfield(target_message, 'message_id')
        error('target_message 必须包含 message_id 字段');
    end
    
    if ~isfield(target_message, 'signals')
        error('target_message 必须包含 signals 字段');
    end
end

function check_model_existency(model_name)
    if bdIsLoaded(model_name)
        open_system(model_name);
    else
        new_system(model_name);
        open_system(model_name);
    end
end

function add_can_parser_subsystem(model_name, subsystem_name, position)
    % 检查是否已存在同名子系统，如果存在则删除
    existing_blocks = find_system(model_name, 'Name', subsystem_name, 'Type', 'block');   
    if ~isempty(existing_blocks)
        delete_block(existing_blocks{1});  % 删除已存在的子系统
    end
    
    % 定义子系统路径
    subsystem_path = [model_name '/' subsystem_name];

    add_block('simulink/Ports & Subsystems/Subsystem', subsystem_path);
    
    % 设置子系统位置
    set_param(subsystem_path, 'Position', position);
    
    clear_subsystem_elements(subsystem_path);
end

function add_inport(subsystem_path, inport_name, inport_position)
    inport_path = [subsystem_path '/' inport_name];
    add_block('simulink/Sources/In1', inport_path);
    set_param(inport_path, 'Port', '1');
    set_param(inport_path, 'IconDisplay', 'Port number');
    set_param(inport_path, 'Position', inport_position);
    % set_param(inport_path, 'Name', 'input_data');
end

function add_signal_parser_block(subsystem_path, block_name, block_position)
    block_path = [subsystem_path '/' block_name];
    add_block('hilite_simulink_libs/Communication Message Parser/Signal Parser', block_path);
    set_param(block_path, 'Position', block_position);
end

function add_outport(subsystem_path, port_number, outport_name, outport_position)
    outport_path = [subsystem_path '/' outport_name];
    add_block('simulink/Sinks/Out1', outport_path);
    set_param(outport_path, 'Port', num2str(port_number));
    set_param(outport_path, 'IconDisplay', 'Port number');
    set_param(outport_path, 'Position', outport_position);
end

function connect_ports(subsystem_path, src_block_name, src_block_port, dst_block_name, dst_block_port)
    src_port = [src_block_name '/' num2str(src_block_port)];  % Signal Parser的输出端口
    dst_port = [dst_block_name '/' num2str(dst_block_port)];  % Out端口的输入端口
    add_line(subsystem_path, src_port, dst_port,'AUTOROUTING','ON')
    % add_line(subsystem_path, src_port, dst_port)
end

function add_signal_param_blocks(subsystem_path, model_workspace, signal_parser_block_name, message_id, signal_info)
    % 在model workspace中创建一个变量，变量名为message id、信号名和startBit的字符组合，变量类型为int8
    msg_id_signal_name = [num2str(message_id) '_' signal_info.signal_name];

    add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, [msg_id_signal_name '_startBit'], 'int8', signal_info.start_bit, 2);
    add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, [msg_id_signal_name '_length'], 'int8', signal_info.length, 3);

    if signal_info.value_type == '+'
        is_signed = false;
    else
        is_signed = true;
    end

    add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, [msg_id_signal_name '_isSigned'], 'bool', is_signed, 4);
    add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, [msg_id_signal_name '_factor'], 'double', signal_info.factor, 5);
    add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, [msg_id_signal_name '_offset'], 'double', signal_info.offset, 6);
    add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, [msg_id_signal_name '_isBigEndian'], 'bool', signal_info.byte_order, 7);
end

function add_signal_param_block(subsystem_path, model_workspace, signal_parser_block_name, param_block_name, parameter_type, parameter_value, port_number)
    parameter_name = ['Param_' param_block_name];
    add_simulink_parameter(model_workspace, parameter_name, parameter_type, parameter_value);
    add_constant(subsystem_path, param_block_name, parameter_name);
    connect_ports(subsystem_path, param_block_name, 1, signal_parser_block_name, port_number);
end

function add_simulink_parameter(model_workspace, parameter_name_with_prefix, parameter_type, parameter_value)
    simParamObj = Simulink.Parameter;
    simParamObj.Value = parameter_value;
    simParamObj.DataType = parameter_type;
    model_workspace.assignin(parameter_name_with_prefix, simParamObj);
end

function add_constant(subsystem_path, block_name, block_value)
    block_path = [subsystem_path '/' block_name];
    add_block('simulink/Sources/Constant', block_path);
    set_param(block_path, 'Value', block_value);
end

% 辅助函数：清空子系统内的所有元素（端口和信号线）
function clear_subsystem_elements(subsystem_path)
    % 删除子系统内的所有信号线 - 正确的方法
    % 方法1: 查找所有line对象并删除
    all_lines = find_system(subsystem_path, 'FindAll', 'on', 'Type', 'Line');
    for i = 1:length(all_lines)
        try
            delete_line(subsystem_path, all_lines{i});
        catch
            % 如果删除失败，继续处理下一个
            continue;
        end
    end
    
    % 方法2: 使用另一种方式查找并删除信号线
    line_objs = find_system(subsystem_path, 'Type', 'line');
    for i = 1:length(line_objs)
        try
            delete_line(subsystem_path, line_objs{i});
        catch
            continue;
        end
    end

    % 删除子系统内的所有Inport
    existing_inports = find_system(subsystem_path, 'BlockType', 'Inport');
    for i = 1:length(existing_inports)
        delete_block(existing_inports{i});
    end
    
    % 删除子系统内的所有Outport (Out1)
    existing_outports = find_system(subsystem_path, 'BlockType', 'Outport');
    for i = 1:length(existing_outports)
        delete_block(existing_outports{i});
    end
    
    % 删除子系统内的其他可能存在的块
    other_blocks = find_system(subsystem_path, 'BlockType', 'Selector');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'BusCreator');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'BusSelector');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'Bitwise Operator');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'Shift Arithmetic');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'Product');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'Add');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'Gain');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'Constant');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
    
    other_blocks = find_system(subsystem_path, 'BlockType', 'hilite_simulink_libs/Communication Message Parser/Signal Parser');
    for i = 1:length(other_blocks)
        delete_block(other_blocks{i});
    end
end