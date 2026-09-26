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
Resource            ../../resources/app_keywords.resource
Library             ../../lib/output_parser.py
Library             JSONLibrary


*** Test Cases ***

Automatic suspension
    [Documentation]   Wait and check that
    ...               in the beginning brightness is 100 %
    ...               in 5 min - the screen locks and turns off
    ...               in 15 min - the laptop is suspended
    ...               in 20 min press the button and check that laptop woke up
    [Tags]            SP-T162  lenovo-x1  darter-pro  lab-only
    [Setup]           Test setup
    [Teardown]        Test teardown

    ${suspended_power_limit}     Set Variable    3500
    ${rel_power_change_limit}    Set Variable    25

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

    Wait For Device Going Offline   ${DEVICE_IP_ADDRESS}

    Wait                     60
    Set timestamp            suspend_start
    Wait                     240
    Set timestamp            suspend_end

    Wake up device
    Close All Connections
    Start ydotoold
    Switch to vm             ${GUI_VM}   user=${USER_LOGIN}

    # Sometimes screen wakeup has required a mouse move
    Wiggle cursor
    
    Wait Until Keyword Succeeds   30s   2s    Check the screen state   on

    Log To Console           Checking if the screen is in locked state after wake up
    ${locked}                Check if locked   iterations=3   debug_screenshot=True
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

        ${max_suspended_power}   Check max power during suspension   ${BUILD_ID}
        ${power_changed}         Measure power level change  ${BUILD_ID}  ${rel_power_change_limit}  ${before_suspend_start}  ${before_suspend_end}  ${after_suspend_start}  ${after_suspend_end}

        IF  ${max_suspended_power} > ${suspended_power_limit}
            FAIL    Power consumption exceptionally high during suspension\nMax suspended power: ${max_suspended_power}mW\nTest limit: ${suspended_power_limit}mW
        END

        IF  ${power_changed}!=${False}
            FAIL  Max suspended power ${max_suspended_power}mW (test limit ${suspended_power_limit}mW)\nPower consumption level increased ${power_changed}% over suspension and wake up (test limit ${rel_power_change_limit}%)
        END
    END

Suspend and wake up with apps running
    [Documentation]   Launch several apps in different VM and verify, that they are still running after suspension
    [Tags]            SP-T208  lenovo-x1  darter-pro  lab-only
    [Setup]           Start screen recording
    ${app_statuses}   Launch several apps in different VMs
    Suspend device via GUI and wake up     ${app_statuses}
    Check apps are running after wake up   ${app_statuses}
    [Teardown]        App suspension test teardown

*** Keywords ***

Test setup
    Start screen recording
    Enable automatic suspension
    Save max brightness
    Set display to max brightness
    Wiggle cursor

Test teardown
    IF  $TEST_STATUS!='PASS'
        Hard Reboot Device And Connect
        Login to laptop
    END
    Switch to vm   ${GUI_VM}   user=${USER_LOGIN}
    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

App suspension test teardown
    ${device_online}    Ping Host    ${DEVICE_IP_ADDRESS}
    IF    not ${device_online}
        Hard Reboot Device And Connect
        Login to laptop
    END
    Kill App in VM    ${Google Chrome}    status=PASS    require_exists=False
    Kill App in VM    ${Zoom}             status=PASS    require_exists=False
    Kill App in VM    ${Gala}             status=PASS    require_exists=False
    Kill App in VM    ${COSMIC Files}     status=PASS    require_exists=False
    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

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

Suspend device via GUI and wake up
    [Arguments]    ${app_statuses}
    ${any_app_started}    Evaluate    any($app_statuses.values())
    IF    not ${any_app_started}
        FAIL    PRECONDITION FAILED: No applications were launched. The test could not be performed.
    END
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Select power menu option   x=815   y=120
    Confirm suspension and wake up the device

Launch several apps in different VMs
    ${app_statuses}      Create Dictionary
    ${started}           Run Keyword And Return Status    Start app via GUI    ${COSMIC Files}
    Set To Dictionary    ${app_statuses}    files=${started}
    ${started}           Run Keyword And Return Status    Start App in VM    ${Gala}
    Set To Dictionary    ${app_statuses}    gala=${started}
    ${started}           Run Keyword And Return Status    Start App in VM    ${Zoom}
    Set To Dictionary    ${app_statuses}    zoom=${started}
    IF    ${started}
        Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
        Accept Chrome Terms Of Service If Shown    ${Zoom}    attempts=2    interval=500ms
    END
    ${started}           Run Keyword And Return Status    Start App in VM    ${Google Chrome}
    Set To Dictionary    ${app_statuses}    chrome=${started}
    IF    ${started}
        Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
        Accept Chrome Terms Of Service If Shown    ${Google Chrome}    attempts=2    interval=500ms
    END
    RETURN    ${app_statuses}

Check apps are running after wake up
    [Documentation]    The order is important:
    ...                It should be reverse to the order from the keyword 'Launch several apps in different VMs'.
    ...                Expecting Apps to be opened in the same order.
    [Arguments]    ${app_statuses}
    Run Keyword And Continue On Failure    Run Keyword If    ${app_statuses}[chrome]    Check that App is running and visible    ${Google Chrome}    chrome
    Run Keyword And Continue On Failure    Run Keyword If    ${app_statuses}[zoom]      Check that App is running and visible    ${Zoom}             Zoom
    Run Keyword And Continue On Failure    Run Keyword If    ${app_statuses}[gala]      Check that App is running and visible    ${Gala}             business
    Run Keyword And Continue On Failure    Run Keyword If    ${app_statuses}[files]     Check that App is running and visible    ${COSMIC Files}     Shares
    [Teardown]    Verify app launch precondition    ${app_statuses}    ${KEYWORD_STATUS}

Check that App is running and visible
    [Arguments]     ${app_key}    ${text_to_check}
    Check that App is running in VM    ${app_key}
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Verify Text Is On The Screen    ${text_to_check}
    [Teardown]   Kill App in VM    ${app_key}    status=${KEYWORD_STATUS}

Verify app launch precondition
    [Arguments]    ${app_statuses}    ${check_status}
    ${failed_to_start}    Evaluate    ', '.join(name for name, started in $app_statuses.items() if not started)
    ${started_apps}    Evaluate    ', '.join(name for name, started in $app_statuses.items() if started)
    IF    not $failed_to_start
        RETURN
    ELSE IF    $check_status == 'PASS'
        FAIL    PRECONDITION PARTIALLY SATISFIED: Failed to launch: ${failed_to_start}. Suspend/wake verification passed for: ${started_apps}.
    ELSE
        FAIL    PRECONDITION PARTIALLY SATISFIED: Failed to launch: ${failed_to_start}. Suspend/wake verification also failed.
    END
