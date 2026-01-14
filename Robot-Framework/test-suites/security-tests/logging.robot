# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check security in logs
Test Tags           logging  lenovo-x1  darter-pro
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/setup_keywords.resource
Library             DateTime
Library             String

Suite Setup         Setup logs
Suite Teardown      Remove Wifi configuration  ${TEST_WIFI_SSID}


*** Test Cases ***

Wifi password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain wifi password
    [Tags]           SP-T328  SP-T328-1
    ${data_available}    ${logs}    Get logs by key words   ${TEST_WIFI_SSID}   hide_found_data=${False}
    ${found}  ${logs}    Get logs by key words   ${TEST_WIFI_PSWD}
    Should Not Be True   ${found}
    [Teardown]           Teardown Logs    ${data_available}

User password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain user's password
    [Tags]           SP-T328  SP-T328-2
    ${data_available}    ${logs}    Get logs by key words   ${USER_LOGIN}    hide_found_data=${False}
    ${found}  ${logs}    Get logs by key words   ${USER_PASSWORD}
    Should Not Be True   ${found}
    [Teardown]           Teardown Logs    ${data_available}

Check Grafana log forwarding after disconnected state
    [Documentation]  Check that logs are sent to Grafana from time of disconnection during previous boot
    [Tags]           SP-T283
    ${initial_check}  Set Variable  ${True}
    Switch to vm      ${ADMIN_VM}
    ${id}             Execute Command  cat /etc/common/device-id
    Log To Console    Creating log entry and verifying forwarding to grafana
    Execute Command   logger --priority=user.info "logtest0_${BUILD_ID}"    sudo=True  sudo_password=${PASSWORD}
    Wait Until Keyword Succeeds  60s  5s  Check VM Log on Grafana  ${id}  ${ADMIN_VM}  2  ${True}  logtest0_${BUILD_ID}
    ${initial_check}  Set Variable  ${False}
    Log To Console    Initial check for log forwarding passed

    Log To Console    Blocking log forwarding from admin-vm
    ${rule}           Set Variable   OUTPUT -p tcp --dport 443 -m owner --uid-owner "$(systemctl show alloy -p UID --value)" -j REJECT
    Execute Command   iptables -I ${rule}    sudo=True  sudo_password=${PASSWORD}
    Sleep             3
    Log To Console    Creating log entry and waiting 50 sec      no_newline=true
    Execute Command   logger --priority=user.info "logtest1_${BUILD_ID}"    sudo=True  sudo_password=${PASSWORD}
    FOR   ${i}   IN RANGE   50
        Log To Console   .  no_newline=true
        Sleep            1
    END

    Check VM Log on Grafana      ${id}   ${ADMIN_VM}   2   ${False}   logtest1_${BUILD_ID}
    Log To Console               Verified that iptables rule is blocking log forwarding
    Soft Reboot Device
    Verify Reboot and Connect
    Login to laptop
    Wait Until Keyword Succeeds  60s  5s  Check VM Log on Grafana     ${id}   ${ADMIN_VM}   5   ${True}   logtest1_${BUILD_ID}
    Log To Console               Checked that log is forwarded after clearing the iptables rule by reboot
    [Teardown]        Skip If    ${initial_check}   Konwn issue: SSRCSP-7612 (Grafana logging stops from a VM).\nDidn't find admin-vm logs in the initial check. Skipping the test.


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

Get logs by key words
    [Arguments]      ${word}    ${period}=1d    ${hide_found_data}=${True}
    [Documentation]    Search and get logs from Grafana
    ...                *Args*'\n:
    ...                - word - key word to find in log line
    ...                - period - sets a period of time for searching to limit lines, 1 day by default
    ...                - hide_found_data - replace found pattern with a placeholder to hid it robot logs in case of sensitive data
    Set Log Level    NONE
    ${logs}          Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="${period}" --limit="100" '{machine="${device_id}"} |= `${word}`'
    IF    ${hide_found_data}
        ${logs}          Replace String    string=${logs}        search_for=${word}        replace_with=<***HIDDEN_SENSITIVE_DATA***>
    END
    ${lines}         Split To Lines    ${logs}
    Remove From List    ${lines}    0    # contains full query including potentially sensitive searched word
    Set Log Level    INFO
    ${length}        Get Length   ${lines}
    ${status}        Run Keyword And Return Status  Should Be True  ${length} > 0   Logs do not contain searched word
    Log              ${logs}
    RETURN           ${status}    ${logs}
