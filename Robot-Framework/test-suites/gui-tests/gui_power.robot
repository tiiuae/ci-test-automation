# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing power options
Test Tags           gui-power

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/measurement_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource

Test Setup          GUI Power Test Setup
Test Teardown       GUI Power Test Teardown


*** Test Cases ***

Suspend and wake up from power menu
    [Documentation]   Suspend the device via GUI taskbar suspend icon and wake up.
    ...               Logs device power consumption during the test
    ...               if power measurement tooling is set.
    [Tags]            SP-T75  SP-T75-3  lenovo-x1  darter-pro  lab-only
    Start power measurement       ${BUILD_ID}   timeout=180
    # Connect back to gui-vm after power measurement has been started
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}

    Select power menu option   x=815   y=120
    Confirm suspension and wake up the device

    Generate power plot           ${BUILD_ID}   ${TEST NAME}
    Stop recording power

Lock and Unlock from power menu
    [Documentation]   Lock the screen via GUI power menu lock icon and check that the screen is locked.
    ...               Unlock lock screen by typing the password and check that desktop is available.
    [Tags]            SP-T75  SP-T75-1  lock  lenovo-x1  darter-pro
    Select power menu option   text=Lock
    ${lock}           Check if locked   iterations=3   debug_screenshot=True
    IF  not ${lock}   FAIL    Failed to lock the screen
    Unlock
    Verify desktop availability

Reboot from power menu
    [Documentation]   Reboot the device via GUI power menu reboot icon.
    ...               Check that it shuts down. Check that it turns on and boots to login screen.
    [Tags]            SP-T75  SP-T75-4  lenovo-x1  darter-pro  lab-only
    Select power menu option   x=870   y=120   confirmation=True
    ${start_time}     Get Time    epoch
    ${shutdown_status}    ${shutdown_msg}    Run Keyword And Ignore Error    Verify shutdown via network
    IF    '${shutdown_status}' == 'FAIL'
        ${expected_failure}    Evaluate    "still responds" in """${shutdown_msg}"""
        IF    ${expected_failure}
            SKIP   Known issue: SSRCSP-8490
        ELSE
            FAIL    ${shutdown_msg}
        END
    END
    Connect After Reboot   soft_reboot=True
    ${end_time}       Get Time    epoch
    Login to laptop   enable_dnd=True
    ${elapsed}        Evaluate    ${end_time} - ${start_time}
    ${reboot_limit}   Set Variable If    "${DEVICE_TYPE}" == "darter-pro"    100    90
    Log               Reboot took ${elapsed} seconds   console=True

    Should Not Be True    ${elapsed} > ${reboot_limit}    msg=Reboot took too long: ${elapsed} seconds (expected < ${reboot_limit})
    [Teardown]    Run Keywords   GUI Power Test Teardown   AND
    ...           Run Keyword If Test Failed    Run Keyword If   "storeDisk" in "${JOB}" and "took too long" in $TEST_MESSAGE   SKIP    Known Issue: SSRCSP-8621

Shutdown from power menu
    [Documentation]   Shutdown the device via GUI power menu shutdown icon.
    ...               Check that it shuts down and then wakes up with a short power button press.
    [Tags]            SP-T75  SP-T75-5  lenovo-x1  darter-pro  lab-only
    Select power menu option   x=925   y=120   confirmation=True
    Set Test Variable          ${max_elapsed}  25

    ${start_time}     Get Time    epoch
    ${end_time}       Wait Until Device Is Down
    ${elapsed}        Evaluate    ${end_time} - ${start_time}
    Log               Shutdown took ${elapsed} seconds   console=True
    IF    ${elapsed} <= ${max_elapsed}
        ${wait_time}  Evaluate    ${max_elapsed} - ${elapsed} + 10
        Wait          ${wait_time}
    ELSE
        Wait          10
    END
    Turn Laptop On
    Connect After Reboot
    Login to laptop   enable_dnd=True

    Should Not Be True    ${elapsed} > ${max_elapsed}    msg=Shutdown took too long: ${elapsed} seconds (expected < ${max_elapsed})
    [Teardown]    Run Keywords   GUI Power Test Teardown   AND
    ...           Run Keyword If Test Failed    Run Keyword If   "storeDisk" in "${JOB}" and "took too long" in $TEST_MESSAGE   SKIP    Known Issue: SSRCSP-8621

Log out and log in from power menu
    [Documentation]   Logout via GUI power menu icon and verify logged out state.
    ...               Login and verify that desktop is available.
    [Tags]            SP-T75  SP-T75-2  logoutlogin  lenovo-x1  darter-pro
    Select power menu option   text=LogOut   confirmation=True
    ${logout_status}            Check if logged out
    Should Be True              ${logout_status}    Logout failed
    Log in, unlock and verify

Log out and log in with shortcut
    [Documentation]   Logout via logout shortcut and verify logged out state.
    ...               Login and verify that desktop is available.
    [Tags]            SP-T186  lenovo-x1  darter-pro
    Press Key(s)                LEFTMETA+LEFTSHIFT+ESC
    Locate on screen            text  Quit  10
    Tab and enter               tabs=1
    ${logout_status}            Check if logged out
    Should Be True              ${logout_status}    Logout failed
    Log in, unlock and verify

Suspend and wake up from lock screen
    [Documentation]   Suspend the device from lock screen suspend icon and wake up.
    [Tags]            SP-T245  lenovo-x1  darter-pro  lab-only
    Press Key(s)          LEFTMETA+ESC
    Locate on screen      image  ${LOCK_ICON}   0.95  10
    Run ydotool command   mousemove --absolute -x 320 -y 275
    Run ydotool command   click 0xC0
    Confirm suspension and wake up the device

*** Keywords ***

GUI Power Test Setup
    ${gui_power_log_since}    BuiltIn.Get Time   epoch
    Set Test Variable         ${gui_power_log_since}
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Start screen recording

GUI Power Test Teardown
    ${needs_reboot_recovery}    Evaluate
    ...    ($TEST_STATUS == 'FAIL' and 'took too long' not in $TEST_MESSAGE) or ($TEST_STATUS == 'SKIP' and 'SSRCSP-8490' in $TEST_MESSAGE)
    IF  ${needs_reboot_recovery}
        Hard Reboot Device And Connect
        IF    ${IS_AVAILABLE}
            ssh_keywords.Save log   ${GUI_VM}  ${gui_power_log_since}
            ssh_keywords.Save log   ${HOST}    ${gui_power_log_since}
            Login to laptop         enable_dnd=True
            Save screen recording   ${TEST_STATUS}   ${TEST_NAME}
        END
    ELSE
        Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
        Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
    END

Select power menu option
    [Documentation]    Open power menu by clicking the icon.
    ...                Search the correct text or click given coordinates.
    [Arguments]        ${text}=${EMPTY}   ${x}=0   ${y}=0   ${confirmation}=False   ${tabs}=1
    Log To Console     Opening power menu
    Locate and click   image  power.png  0.95  10
    # Wait for menu to open and stop retrying when successful
    ${menu_opened}     Run Keyword And Return Status   Locate on screen   text   Settings   iterations=3
    IF  not ${menu_opened}
        FAIL   Failed to open power menu: 'Settings' not visible.
    END
    IF  '${text}'
        Locate and click   text   ${text}
    ELSE IF  ${x} != 0 and ${y} != 0
        Log To Console        Clicking the coordinates of the icon {'x': ${x}, 'y': ${y}}
        Run ydotool command   mousemove --absolute -x ${x} -y ${y}
        Click
    ELSE
        FAIL   No type provided
    END
    Sleep   1
    # Some options have a separate confirmation window that needs to be clicked.
    # Error is ignored because the connection is sometimes lost before the last Enter returns a value.
    IF  ${confirmation}   Run Keyword And Ignore Error   Tab and enter   tabs=${tabs}
    Sleep   1

Confirm suspension and wake up the device
    [Documentation]   Check that the device is suspended.
    ...               Wake up by pressing the power button for 1 sec.
    ...               Check that the device is awake and unlock.
    Wait For Device Going Offline    ${DEVICE_IP_ADDRESS}

    Log To Console      Letting the device stay suspended for 30 sec
    Wait                30
    Log To Console      Waking the device up by pressing the power button for 1 sec
    Wake up device

    Close All Connections
    Start ydotoold
    Switch to vm        ${GUI_VM}   user=${USER_LOGIN}

    # Sometimes screen wakeup has required a mouse move
    Wiggle cursor
    Wait Until Keyword Succeeds   30s   2s    Check the screen state   on

    Log To Console      Checking if the screen is in locked state after wake up
    ${locked}           Check if locked   iterations=3   debug_screenshot=True
    Should Be True      ${locked}    Screen lock not active after wake up

    Unlock
    Verify desktop availability
