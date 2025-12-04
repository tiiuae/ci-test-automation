# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check security in logs
Force Tags          security  regression  logging  darter-pro
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Library             DateTime


*** Test Cases ***

Passwords are not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain sensitive data like passwords
    [Tags]           SP-T328
    [Setup]          Setup logs
    ${logs}          Get grafana logs    ${GUI_VM}
    Check sensitive WiFi data in logs    ${logs}
    Check sensitive User's data in logs  ${logs}
    [Teardown]       Remove Wifi configuration  ${TEST_WIFI_SSID}


*** Keywords ***

Setup logs
    Create logs with sensitive data
    Switch to vm       ${HOST}
    ${device_id}       Execute Command   cat /persist/common/device-id
    Set Test Variable  ${device_id}

Create logs with sensitive data

    ${from}          Get Current Date    UTC    result_format=%Y-%m-%dT%H:%M:%SZ
    Set Test Variable    ${from}
    Configure wifi   ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Switch to vm     ${GUI_VM}  user=${USER_LOGIN}

Get grafana logs
    [Arguments]      ${host}
    FOR   ${i}   IN RANGE  15
    #    Set Log Level    NONE
    #    Wait Until Keyword Succeeds  60s  5s
        ${logs}          Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --from="${from}" --limit="5000" '{machine="${device_id}"}'
    #    ${logs}          Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="5m" --limit="1000" '{machine="${device_id}", host="${host}"} |= `${text}`'
    #    Set Log Level    INFO
        ${lines}    Count lines    ${logs}
        ${status}  ${output}  Run Keyword And Ignore Error  Should Be True  ${lines} > 1   Query does not contain logs
        IF   $status == 'PASS'
            Sleep    5
            ${logs}          Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --from="${from}" --limit="5000" '{machine="${device_id}"}'
            BREAK
        ELSE
            Sleep    3
        END
    END

    ${lines}          Split To Lines   ${logs}
    ${last_line}      Get From List    ${lines}    -1
    ${ts_pattern}     Set Variable    ^(\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2})
    ${matches}        Get Regexp Matches    ${last_line}    ${ts_pattern}
    ${last_ts}        Set Variable    ${matches[0]}
    ${iso_ts}         Convert Date    ${last_ts}    date_format=%Y/%m/%d %H:%M:%S   result_format=%Y-%m-%dT%H:%M:%SZ
    Log    Last timestamp: ${last_ts}
    ${is_later}       Evaluate    '${last_ts}' > '${from}'
    IF    ${is_later}
        ${logs2}      Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --from="${from}" --to="${iso_ts}" --limit="5000" '{machine="${device_id}"}'
        ${lines1}     Split To Lines    ${logs}
        ${lines2}     Split To Lines    ${logs2}

        ${all}        Combine Lists     ${lines1}    ${lines2}
        ${unique}     Remove Duplicates    ${all}

        ${logs}   Catenate    SEPARATOR=\n    @{unique}

    END

    Log              ${logs}
    [Return]         ${logs}

Check sensitive User's data in logs
    [Arguments]      ${logs}
#    ${logs}          Get grafana logs    ${GUI_VM}
    Run Keyword And Continue On Failure   Should Contain      ${logs}   ${USER_LOGIN}
    Run Keyword And Continue On Failure   Should Not Contain  ${logs}   ${USER_PASSWORD}

Check sensitive WiFi data in logs
    [Arguments]      ${logs}
#    ${logs}          Get grafana logs    ${NETVM_NAME}
    Run Keyword And Continue On Failure   Should Contain      ${logs}   ${TEST_WIFI_SSID}
    Run Keyword And Continue On Failure   Should Not Contain  ${logs}   ${TEST_WIFI_PSWD}
