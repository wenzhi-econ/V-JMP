/* 
This do file installs necessary community-contributed packages to a directory in the project folder.

RA: WWZ
Date installed: 2025-02-25
*/

capture mkdir "${user}/stata_libraries"
net set ado "${user}/stata_libraries"

foreach pkg in egenmore ftools reghdfe ppmlhdfe xlincom balancetable estout coefplot grstyle palettes colrspace schemepack mediation binscatter {
    local website_folder = substr("`pkg'", 1, 1)
    net from "http://fmwww.bc.edu/repec/bocode/`website_folder'"
    net install `pkg', replace
}

foreach pkg in winsor2 {
    local website_folder = substr("`pkg'", 1, 1)
    net from "http://fmwww.bc.edu/repec/bocode/`website_folder'"
    net install `pkg', replace
}

foreach pkg in ietoolkit {
    local website_folder = substr("`pkg'", 1, 1)
    net from "http://fmwww.bc.edu/repec/bocode/`website_folder'"
    net install `pkg', replace
}
