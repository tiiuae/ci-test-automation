# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device bootup time.
Force Tags          boot_time_test   performance
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/performance_keywords.resource
Resource            ../../config/variables.robot
Variables           ../../lib/performance_thresholds.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             DateTime
Library             Collections
Suite Setup         Boot Time Test Setup
Suite Teardown      Close All Connections


*** Variables ***
${PING_TIMEOUT}     120
${SEARCH_TIMEOUT1}  20
${SEARCH_TIMEOUT2}  5


*** Test Cases ***

Measure Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]  SP-T187  lenovo-x1  dell-7330
    Soft Reboot Device
    Wait Until Keyword Succeeds  35s  2s  Check If Ping Fails
    Get Boot times

Measure Hard Boot Time
    [Documentation]  Measure how long it takes to device to boot up with hard reboot
    [Tags]  SP-T182  lenovo-x1  dell-7330
    Log to console                Shutting down by pressing the power button
    Press Button                  ${SWITCH_BOT}-OFF
    Wait Until Keyword Succeeds   15s  2s  Check If Ping Fails
    Log to console                The device has shut down
    Log to console                Waiting for the robot finger to return
    Sleep  20
    Log to console                Booting the device by pressing the power button
    Press Button                  ${SWITCH_BOT}-ON
    Get Boot times                plot_name=Hard Boot Times

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
    Log to console                Shutting down by switching the power off
    Turn Relay Off                ${RELAY_NUMBER}
    Wait Until Keyword Succeeds   15s  2s  Check If Ping Fails
    Log to console                The device has shut down
    Log to console                Booting the device by switching the power on
    Turn Relay On                 ${RELAY_NUMBER}
    Get Time To Ping              plot_name=Hard Boot Times
    IF  "NX" in "${DEVICE}"       Sleep    30


*** Keywords ***

Measure Time To Ping
    [Arguments]               ${start_time}
    ${ping_response}          Set Variable  ${EMPTY}
    Log to console            Start checking ping response
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
    ${start_time_epoc}            DateTime.Get Current Date   result_format=epoch
    ${ping_response_seconds}      Measure Time To Ping  ${start_time_epoc}
    &{final_results}              Create Dictionary
    Set To Dictionary             ${final_results}  response_to_ping  ${ping_response_seconds}
    &{statistics}                 Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    Determine Test Status         ${statistics}  inverted=1

Get Boot times
    [Documentation]  Collect boot times from device
    [Arguments]  ${plot_name}=Soft Boot Times
    ${freedesktop_line}  Catenate  SEPARATOR=\n
    ...  freedesktop_line=$(journalctl --output=short-iso | grep "Successfully activated service 'org.freedesktop.systemd1'" | grep session)
    ...  echo $freedesktop_line
    # For detecting timestamp of Login screen in cosmic desktop
    ${testuser_line}  Catenate  SEPARATOR=\n
    ...  testuser_line=$(journalctl --output=short-iso | grep "testuser: changing state")
    ...  echo $testuser_line

    ${start_time_epoc}    DateTime.Get Current Date   result_format=epoch
    ${ping_response_seconds}    Measure Time To Ping    ${start_time_epoc}
    Sleep  30
    Connect to netvm
    Connect to VM  ${GUI_VM}
    ${time_to_desktop}  Run Keyword And Continue On Failure
    ...  Wait Until Keyword Succeeds  ${SEARCH_TIMEOUT1}s  1s  Check Time To Notification  ${freedesktop_line}   ${start_time_epoc}
    IF  $time_to_desktop == 'False'
        ${time_to_desktop}  Run Keyword And Continue On Failure
        ...  Wait Until Keyword Succeeds  ${SEARCH_TIMEOUT2}s  1s  Check Time To Notification  ${testuser_line}   ${start_time_epoc}
        Skip If   $time_to_desktop == 'False'  Skipping. The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.
    END
    Log                     Boot time to login screen measured: ${time_to_desktop}   console=True
    &{final_results}        Create Dictionary
    Set To Dictionary       ${final_results}  time_to_desktop  ${time_to_desktop}
    Set To Dictionary       ${final_results}  response_to_ping  ${ping_response_seconds}
    &{statistics}           Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    # In boot time test decrease in result value is considered improvement -> using inverted argument
    Determine Test Status   ${statistics}   inverted=1

Check Time To Notification
    [Documentation]  Check that correct notification is available in journalctl
    [Arguments]      ${command}   ${start_time}
    ${get_timestamp}  Catenate  SEPARATOR=\n
    ...  freedesktop_time=$(date -d "$(${command} | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $freedesktop_time
    ${notification_line}  Execute Command  ${command}
    IF  $notification_line == '${EMPTY}'
        RETURN  False
    END
    ${noticication_time}  Execute Command  ${get_timestamp}
    ${time}  Subtract Time From Time  ${noticication_time}  ${start_time}   exclude_millis=True
    Should Be True  0 < ${time} < 120
    RETURN  ${time}

Boot Time Test Setup
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Connect to ghaf host
        Verify service status   range=15  service=microvm@gui-vm.service  expected_status=active  expected_state=running
        Connect to netvm
        Connect to VM           ${GUI_VM}
        Create test user
    END
