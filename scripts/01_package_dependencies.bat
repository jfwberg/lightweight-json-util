REM --------------------------------------------------------
REM MANGED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)  -
REM --------------------------------------------------------
REM Managed package - Lightweight - Apex Unit Test Util v2@2.4.0-1
sf package install --package 04tP3000000M6OXIA0 -w 30


REM --------------------------------------------------------
REM UNLOCKED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)-
REM --------------------------------------------------------
REM Unlocked package - Lightweight - Apex Unit Test Util v2 (Unlocked)@2.4.0-1
sf package install --package 04tP3000000M6Q9IAK -w 30


REM --------------------------------------------------------
REM                  ASSIGN PERMISSION SETS                -
REM --------------------------------------------------------
sf org assign permset --name "Lightweight_Apex_Unit_Test_Util_v2"
