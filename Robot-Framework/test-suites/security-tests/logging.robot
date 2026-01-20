# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check security in logs
Test Tags           logging  lenovo-x1  darter-pro  lab-only
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
    ${data_available}    ${logs}    Get logs by key words    ${USER_LOGIN}    hide_found_data=${False}
    ${found}  ${logs}    Get logs by key words   ${USER_PASSWORD}
    Should Not Be True   ${found}
    [Teardown]           Teardown Logs    ${data_available}

Check Grafana log forwarding after disconnected state
    [Documentation]  Check that logs are sent to Grafana from time of disconnection during previous boot
    [Tags]           SP-T283
    ${initial_check}  Set Variable  ${True}
    Switch to vm      ${ADMIN_VM}
    ${id}             Run Command  cat /etc/common/device-id
    Log To Console    Creating log entry and verifying forwarding to grafana
    Run Command       logger --priority=user.info "logtest0_${BUILD_ID}"    sudo=True
    Wait Until Keyword Succeeds  60s  5s  Check VM Log on Grafana  ${id}  ${ADMIN_VM}  2m  ${True}  logtest0_${BUILD_ID}
    ${initial_check}  Set Variable  ${False}
    Log To Console    Initial check for log forwarding passed

    Log To Console    Blocking log forwarding from admin-vm
    ${rule}           Set Variable   OUTPUT -p tcp --dport 443 -m owner --uid-owner "$(systemctl show alloy -p UID --value)" -j REJECT
    Run Command   iptables -I ${rule}    sudo=True
    Sleep             3
    Log To Console    Creating log entry and waiting 50 sec      no_newline=true
    Run Command   logger --priority=user.info "logtest1_${BUILD_ID}"    sudo=True
    FOR   ${i}   IN RANGE   50
        Log To Console   .  no_newline=true
        Sleep            1
    END

    Check VM Log on Grafana      ${id}   ${ADMIN_VM}   2m   ${False}   logtest1_${BUILD_ID}
    Log To Console               Verified that iptables rule is blocking log forwarding
    Soft Reboot Device
    Verify shutdown via network
    Connect After Reboot
    Login to laptop
    Wait Until Keyword Succeeds  60s  5s  Check VM Log on Grafana     ${id}   ${ADMIN_VM}   5m   ${True}   logtest1_${BUILD_ID}
    Log To Console               Checked that log is forwarded after clearing the iptables rule by reboot
    [Teardown]        Skip If    ${initial_check}   Known issue: SSRCSP-7612 (Grafana logging stops from a VM).\nDidn't find admin-vm logs in the initial check. Skipping the test.


*** Keywords ***

Setup logs
    Configure wifi      ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Sleep   3           # Time for needed data to be logged
    Switch to vm        ${HOST}
    ${device_id}        Get Actual Device ID
    Set Suite Variable  ${device_id}

Teardown Logs
    [Arguments]    ${data_checked}
    IF    '${TEST STATUS}' != 'FAIL'
        IF  not ${data_checked}
            # Logging from VM sometimes stops during the run (SSRCSP-7612).
            SKIP    There is not enough logs to check
        END
    END

