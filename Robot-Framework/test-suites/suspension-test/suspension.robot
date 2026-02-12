# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing automatic suspension

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/measurement_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Library             ../../lib/output_parser.py
Library             JSONLibrary


*** Test Cases ***

Automatic suspension (Lenovo X1)
    [Documentation]   Wait and check that
    ...               in the beginning brightness is 100 %
    ...               in 5 min - the screen locks and turns off
    ...               in 15 min - the laptop is suspended
    ...               in 20 min press the button and check that laptop woke up
    [Tags]            SP-T162  lenovo-x1  lab-only
    [Setup]           Test setup
    [Teardown]        Test teardown
    SKIP   Known issue: SSRCSP-8012
    Check the screen state   on
    Check screen brightness  ${max_brightness}

    Start power measurement  ${BUILD_ID}   timeout=1500
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}

    Wait                     60
    Set timestamp            before_suspend_start
    Wait                     60
    Set timestamp            before_suspend_end
    Wait                     200

    Check the screen state   off

    Wait                     610

    Check that device is suspended

    Wait                     60
    Set timestamp            suspend_start
    Wait                     240
    Set timestamp            suspend_end

    Wake up device
    Close All Connections
    Start ydotoold
    Switch to vm             ${GUI_VM}   user=${USER_LOGIN}

    # Sometimes screen wakeup has required a mouse move
    Move Cursor
    
    Wait Until Keyword Succeeds   30s   2s    Check the screen state   on

    Log To Console           Checking if the screen is in locked state after wake up
    ${locked}                Check if locked
    Should Be True           ${locked}    Screen lock not active after wake up

    # Power level comparison in the same login gui state as in the beginning
    # Applied only if power measurement agent is available in the setup
    IF  $SSH_MEASUREMENT!='${EMPTY}'
        Unlock
        Verify desktop availability
        Wait                     120
        Set timestamp            after_suspend_start
        Wait                     60
        Set timestamp            after_suspend_end

        Generate power plot      ${BUILD_ID}   ${TEST NAME}
        Stop recording power

        ${suspended_power}       Check power during suspension   ${BUILD_ID}   2500
        ${power_changed}         Measure power level change  ${BUILD_ID}  25  ${before_suspend_start}  ${before_suspend_end}  ${after_suspend_start}  ${after_suspend_end}
        IF  ${suspended_power}!=${False} or ${power_changed}!=${False}
            FAIL  Average suspended power ${suspended_power}mW (test limit 2500mW)\nPower consumption level increased ${power_changed}% over suspension and wake up (test limit 25%)
        END
    END

Automatic lock
    [Documentation]   Suspension is currently broken but automatic lock works (without screen state checks)
    ...               Wait and check that
    ...               in the beginning brightness is 100 %
    ...               in 5 min - the screen locks and turns off
    [Tags]            SP-T269  lenovo-X1  darter-pro
    [Setup]           Test setup

    # Check the screen state   on   Skipped due to SSRCSP-8015
    Check screen brightness   ${max_brightness}

    Wait     320
    # Check the screen state   off   Skipped due to SSRCSP-8015
    
    # Screen has to be turned on before checking for lock
    Move cursor

    ${locked}         Check if locked
    Should Be True    ${locked}

*** Keywords ***

Test setup
    Enable automatic suspension
    Save max brightness
    Set display to max brightness
    Move cursor

Test teardown
    Run Keyword If Test Passed    Run Keywords   Switch to vm   ${GUI_VM}   user=${USER_LOGIN}   AND   Log out and verify
    Run Keyword If Test Failed    Reboot Laptop


Save max brightness
    ${device}     Run Command    ls /sys/class/backlight/
    ${max}        Run Command    cat /sys/class/backlight/${device}/max_brightness
    Set Test Variable  ${max_brightness}     ${max}
    Log                Max brightness value is ${max}  console=True

Set display to max brightness
    [Setup]   Switch to vm    ${GUI_VM}
    ${current_brightness}    Get screen brightness   log_brightness=False
    IF   ${current_brightness} != ${max_brightness}
        Set brightness   100%
        ${current_brightness}   Get screen brightness
        Should be Equal As Numbers    ${current_brightness}   ${max_brightness}
    END
    [Teardown]   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Check screen brightness
    [Arguments]       ${expected_brightness}
    ${output}     Get screen brightness
    Should be Equal As Numbers   ${output}  ${expected_brightness}   The screen brightness is ${output}, expected ${expected_brightness}