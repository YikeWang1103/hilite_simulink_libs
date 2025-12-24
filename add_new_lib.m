% new_system("hilite_simulink_libs","Library");
open_system("hilite_simulink_libs");
load_system("hilite_simulink_libs");
set_param("hilite_simulink_libs","Lock","off");
set_param("hilite_simulink_libs","EnableLBRepository","on")
save_system("hilite_simulink_libs");