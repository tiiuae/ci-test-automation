# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device bootup time.
Force Tags          ssh_boot_test
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../config/variables.robot
Variables           ../../lib/performance_thresholds.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}  ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}
Library             DateTime
Library             Collections


*** Variables ***
${BOOT_TIME}  ${thresholds}[boot_time][time_to_bootup]
${TIME_TO_RESPOND_TO_SSH}  ${thresholds}[boot_time][time_to_respond_to_ssh]
${TIME_TO_RESPOND_TO_PING}  ${thresholds}[boot_time][time_to_respond_to_ping]
${TIME_TO_DESKTOP_AFTER_REBOOT}  ${thresholds}[boot_time][time_to_desktop_after_reboot]


*** Test Cases ***

Measure Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]  SP-T187  lenovo-x1
    Soft Reboot Device
    Wait Until Keyword Succeeds  25s  2s  Check If Ping Fails
    Get Boot times

Measure Hard Boot Time
    [Documentation]  Measure how long it takes to device to boot up with hard reboot
    [Tags]  SP-T182  lenovo-x1
    Press Button      ${SWITCH_BOT}-OFF
    Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    Sleep  5  # Wait until switchbot has pressed and returned button
    Press Button      ${SWITCH_BOT}-ON
    Get Boot times  hard  image_name=Hard Boot Times


*** Keywords ***
Get Boot times
    [Documentation]  Collect boot times from device
    [Arguments]  ${boot_type}=soft  ${image_name}=Soft Boot Times
    ${ping_response}  Set Variable  False
    ${ssh_response}  Set Variable  False
    ${cmd1}  Catenate  SEPARATOR=\n  current_timestamp=$(expr $(date '+%s%N') / 1000000000)
    ...  echo $current_timestamp
    ${cmd2}  Catenate  SEPARATOR=\n  since_nixos_menu=$(awk '{print $1}' /proc/uptime)
    ...  echo $since_nixos_menu
    ${cmd3}  Catenate  SEPARATOR=\n
    ...  welcome_note=$(date -d "$(journalctl --output=short-iso | grep gui-vm | grep "Welcome" | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $welcome_note
    ${freedesktop}  Catenate  SEPARATOR=\n
    ...  freedesktop=$(date -d "$(journalctl --output=short-iso | grep "Successfully activated service 'org.freedesktop.systemd1'" | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $freedesktop

    ${start_time}  DateTime.Get Current Date
    Log to console  Start checking ping and ssh response
    WHILE  not (${ping_response} and ${ssh_response})   limit=${BOOT_TIME} seconds
        ${connection}  Open Connection    ${DEVICE_IP_ADDRESS}    port=22    prompt=\$    timeout=2
        ${ssh_response}  Run Keyword And Return Status  Login     username=${LOGIN}    password=${PASSWORD}
        ${ssh_end_time}  IF  ${ssh_response}  DateTime.Get Current Date  ELSE  Set Variable  False
        ${ping_response}  IF  not ${ping_response}  Ping Host  ${DEVICE_IP_ADDRESS}
        ${ping_end_time}  IF  ${ping_response}  DateTime.Get Current Date  ELSE  Set Variable  False
    END
    Connect to ghaf host
    ${current_timestamp}  Execute Command  ${cmd1}
    ${time_from_nixos_menu_tos_ssh}  Execute Command  ${cmd2}  # uptime
    ${nixos_menu_timestamp}  Subtract Time From Time  ${current_timestamp}  ${time_from_nixos_menu_tos_ssh}
    ${start_time_epoc}  Convert Date  ${start_time}  epoch

    Connect to netvm
    Connect to VM  ${GUI_VM}
    ${time_from_reboot_to_desktop_available}  Run Keyword And Continue On Failure
    ...  Wait Until Keyword Succeeds  ${TIME_TO_DESKTOP_AFTER_REBOOT}s  1s  Check Log For Notification  ${freedesktop}  ${start_time_epoc}

    ${ping_response_seconds}  IF  ${ping_response}  DateTime.Subtract Date From Date  ${ping_end_time}  ${start_time}    exclude_millis=True
    ${ssh_response_seconds}  IF  ${ssh_response}  DateTime.Subtract Date From Date  ${ssh_end_time}  ${start_time}    exclude_millis=True

    &{final_results}  Create Dictionary
    Set To Dictionary  ${final_results}  time_from_nixos_menu_tos_ssh  ${time_from_nixos_menu_tos_ssh}
    Set To Dictionary  ${final_results}  time_from_reboot_to_desktop_available  ${time_from_reboot_to_desktop_available}
    Set To Dictionary  ${final_results}  response_to_ping  ${ping_response_seconds}
    Set To Dictionary  ${final_results}  response_to_ssh  ${ssh_response_seconds}
    Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${image_name}" width="1200">    HTML
    IF  '${boot_type}' == 'soft'
        Run Keyword And Continue On Failure  Should Be True  ${ping_response_seconds} <= ${TIME_TO_RESPOND_TO_PING}
        Run Keyword And Continue On Failure  Should Be True  ${ssh_response_seconds} <= ${TIME_TO_RESPOND_TO_SSH}
    ELSE
        Run Keyword And Continue On Failure  Should Be True  ${ping_response_seconds} <= ${${TIME_TO_RESPOND_TO_PING} + 10}
        Run Keyword And Continue On Failure  Should Be True  ${ssh_response_seconds} <= ${${TIME_TO_RESPOND_TO_SSH} + 10}
    END
    Should Be True  ${time_from_reboot_to_desktop_available} <= ${TIME_TO_DESKTOP_AFTER_REBOOT}

Check Log For Notification
    [Documentation]  Check that correct notification is available in journalctl
    [Arguments]  ${command}  ${current_time}
    ${notification}  Execute Command  ${command}
    Should Not Be Empty  ${notification}
    ${time}  Subtract Time From Time  ${notification}  ${current_time}
    Should Be True  0 < ${time} < 120
    RETURN  ${time}
