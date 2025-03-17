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
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}  ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}
Library             DateTime
Library             Collections
Suite Setup         Boot Time Test Setup


*** Variables ***
${PING_TIMEOUT}     80
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


*** Keywords ***

Get Boot times
    [Documentation]  Collect boot times from device
    [Arguments]  ${plot_name}=Soft Boot Times
    ${ping_response}    Set Variable  ${EMPTY}
    ${cmd1}  Catenate   SEPARATOR=\n  current_timestamp=$(expr $(date '+%s%N') / 1000000000)
    ...  echo $current_timestamp
    ${cmd2}  Catenate   SEPARATOR=\n  since_nixos_menu=$(awk '{print $1}' /proc/uptime)
    ...  echo $since_nixos_menu
    ${cmd3}  Catenate   SEPARATOR=\n
    ...  welcome_note=$(date -d "$(journalctl --output=short-iso | grep gui-vm | grep "Welcome" | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $welcome_note
    ${freedesktop_line}  Catenate  SEPARATOR=\n
    ...  freedesktop_line=$(journalctl --output=short-iso | grep "Successfully activated service 'org.freedesktop.systemd1'" | grep session)
    ...  echo $freedesktop_line
    # For detecting timestamp of Login screen in cosmic desktop
    ${testuser_line}  Catenate  SEPARATOR=\n
    ...  testuser_line=$(journalctl --output=short-iso | grep "testuser: changing state")
    ...  echo $testuser_line

    ${start_time_epoc}    DateTime.Get Current Date   result_format=epoch

    Log to console        Start checking ping response
    ${ping_end_time}  Set Variable  False
    WHILE  not $ping_response   limit=${PING_TIMEOUT} seconds
        ${ping_response}  Ping Host  ${DEVICE_IP_ADDRESS}  1
        ${ping_end_time}  IF  $ping_response  DateTime.Get Current Date  result_format=epoch
    END
    IF  not $ping_end_time
        FAIL  No response to ping within ${PING_TIMEOUT}
    END
    ${ping_response_seconds}  DateTime.Subtract Date From Date  ${ping_end_time}  ${start_time_epoc}   exclude_millis=True
    Log                       Response time to ping measured: ${ping_response_seconds}   console=True

    Sleep  30
    Connect to netvm
    Connect to VM  ${GUI_VM}

    ${time_from_reboot_to_desktop_available}  Run Keyword And Continue On Failure
    ...  Wait Until Keyword Succeeds  ${SEARCH_TIMEOUT1}s  1s  Check Time To Notification  ${freedesktop_line}   ${start_time_epoc}

    IF  $time_from_reboot_to_desktop_available == 'False'
        ${time_from_reboot_to_desktop_available}  Run Keyword And Continue On Failure
        ...  Wait Until Keyword Succeeds  ${SEARCH_TIMEOUT2}s  1s  Check Time To Notification  ${testuser_line}   ${start_time_epoc}
        Skip If   $time_from_reboot_to_desktop_available == 'False'  Skipping. The searched journalctl line is sometimes (randomly) not there. Didn't find it this time.
    END
    Log                     Boot time to login screen measured: ${time_from_reboot_to_desktop_available}   console=True
    &{final_results}        Create Dictionary
    Set To Dictionary       ${final_results}  time_from_reboot_to_desktop_available  ${time_from_reboot_to_desktop_available}
    Set To Dictionary       ${final_results}  response_to_ping  ${ping_response_seconds}
    &{statistics}           Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML

    &{statistics_desktop}  Get From Dictionary   ${statistics}   statistics_desktop
    &{statistics_ping}     Get From Dictionary   ${statistics}   statistics_ping

    ${fail_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_desktop}[flag]" == "1"
        ${add_msg}      Create fail message  ${statistics_desktop}
        ${fail_msg}=    Set Variable  Time to desktop:\n${add_msg}
    END
    IF  "${statistics_ping}[flag]" == "1"
        ${add_msg}      Create fail message  ${statistics_ping}
        ${fail_msg}=    Set Variable  ${fail_msg}\nTime to ping response:\n${add_msg}
    END
    IF  "${statistics_desktop}[flag]" == "1" or "${statistics_ping}[flag]" == "1"
        FAIL            ${fail_msg}
    END

    ${pass_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_desktop}[flag]" == "-1"
        ${add_msg}      Create improved message  ${statistics_desktop}
        ${pass_msg}=    Set Variable  Time to desktop:\n${add_msg}
    END
    IF  "${statistics_ping}[flag]" == "-1"
        ${add_msg}      Create improved message  ${statistics_ping}
        ${pass_msg}=    Set Variable  ${pass_msg}\nTime to ping response:\n${add_msg}
    END
    IF  "${statistics_desktop}[flag]" == "-1" or "${statistics_ping}[flag]" == "-1"
        Pass Execution    ${pass_msg}
    END

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
