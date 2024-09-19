# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing taskbar power widget options
Force Tags          gui
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Suite Teardown      Close All Connections


*** Test Cases ***

GUI Reboot
    [Documentation]   Reboot the device via GUI reboot icon.
    ...               Check that it shuts down. Check that it turns on and boots to login screen.
    [Tags]            lenovo-x1   SP-T208-1
    Connect to VM if not already connected  gui-vm
    Start ydotoold
    Log To Console                Going to click the power icon
    Get icon                      ghaf-artwork  power.svg  crop=0  background=black
    Locate and click              ./icon.png  0.95  5
    Log To Console                Going to click the reboot icon
    Get icon                      ghaf-artwork  restart.svg  crop=0  background=black
    Locate and click              ./icon.png  0.95  5
    ${device_not_available}       Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console            Device is down
    ELSE
        FAIL                      Device didn't shut down at reboot.
    END
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did shutdown but didn't start in reboot
    ELSE
        Log To Console            Device started
    END
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Connect to netvm
        Connect to VM             ${GUI_VM}
    END
    Verify logout
    Log To Console                LOGGED_IN_STATUS after reboot
    Log To Console                ${LOGGED_IN_STATUS}
    Run Keyword If                ${LOGGED_IN_STATUS}  FAIL  Desktop detected. Device failed to boot to login screen.

Log in
    [Documentation]   Login and verify logged in state.
    [Tags]            lenovo-x1   SP-T149   login
    Connect to VM if not already connected  gui-vm
    GUI Log in
    Verify login

Log out
    [Documentation]   Logout via gui icon and verify that desktop is not available
    [Tags]            lenovo-x1   SP-T149   logout
    Connect to VM if not already connected  gui-vm
    GUI Log out
    Verify logout           iterations=5
    Run Keyword If          ${LOGGED_IN_STATUS}  FAIL  Logout failed. Desktop still detected after 5 sec.
