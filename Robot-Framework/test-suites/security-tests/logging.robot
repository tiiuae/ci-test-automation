# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check security in logs
Force Tags          security  regression  logging  darter-pro
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Library             DateTime

Suite Setup         Setup logs
Suite Teardown      Remove Wifi configuration  ${TEST_WIFI_SSID}


*** Test Cases ***

Wifi password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain wifi password
    [Tags]           SP-T328
    ${data_available}    ${logs}    Get logs by key words   ${TEST_WIFI_SSID}
    ${found}  ${logs}    Get logs by key words   ${TEST_WIFI_PSWD}
    Should Not Be True   ${found}
    [Teardown]           Teardown Logs    ${data_available}

User password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain user's password
    [Tags]           SP-T328
    ${data_available}    ${logs}    Get logs by key words   ${USER_LOGIN}
    ${found}  ${logs}    Get logs by key words   ${USER_PASSWORD}
    Should Not Be True   ${found}
    [Teardown]           Teardown Logs    ${data_available}


*** Keywords ***

Setup logs
    Configure wifi      ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Sleep   3           # Time for needed data to be logged
    Switch to vm        ${HOST}
    ${device_id}        Execute Command   cat /persist/common/device-id
    Set Suite Variable  ${device_id}

Teardown Logs
    [Arguments]    ${data_checked}
    IF    '${TEST STATUS}' != 'FAIL'
        IF  not ${data_checked}
            # Logging from VM sometimes stops during the run (SSRCSP-7612).
            SKIP    There is not enough logs to check
        END
    END

Get latest log's time
    [Arguments]      ${logs}
    ${lines}         Split To Lines      ${logs}
    ${last_line}     Get From List       ${lines}    1     # first line in output contains 'technical' data with different data format
    ${ts_pattern}    Set Variable        ^(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z)
    ${matches}       Get Regexp Matches  ${last_line}  ${ts_pattern}
    Log              Last timestamp: ${matches[0]}
    RETURN           ${matches[0]}

Get logs by key words
    [Arguments]      ${word}    ${period}=1d
    Set Log Level    NONE
    ${logs}          Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="${period}" --limit="100" '{machine="${device_id}"} |= `${word}`'
    ${lines}         Split To Lines    ${logs}
    Remove From List    ${lines}    0    # contains full query including potentially sensitive searched word
    Set Log Level    INFO
    ${length}        Get Length   ${lines}
    ${status}        Run Keyword And Return Status  Should Be True  ${length} > 0   Logs do not contain searched word
    IF    ${status}
        ${logs}            Catenate    SEPARATOR=\n    @{lines}
        ${last_log_time}   Get latest log's time   ${logs}
    END
    Log              ${logs}
    RETURN           ${status}    ${logs}
