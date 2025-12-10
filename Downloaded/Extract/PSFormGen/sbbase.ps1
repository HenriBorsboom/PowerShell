$parm = "Psw,psw,txt password;cmb,combo,,,g,a:alfa|beta|g:gamma|delta;list,combo2,,25,,a:aleph|bet|g:gimel|dalet"
$parm += ";Chk,check,Check box,,"
.\formgenbase.ps1 -widgets $parm -title "Try Form Generator" -background "lightgreen"
""
"********* data **********"
$fg_data
"*************************"
