# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing taskbar power widget options
Force Tags          gui   gui-power-menu
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/power_meas_keywords.resource
Library             ../../lib/SwitchbotLibrary.py  ${SWITCH_TOKEN}  ${SWITCH_SECRET}
Test Teardown       Close All Connections


*** Test Cases ***

GUI Suspend and wake up
    [Documentation]   Suspend the device via GUI taskbar suspend icon.
    ...               Check that the device is suspended.
    ...               Wake up by pressing the power button for 1 sec.
    ...               Check that the device is awake.
    ...               Logs device power consumption during the test
    ...               if power measurement tooling is set.
    [Tags]            lenovo-x1   SP-T208-2
    Start power measurement       ${BUILD_ID}   timeout=180
    Set start timestamp
    Connect to netvm
    Connect to VM                 ${GUI_VM}
    Click power menu item         suspend
    ${device_not_available}       Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console            Device suspended.
    ELSE
        FAIL                      Device failed to suspend.
    END
    Log To Console                Letting the device stay suspended for 30 sec
    BuiltIn.Sleep                 30
    Log To Console                Waking the device up by pressing the power button for 1 sec
    Press Button                  ${SWITCH_BOT}-ON
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did suspend but failed to wake up
    ELSE
        Log To Console            Device succesfully woke up after suspend
    END
    Log To Console                Checking if the screen is in locked state after wake up
    ${lock}                       Check if locked
    IF  ${lock}
        Log To Console            Screen lock detected
    ELSE
        Log To Console            Screen lock not active.
        FAIL                      Screen lock not active after wake up
    END
    Unlock
    Generate power plot           ${BUILD_ID}   ${TEST NAME}
    Stop recording power

GUI Lock and Unlock
    [Documentation]   Lock the screen via GUI taskbar lock icon and check that the screen is locked.
    ...               Unlock lock screen by typing the password and check that desktop is available
    [Tags]            lenovo-x1   SP-T208-3   SP-T208-4   lock
    Connect to netvm
    Connect to VM                 ${GUI_VM}
    Click power menu item         lock
    ${lock}                       Check if locked
    IF  ${lock}
        Log To Console            Screen lock detected
    ELSE
        Log To Console            Screen lock not active
        FAIL                      Failed to lock the screen
    END
    Unlock
    Verify login

GUI Reboot
    [Documentation]   Reboot the device via GUI reboot icon.
    ...               Check that it shuts down. Check that it turns on and boots to login screen.
    [Tags]            lenovo-x1   SP-T208-1
    Click power menu item         restart
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
    Sleep  30
    IF  "Lenovo" in "${DEVICE}"
        ${NETVM_SSH}              Connect   iterations=10
        Connect to VM             ${GUI_VM}
    ELSE
        Connect to ghaf host
    END
    Verify logout
    Log To Console                LOGGED_IN_STATUS after reboot
    Log To Console                ${LOGGED_IN_STATUS}
    Run Keyword If                ${LOGGED_IN_STATUS}  FAIL  Desktop detected. Device failed to boot to login screen.

GUI Log in and log out
    [Documentation]   Login and verify logged in state.
    ...               Logout via gui icon and verify that desktop is not available.
    [Tags]            lenovo-x1   SP-T149   loginlogout
    Connect to VM if not already connected  gui-vm
    Log in via GUI
    Verify login
    Log out
    Verify logout           iterations=5
    Run Keyword If          ${LOGGED_IN_STATUS}  FAIL  Logout failed. Desktop still detected after 5 sec.


*** Keywords ***

Click power menu item
    [Arguments]    ${icon_name}
    Connect to VM if not already connected  gui-vm
    Start ydotoold
    Log To Console                Going to click the power icon
    Get icon                      ghaf-artwork  power.svg  crop=0  background=black
    Locate and click              ./icon.png  0.95  5
    Log To Console                Going to click the ${icon_name} icon
    Get icon                      ghaf-artwork  ${icon_name}.svg  crop=0  background=black
    Locate and click              ./icon.png  0.95  5