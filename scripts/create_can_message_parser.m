% define path of .dbc file, target message ID and model name
dbcFilePath = 'C:\Yike Wang\00_workspace\projects\robot_actuators\imperix_tutorial\can_message\dbc\robot_actuator.dbc';
messageID = 0x181;
modelName = 'can_message_parser_block';
sfunc_module_suffix = '.cpp';

% extract target message and signal information in .dbc file
target_message = parse_dbc_file(dbcFilePath, messageID);

% generate simulink block for target message parser
can_message_parser_block_position = [100 100 300 200];
create_can_message_parser_block(target_message, modelName, can_message_parser_block_position, sfunc_module_suffix);