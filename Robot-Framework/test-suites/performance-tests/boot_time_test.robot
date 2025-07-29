# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device bootup time.
Force Tags          boot_time_test   performance

Resource            ../../config/variables.robot
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             DateTime
Library             Collections
Resource            ../../resources/device_control.resource
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Variables           ../../lib/performance_thresholds.py

Suite Setup         Prepare Test Environment  login=False
Suite Teardown      Close All Connections


*** Variables ***
${PING_TIMEOUT}     120
${SEARCH_TIMEOUT}   40


*** Test Cases ***

Measure Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]  SP-T187  lenovo-x1  dell-7330
    Soft Reboot Device
    Wait Until Keyword Succeeds  35s  2s  Check If Ping Fails
    Get Boot times
    [Teardown]    Run Keyword If Test Failed  Log Journal To Debug

Measure Hard Boot Time
    [Documentation]  Measure how long it takes to device to boot up with hard reboot
    [Tags]  SP-T182  lenovo-x1  dell-7330
    Log To Console                Shutting down by pressing the power button
    Press Button                  ${SWITCH_BOT}-OFF
    Wait Until Keyword Succeeds   15s  2s  Check If Ping Fails
    Log To Console                The device has shut down
    Log To Console                Waiting for the robot finger to return
    Sleep  20
    Log To Console                Booting the device by pressing the power button
    Press Button                  ${SWITCH_BOT}-ON
    Get Boot times                plot_name=Hard Boot Times
    [Teardown]    Run Keyword If Test Failed  Log Journal To Debug

Measure Orin Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]  SP-T187  orin-agx  orin-agx-64  orin-nx
    Soft Reboot Device
    Wait Until Keyword Succeeds  35s  2s  Check If Ping Fails
    Get Time To Ping
    IF  "NX" in "${DEVICE}"      Sleep    30

Measure Orin Hard Boot Time
    [Documentation]  Measure how long it takes to device to boot up with hard reboot
    [Tags]  SP-T182  orin-agx  orin-agx-64  orin-nx
    Log To Console                Shutting down by switching the power off
    Turn Relay Off                ${RELAY_NUMBER}
    Wait Until Keyword Succeeds   15s  2s  Check If Ping Fails
    Log To Console                The device has shut down
    Log To Console                Booting the device by switching the power on
    Turn Relay On                 ${RELAY_NUMBER}
    Get Time To Ping              plot_name=Hard Boot Times
    IF  "NX" in "${DEVICE}"       Sleep    30


*** Keywords ***

Measure Time To Ping
    [Arguments]               ${start_time}
    ${ping_response}          Set Variable  ${EMPTY}
    Log To Console            Start checking ping response
    ${ping_end_time}          Set Variable  False
    WHILE  not $ping_response   limit=${PING_TIMEOUT} seconds
        ${ping_response}      Ping Host  ${DEVICE_IP_ADDRESS}  1
        ${ping_end_time}      IF  $ping_response  DateTime.Get Current Date  result_format=epoch
    END
    IF  not $ping_end_time
        FAIL                  No response to ping within ${PING_TIMEOUT}
    END
    ${ping_response_seconds}  DateTime.Subtract Date From Date  ${ping_end_time}  ${start_time}   exclude_millis=True
    Log                       Response time to ping measured: ${ping_response_seconds}   console=True
    RETURN                    ${ping_response_seconds}

Get Time To Ping
    [Arguments]  ${plot_name}=Soft Boot Times
    ${start_time_epoch}            DateTime.Get Current Date   result_format=epoch
    ${ping_response_seconds}      Measure Time To Ping  ${start_time_epoch}
    &{final_results}              Create Dictionary
    Set To Dictionary             ${final_results}  response_to_ping  ${ping_response_seconds}
    Check Result Validity         ${final_results}
    &{statistics}                 Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    Determine Test Status         ${statistics}  inverted=1

Get Boot times
    [Documentation]  Collect boot times from device
    [Arguments]  ${plot_name}=Soft Boot Times
    ${start_time_epoch}  DateTime.Get Current Date   result_format=epoch
    # For detecting timestamp of Login screen in cosmic desktop
    ${testuser_line}  Catenate  SEPARATOR=\n
    ...  testuser_line=$(journalctl -b --output=short-iso | grep "testuser: changing state activating-for-acquire")
    ...  echo $testuser_line

    ${ping_response_seconds}    Measure Time To Ping    ${start_time_epoch}
    Sleep  30
    Connect to netvm
    Connect to VM  ${GUI_VM}
    ${time_to_desktop}      Check Time To Notification  ${testuser_line}   ${start_time_epoch}
    Log                     Boot time to login screen measured: ${time_to_desktop}   console=True
    &{final_results}        Create Dictionary
    Set To Dictionary       ${final_results}  time_to_desktop  ${time_to_desktop}
    Set To Dictionary       ${final_results}  response_to_ping  ${ping_response_seconds}
    # Before saving the data, check that the captured values are positive.
    Check Result Validity   ${final_results}
    &{statistics}           Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    # In boot time test decrease in result value is considered improvement -> using inverted argument
    Determine Test Status   ${statistics}   inverted=1

Check Time To Notification
    [Documentation]  Check that correct notification is available in journalctl
    [Arguments]      ${command}   ${start_time}
    ${notification_line}  Set Variable  ${EMPTY}
    WHILE  '${notification_line}' == '${EMPTY}'   limit=${SEARCH_TIMEOUT} seconds
        ${notification_line}    Execute Command  ${command}
    END

    IF  '${notification_line}' == '${EMPTY}'
       Fail  The searched journalctl line that is needed for 'time_to_desktop' calculation was not captured.
    END

    ${get_timestamp}      Catenate  SEPARATOR=\n
    ...  desktop_time=$(date -d "$(${command} | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $desktop_time
    ${notification_time}  Execute Command  ${get_timestamp}
    ${time}  Subtract Time From Time  ${notification_time}  ${start_time}   exclude_millis=True
    Should Be True  0 < ${time} < 120
    RETURN  ${time}

Check Result Validity
    [Arguments]      ${captured_results}
    FOR  ${key}  ${value}  IN  &{captured_results}
         Should Be True  ${value} > 0
    END

Log Journal To Debug
    ${journal_output}     Execute Command   journalctl -b
    Log                   ${journal_output}

