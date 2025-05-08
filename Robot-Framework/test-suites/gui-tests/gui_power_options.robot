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
Test Setup          GUI Power Test Setup
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
    # Connect back to gui-vm after power measurement has been started
    Connect to netvm
    Connect to VM                 ${GUI_VM}
    IF  $COMPOSITOR == 'cosmic'
        Skip   The X1 in the lab gets stuck when a suspension is attempted. Needs further investigation.
        # Select power menu option   index=4
    ELSE
        Select power menu option   icon_name=suspend
    END
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
        Log To Console            Device successfully woke up after suspend
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
    Verify desktop availability
    Generate power plot           ${BUILD_ID}   ${TEST NAME}
    Stop recording power

GUI Lock and Unlock
    [Documentation]   Lock the screen via GUI power menu lock icon and check that the screen is locked.
    ...               Unlock lock screen by typing the password and check that desktop is available.
    [Tags]            lenovo-x1   SP-T208-3   SP-T208-4   lock
    IF  $COMPOSITOR == 'cosmic'
        Select power menu option   index=2
    ELSE
        Select power menu option   icon_name=lock
    END
    ${lock}           Check if locked
    IF  not ${lock}   FAIL    Failed to lock the screen
    Unlock
    Verify desktop availability

GUI Reboot
    [Documentation]   Reboot the device via GUI power menu reboot icon.
    ...               Check that it shuts down. Check that it turns on and boots to login screen.
    [Tags]            SP-T208-1  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Skip   The X1 in the lab gets stuck when a reboot is attempted. Needs further investigation.
        # Select power menu option   index=5   confirmation=true
    ELSE
        Select power menu option   icon_name=restart
    END
    ${device_not_available}       Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console            Device is down
    ELSE
        FAIL                      Device didn't shut down at reboot.
    END
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did shutdown but didn't start in reboot.
    ELSE
        Log To Console            Device started
    END
    Sleep  30
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        ${NETVM_SSH}              Connect   iterations=10
        Connect to VM             ${GUI_VM}
    ELSE
        Connect to ghaf host
    END
    ${logout_status}     Check if logged out
    IF   not ${logout_status}  FAIL  Desktop detected. Device failed to boot to login screen.

GUI Log out and log in
    [Documentation]   Logout via GUI power menu icon and verify logged out state.
    ...               Login and verify that desktop is available.
    [Tags]            lenovo-x1   SP-T149   logoutlogin
    IF  $COMPOSITOR == 'cosmic'
        Select power menu option   index=3   confirmation=true
    ELSE
        Log out via GUI
    END
    ${logout_status}            Check if logged out
    IF  not ${logout_status}    FAIL  Logout failed.
    Log in via GUI
    Verify desktop availability

*** Keywords ***

GUI Power Test Setup
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Log in, unlock and verify

Select power menu option
    [Documentation]    Open power menu by clicking the icon.
    ...                Navigate to index and click (cosmic) or locate image and click.
    [Arguments]        ${icon_name}=""   ${index}=0   ${confirmation}=false
    IF  $COMPOSITOR == 'cosmic'
        Log To Console     Opening power menu
        Locate and click   ./power.png  0.95  5
        Tab and enter      tabs=${index}
        # Some options have a separate confirmation window that needs to be clicked.
        IF  '${confirmation}' == 'true'   Tab and enter   tabs=2
    ELSE
        Log To Console     Going to click the power icon
        Get icon           ghaf-artwork  power.svg  crop=0  background=black
        Locate and click   ./icon.png  0.95  5
        Log To Console     Going to click the ${icon_name} icon
        Get icon           ghaf-artwork  ${icon_name}.svg  crop=0  background=black
        Locate and click   ./icon.png  0.95  5
    END