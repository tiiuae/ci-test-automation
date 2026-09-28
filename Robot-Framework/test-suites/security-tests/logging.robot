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
Resource            ../../resources/logging_keywords.resource
Resource            ../../resources/time_keywords.resource
Library             DateTime
Library             Collections
Library             String

Suite Setup         Logging Setup


*** Test Cases ***

Wifi password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain wifi password
    [Tags]           SP-T328  SP-T328-1  bat  orin-agx  orin-agx-64  lab-only
    Skip If Grafana Unreachable
    Configure wifi   ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Sleep   3        # Time for needed data to be logged
    Is password revealed in Grafana    ${TEST_WIFI_SSID}    ${TEST_WIFI_PSWD}
    [Teardown]       Remove Wifi configuration  ${TEST_WIFI_SSID}

User password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain user's password
    [Tags]           SP-T328  SP-T328-2  bat
    Skip If Grafana Unreachable
    Is password revealed in Grafana    ${USER_LOGIN}    ${USER_PASSWORD}

Check Grafana log forwarding after disconnected state
    [Documentation]  Check that logs are sent to Grafana from time of disconnection during previous boot
    [Tags]           SP-T283  orin-agx  orin-agx-64  orin-nx  lab-only
    Switch to vm      ${ADMIN_VM}
    ${id}             Get Actual Device ID
    Log To Console    Creating log entry and verifying forwarding to grafana
    Run Command       logger --priority=user.info "logtest0_${BUILD_ID}"    sudo=True
    Wait Until Keyword Succeeds  60s  5s  Check VM Log on Grafana  ${id}  ${ADMIN_VM}  2m  ${True}  logtest0_${BUILD_ID}
    Log To Console    Initial check for log forwarding passed

    Log To Console    Blocking log forwarding from admin-vm
    ${rule}           Set Variable   OUTPUT -p tcp --dport 443 -m owner --uid-owner "$(systemctl show alloy -p UID --value)" -j REJECT
    Run Command       iptables -I ${rule}    sudo=True
    Sleep             3
    Log To Console    Creating log entry and waiting 50 sec      no_newline=true
    Run Command       logger --priority=user.info "logtest1_${BUILD_ID}"    sudo=True
    FOR   ${i}   IN RANGE   50
        Log To Console   .  no_newline=true
        Sleep            1
    END

    Check VM Log on Grafana      ${id}   ${ADMIN_VM}   2m   ${False}   logtest1_${BUILD_ID}
    Log To Console               Verified that iptables rule is blocking log forwarding
    IF  ${IS_LAPTOP}
        Soft Reboot Device And Connect   vm=${GUI_VM}
        Login to laptop
    ELSE
        Soft Reboot Device And Connect   vm=${HOST}     retry=60
    END
    Wait Until Keyword Succeeds  120s  5s  Check VM Log on Grafana     ${id}   ${ADMIN_VM}   5m   ${True}   logtest1_${BUILD_ID}
    Log To Console               Checked that log is forwarded after clearing the iptables rule by reboot

Log sealing works after clock change
    [Documentation]  Verify that log sealing passes before, during, and after VM clock changes
    [Tags]           SP-T377
    Verify Time And Log Sealing In VMs    0    log_sealing_before_clock_change_${BUILD_ID}    @{VM_LIST}

    Change Time And Verify Log Sealing In VMs
    ...    1800    log_sealing_after_clock_change_${BUILD_ID}    @{VM_LIST}

    Restore Time And Verify Log Sealing In VMs
    ...    log_sealing_after_clock_restore_${BUILD_ID}    @{VM_LIST}
    [Teardown]    Restore System Time In VMs    @{VM_LIST}

*** Keywords ***

Logging Setup
    Switch to vm        ${HOST}
    ${device_id}        Get Actual Device ID
    Set Suite Variable  ${device_id}
    @{VM_LIST}          Get VM list  with_host=True
    Set Suite Variable  @{VM_LIST}

Is password revealed in Grafana
    [Arguments]          ${id}    ${pw}
    ${data_available}    ${logs}    Get logs by key words   ${id}
    IF  not ${data_available}
        FAIL    Not enough logs for the test.\nCheck if log forwarding is broken.
    END
    ${found}  ${logs}    Get logs by key words   ${pw}
    Should Not Be True   ${found}    ALERT: password leak to grafana detected

Verify Time And Log Sealing In VMs
    [Documentation]    Verify clock offset and log sealing with one connection switch per VM
    [Arguments]        ${expected_offset_seconds}    ${log}    @{vms}
    @{failures}        Create List
    FOR    ${vm}    IN    @{vms}
        Switch To Vm    ${vm}
        ${actual_offset}    Wait Until Keyword Succeeds
        ...    60s    5s    Check System Time Offset    ${expected_offset_seconds}
        TRY
            Verify Log Sealing In Current VM    ${vm}    ${log}
            Log    ${vm}: clock offset ${actual_offset}s    console=True
        EXCEPT    AS    ${error}
            Append To List    ${failures}    Verification failed in ${vm}: ${error}
        END
    END
    Should Be Empty    ${failures}    Time or log sealing failures: ${failures}

Change Time And Verify Log Sealing In VMs
    [Documentation]    Change time and verify log sealing with one connection switch per VM
    [Arguments]        ${offset_seconds}    ${log}    @{vms}
    @{failures}        Create List
    FOR    ${vm}    IN    @{vms}
        TRY
            Switch To Vm    ${vm}
            ${service_name}    Set Variable If
            ...    '${vm}' == '${NET_VM}'    chronyd.service    systemd-timesyncd.service
            Stop Timesync Daemon    ${service_name}
            Set System Time Offset    ${offset_seconds}
            Verify Log Sealing In Current VM    ${vm}    ${log}
        EXCEPT    AS    ${error}
            Append To List    ${failures}    Clock change or log sealing failed in ${vm}: ${error}
        END
    END
    Should Be Empty    ${failures}    Clock change or log sealing failures: ${failures}

Restore Time And Verify Log Sealing In VMs
    [Documentation]    Restore time and verify log sealing with one connection switch per VM
    [Arguments]        ${log}    @{vms}
    @{failures}        Create List
    FOR    ${vm}    IN    @{vms}
        TRY
            Switch To Vm    ${vm}
            ${service_name}    Set Variable If
            ...    '${vm}' == '${NET_VM}'    chronyd.service    systemd-timesyncd.service
            Restore System Time
            Start Timesync Daemon    ${service_name}
            Wait Until Keyword Succeeds    30s    2s    Check System Time Offset    0
            Verify Log Sealing In Current VM    ${vm}    ${log}
        EXCEPT    AS    ${error}
            Append To List    ${failures}    Time restore or log sealing failed in ${vm}: ${error}
        END
    END
    Should Be Empty    ${failures}    Time restore or log sealing failures: ${failures}
