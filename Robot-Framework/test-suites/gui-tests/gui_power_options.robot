# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing taskbar power widget options
Force Tags          gui   gui-power-menu

Library             ../../lib/SwitchbotLibrary.py  ${SWITCH_TOKEN}  ${SWITCH_SECRET}
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/measurement_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Teardown       GUI Power Test Teardown


*** Test Cases ***

GUI Suspend and wake up
    [Documentation]   Suspend the device via GUI taskbar suspend icon.
    ...               Check that the device is suspended.
    ...               Wake up by pressing the power button for 1 sec.
    ...               Check that the device is awake.
    ...               Logs device power consumption during the test
    ...               if power measurement tooling is set.
    [Tags]            SP-T75-3   lenovo-x1   lab-only
    Start power measurement       ${BUILD_ID}   timeout=180
    # Connect back to gui-vm after power measurement has been started
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}

    Select power menu option   x=815   y=120
    Check that device is suspended

    Log To Console                Letting the device stay suspended for 30 sec
    Sleep                         30
    Log To Console                Waking the device up by pressing the power button for 1 sec

    Wake up device
    Close All Connections
    Connect
    Start ydotoold
    Switch to vm             ${GUI_VM}   user=${USER_LOGIN}

    # Sometimes screen wakeup has required a mouse move
    Move Cursor

    Wait Until Keyword Succeeds   30s   2s    Check the screen state   on

    Log To Console           Checking if the screen is in locked state after wake up
    ${locked}                Check if locked
    Should Be True           ${locked}    Screen lock not active after wake up

    Unlock
    Verify desktop availability
    Generate power plot           ${BUILD_ID}   ${TEST NAME}
    Stop recording power

GUI Lock and Unlock
    [Documentation]   Lock the screen via GUI power menu lock icon and check that the screen is locked.
    ...               Unlock lock screen by typing the password and check that desktop is available.
    [Tags]            SP-T75-1   lock  lenovo-x1  darter-pro
    [Setup]           Start screen recording
    Select power menu option   text=Lock
    ${lock}           Check if locked
    IF  not ${lock}   FAIL    Failed to lock the screen
    Unlock
    Verify desktop availability
    [Teardown]        Run Keywords   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}   AND
    ...               GUI Power Test Teardown

GUI Reboot
    [Documentation]   Reboot the device via GUI power menu reboot icon.
    ...               Check that it shuts down. Check that it turns on and boots to login screen.
    [Tags]            SP-T75-4  lenovo-x1  darter-pro

    Select power menu option   x=870   y=120   confirmation=True
    Verify Reboot and Connect
    Login to laptop   enable_dnd=True

GUI Shutdown
    [Documentation]   Shutdown the device via GUI power menu shutdown icon.
    ...               Check that it shuts down and then wakes up with a short power button press.
    [Tags]            SP-T75-5  lenovo-x1  darter-pro  lab-only
    Select power menu option   x=925   y=120   confirmation=True   tabs=3
    ${start_time}     Get Time    epoch
    Verify Laptop Shutdown        timeout=60
    ${end_time}       Get Time    epoch
    ${elapsed}        Evaluate    ${end_time} - ${start_time}
    IF    ${elapsed} > 20   SKIP   Known issue: SSRCSP-7512 (Shutdown took too long: ${elapsed} seconds (expected < 20))
    # Give laptop time to properly turn off before trying to turn on
    ${wait_time}      Evaluate    20 - ${elapsed}
    Wait     ${wait_time}
    Turn Laptop On and Connect
    Login to laptop   enable_dnd=True

GUI Log out and log in
    [Documentation]   Logout via GUI power menu icon and verify logged out state.
    ...               Login and verify that desktop is available.
    [Tags]            SP-T75-2   logoutlogin   lenovo-x1  darter-pro
    Select power menu option   text=LogOut   confirmation=True
    ${logout_status}            Check if logged out
    IF  not ${logout_status}    FAIL  Logout failed.
    Log in, unlock and verify

*** Keywords ***

GUI Power Test Teardown
    IF  $TEST_STATUS=='PASS'
        Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    ELSE
        Reboot Laptop
        Verify Reboot and Connect
        Login to laptop   enable_dnd=True
    END

Select power menu option
    [Documentation]    Open power menu by clicking the icon.
    ...                Search the correct text or click given coordinates.
    [Arguments]        ${text}=${EMPTY}   ${x}=0   ${y}=0   ${confirmation}=False   ${tabs}=2
    Log To Console     Opening power menu
    Locate and click   image  ./power.png  0.95  10
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
    # Error is ignored because the connection is sometimes lost before the last Enter returns a value.
    IF  ${confirmation}   Run Keyword And Ignore Error   Tab and enter   tabs=${tabs}
    Sleep   1