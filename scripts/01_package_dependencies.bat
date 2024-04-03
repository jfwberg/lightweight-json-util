REM --------------------------------------------------------
REM MANGED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)  -
REM --------------------------------------------------------
rem Lightweight - Apex Unit Test Util v2@2.4.0-2
sf package install --package "04tP3000000M6OXIA0" -w 30

REM Lightweight - Apex LWC Util@0.3.0-3
sf package install --package "04tP3000000R7F7IAK" -w 30


REM --------------------------------------------------------
REM UNLOCKED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)-
REM --------------------------------------------------------
rem Lightweight - Apex Unit Test Util v2 (Unlocked)@2.4.0-2
sf package install -package "04tP3000000M6Q9IAK" -w 30

REM Lightweight - Apex LWC Util@0.3.0-1 (Unlocked)
sf package install --package "04tP3000000R7GjIAK" -w 30


REM --------------------------------------------------------
REM                  ASSIGN PERMISSION SETS                -
REM --------------------------------------------------------
sf org assign permset --name "Lightweight_Apex_Unit_Test_Util_v2"
sf org assign permset --name "Lightweight_LWC_Util"

REM After push
sf org assign permset --name "Lightweight_JSON_Util"