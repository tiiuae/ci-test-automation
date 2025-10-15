# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing taskbar power widget options
Force Tags          gui   gui-power-menu

Library             ../../lib/SwitchbotLibrary.py  ${SWITCH_TOKEN}  ${SWITCH_SECRET}
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/power_meas_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Setup          GUI Power Test Setup
Test Teardown       Run Keyword If Test Failed    GUI Power Test Teardown


*** Test Cases ***

GUI Suspend and wake up
    [Documentation]   Suspend the device via GUI taskbar suspend icon.
    ...               Check that the device is suspended.
    ...               Wake up by pressing the power button for 1 sec.
    ...               Check that the device is awake.
    ...               Logs device power consumption during the test
    ...               if power measurement tooling is set.
    [Tags]            SP-T208-2   lenovo-x1   lab-only
    Start power measurement       ${BUILD_ID}   timeout=180
    # Connect back to gui-vm after power measurement has been started
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}

    Select power menu option   x=815   y=120

    ${device_not_available}       Run Keyword And Return Status  Wait Until Keyword Succeeds  2x  ${PING_SPACING}s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console            Device suspended.
    ELSE
        FAIL                      Device failed to suspend.
    END
    Log To Console                Letting the device stay suspended for 30 sec
    Sleep                         30
    Log To Console                Waking the device up by pressing the power button for 1 sec
    Press Button                  ${SWITCH_BOT}-ON
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did suspend but failed to wake up
    ELSE
        Log To Console            Device successfully woke up after suspend
    END
    # Screen wakeup requires a mouse move
    Move Cursor
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
    [Tags]            SP-T208-3   lock  lenovo-x1  darter-pro
    [Setup]           Run Keywords   GUI Power Test Setup   AND   Start screen recording
    Select power menu option   text=Lock
    ${lock}           Check if locked
    IF  not ${lock}   FAIL    Failed to lock the screen
    Unlock
    Verify desktop availability
    [Teardown]        Run Keywords   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}   AND
    ...               Run Keyword If Test Failed    GUI Power Test Teardown

GUI Reboot
    [Documentation]   Reboot the device via GUI power menu reboot icon.
    ...               Check that it shuts down. Check that it turns on and boots to login screen.
    [Tags]            SP-T208-1  lenovo-x1  darter-pro

    Select power menu option   x=870   y=120   confirmation=true

    ${device_not_available}       Run Keyword And Return Status  Wait Until Keyword Succeeds  2x  ${PING_SPACING}s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console            Device is down
    ELSE
        FAIL                      Device didn't shut down at reboot.
    END
    Sleep  20
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did shutdown but didn't start in reboot.
    ELSE
        Log To Console            Device started
    END
    Sleep  30
    Connect   iterations=10
    Check if ssh is ready on vm   gui-vm   timeout=60
    Start ydotoold
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Log in, unlock and verify   enable_dnd=True

GUI Log out and log in
    [Documentation]   Logout via GUI power menu icon and verify logged out state.
    ...               Login and verify that desktop is available.
    [Tags]            SP-T149   logoutlogin   lenovo-x1  darter-pro
    Select power menu option   text=LogOut   confirmation=true
    ${logout_status}            Check if logged out
    IF  not ${logout_status}    FAIL  Logout failed.
    Log in, unlock and verify

*** Keywords ***

GUI Power Test Setup
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Log in, unlock and verify

GUI Power Test Teardown
    Reboot Laptop
    Check If Device Is Up
    Sleep  30
    Connect    iterations=10
    Check if ssh is ready on vm   gui-vm    timeout=60
    Start ydotoold

Select power menu option
    [Documentation]    Open power menu by clicking the icon.
    ...                Search the correct text or click given coordinates.
    [Arguments]        ${text}=${EMPTY}   ${x}=0   ${y}=0   ${confirmation}=false
    Log To Console     Opening power menu
    Locate and click   image  ./power.png  0.95  5
    IF  '${text}'
        Locate and click   text   ${text}
    ELSE IF  ${x} != 0 and ${y} != 0
        Log To Console        Clicking the coordinates of the icon {'x': ${x}, 'y': ${y}}
        Run ydotool command   mousemove --absolute -x ${x} -y ${y}
        Run ydotool command   click 0xC0
    ELSE
        FAIL   No type provided
    END
    Sleep   1
    # Some options have a separate confirmation window that needs to be clicked.
    IF  '${confirmation}' == 'true'
        # Confirmation window needs to be clicked twice to focus it
        # Word "automatically" is used to locate the window since it is used in all confirmations
        Locate and click   text   automatically
        Locate and click   text   automatically
        Tab and enter   tabs=2
    END
    Sleep   1