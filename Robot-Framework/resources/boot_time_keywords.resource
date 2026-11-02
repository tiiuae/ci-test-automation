# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Library             Collections
Library             DateTime
Resource            device_control.resource
Resource            performance_data_processing.resource
Resource            performance_keywords.resource
Resource            ssh_keywords.resource
Variables           ../lib/performance_thresholds.py


*** Variables ***
${BOOT_PING_TIMEOUT}        180
${BOOT_SEARCH_TIMEOUT}      60


*** Keywords ***
Measure Time To Ping
    [Arguments]               ${start_time}  ${timeout}=${BOOT_PING_TIMEOUT}
    ${ping_response}          Set Variable    ${EMPTY}
    Log To Console            Start checking ping response
    ${ping_end_time}          Set Variable    False
    WHILE  not $ping_response   limit=${timeout} seconds
        ${ping_response}      Ping Host  ${DEVICE_IP_ADDRESS}  3
        IF  $ping_response
            ${ping_end_time}  DateTime.Get Current Date  result_format=epoch
            Sleep             ${PING_SPACING}
        END
    END
    IF  not $ping_end_time
        FAIL                  No response to ping within ${timeout}
    END
    ${ping_response_seconds}  DateTime.Subtract Date From Date  ${ping_end_time}  ${start_time}   exclude_millis=True
    Log                       Response time to ping measured: ${ping_response_seconds}   console=True
    RETURN                    ${ping_response_seconds}    ${ping_end_time}

Get Time To Ping
    [Arguments]  ${plot_name}=Soft Boot Times  ${save_performance_data}=${True}
    ...          ${persist_result}=${False}  ${timeout}=${BOOT_PING_TIMEOUT}  ${start_time}=${EMPTY}
    ...          ${end_time}=${EMPTY}
    IF  '${start_time}' == '${EMPTY}'
        ${start_time_epoch}   DateTime.Get Current Date   result_format=epoch
    ELSE
        ${start_time_epoch}   Set Variable   ${start_time}
    END
    IF  '${end_time}' == '${EMPTY}' or '${end_time}' == 'False'
        ${ping_response_seconds}    ${ping_timestamp}     Measure Time To Ping
        ...    ${start_time_epoch}    ${timeout}
    ELSE
        ${ping_timestamp}    Set Variable    ${end_time}
        ${ping_response_seconds}  DateTime.Subtract Date From Date  ${end_time}  ${start_time_epoch}
        ...                       exclude_millis=True
        Log                       Response time to ping measured: ${ping_response_seconds}   console=True
    END
    &{final_results}          Create Dictionary
    Set To Dictionary         ${final_results}  response_to_ping  ${ping_response_seconds}
    Check Result Validity     ${final_results}
    IF  ${persist_result}
        Save Boot Time Results To Ghaf    ${ping_response_seconds}    ${ping_timestamp}
    END
    IF  ${save_performance_data}
        &{statistics}          Save Boot time Data   ${TEST NAME}  ${final_results}
        Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
        Determine Test Status  ${statistics}  inverted=1
    END
    RETURN                    ${final_results}

Save Time To Ping On Target Device
    [Documentation]    Saves the ping time and reply timestamp for boot-health gap boundaries.
    ...                Measures the time if unavailable; failures are logged without failing the test.
    [Arguments]    ${start_time}    ${timeout}    ${end_time}=${BOOT_PING_TIME}
    TRY
        Get Time To Ping    save_performance_data=${False}    persist_result=${True}
        ...    timeout=${timeout}    start_time=${start_time}    end_time=${end_time}
    EXCEPT    AS    ${error}
        Log    Could not collect boot time result: ${error}    level=WARN
    END

Get Boot times
    [Documentation]  Collect boot times from device.
    [Arguments]  ${plot_name}=Soft Boot Times  ${save_performance_data}=${True}
    ...          ${persist_result}=${False}  ${ping_timeout}=${BOOT_PING_TIMEOUT}
    ...          ${desktop_timeout}=${BOOT_SEARCH_TIMEOUT}  ${desktop_limit}=120  ${start_time}=${EMPTY}
    IF  '${start_time}' == '${EMPTY}'
        ${start_time_epoch}  DateTime.Get Current Date   result_format=epoch
    ELSE
        ${start_time_epoch}  Set Variable   ${start_time}
    END
    ${testuser_line}     Catenate  SEPARATOR=\n
    ...  testuser_line=$(journalctl -b --output=short-iso | grep "${USER_LOGIN}: changing state activating-for-acquire")
    ...  echo $testuser_line

    ${ping_response_seconds}    ${ping_timestamp}     Measure Time To Ping
    ...    ${start_time_epoch}    ${ping_timeout}
    Switch to vm               ${GUI_VM}
    ${time_to_desktop}         Check Time To Notification  ${testuser_line}  ${start_time_epoch}
    ...                         ${desktop_timeout}  ${desktop_limit}
    Log                        Boot time to login screen measured: ${time_to_desktop}   console=True
    &{final_results}           Create Dictionary
    Set To Dictionary          ${final_results}  time_to_desktop  ${time_to_desktop}
    Set To Dictionary          ${final_results}  response_to_ping  ${ping_response_seconds}
    Check Result Validity      ${final_results}
    IF  ${persist_result}
        Save Boot Time Results To Ghaf    ${ping_response_seconds}    ${ping_timestamp}
    END
    IF  ${save_performance_data}
        &{statistics}           Save Boot time Data   ${TEST NAME}  ${final_results}
        Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
        Determine Test Status   ${statistics}   inverted=1
    END
    RETURN                     ${final_results}

Check Time To Notification
    [Documentation]  Check that the desktop notification is available in journalctl.
    [Arguments]  ${command}  ${start_time}  ${timeout}=${BOOT_SEARCH_TIMEOUT}  ${time_limit}=120
    ${notification_line}  Set Variable    ${EMPTY}
    WHILE  '${notification_line}' == '${EMPTY}'   limit=${timeout} seconds
        ${notification_line}    Run Command    ${command}
    END
    IF  '${notification_line}' == '${EMPTY}'
        Fail  The searched journalctl line that is needed for boot-time calculation was not captured.
    END
    ${get_timestamp}      Catenate  SEPARATOR=\n
    ...  desktop_time=$(date -d "$(${command} | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $desktop_time
    ${notification_time}  Run Command    ${get_timestamp}
    ${time}               Subtract Time From Time  ${notification_time}  ${start_time}  exclude_millis=True
    Should Be True        0 < ${time} < ${time_limit}
    RETURN                ${time}

Check Result Validity
    [Arguments]  ${captured_results}
    FOR  ${key}  ${value}  IN  &{captured_results}
        IF  '${value}' == 'nan'
            CONTINUE
        END
        Should Be True  ${value} > 0
    END

Save Boot Time Results To Ghaf
    [Arguments]  ${response_to_ping}    ${ping_timestamp}
    Switch to vm  ${HOST}
    Run Command  sh -c "echo ${response_to_ping} > /persist/common/first_boot_to_ping"  sudo=True
    ${ping_timestamp_utc}    Run Command
    ...    date -u -d @${ping_timestamp} '+%Y-%m-%dT%H:%M:%S.%N+00:00'
    Run Command  sh -c "echo ${ping_timestamp_utc} > /persist/common/first_boot_to_ping_timestamp"  sudo=True
    ${boot_id}    Run Command    cat /proc/sys/kernel/random/boot_id
    Run Command    sh -c "echo ${boot_id} > /persist/common/first_boot_to_ping_boot_id"    sudo=True
