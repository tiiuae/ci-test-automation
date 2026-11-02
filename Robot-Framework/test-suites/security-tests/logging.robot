# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Check security in logs

Library             Collections
Library             DateTime
Library             String
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/logging_keywords.resource
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/time_keywords.resource
Resource            ../../resources/wifi_keywords.resource

Suite Setup         Logging Setup

Test Tags           logging  lenovo-x1  darter-pro


*** Test Cases ***
Wifi password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain wifi password
    [Tags]           SP-T456  bat  orin-agx  orin-agx-64  lab-only
    Skip If Grafana Unreachable
    Configure wifi   ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Sleep   3        # Time for needed data to be logged
    Is password revealed in Grafana    ${TEST_WIFI_SSID}    ${TEST_WIFI_PSWD}
    [Teardown]       Remove Wifi configuration  ${TEST_WIFI_SSID}

User password is not revealed in Grafana
    [Documentation]  Check that logs in Grafana don't contain user's password
    [Tags]           SP-T457  bat
    Skip If Grafana Unreachable
    Is password revealed in Grafana    ${USER_LOGIN}    ${USER_PASSWORD}

Check Grafana log forwarding after disconnected state
    [Documentation]  Check that logs are sent to Grafana from time of disconnection during previous boot
    [Tags]           SP-T283  orin-agx  orin-agx-64  orin-nx  lab-only
    Skip If Grafana Unreachable
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
    Soft Reboot Device And Connect
    Wait Until Keyword Succeeds  120s  5s  Check VM Log on Grafana     ${id}   ${ADMIN_VM}   5m   ${True}   logtest1_${BUILD_ID}
    Log To Console               Checked that log is forwarded after clearing the iptables rule by reboot

Persist journal upload cursors across reboots
    [Documentation]    Verify that rebooting audio-vm does not replay journal entries already received by admin-vm.
    ...                Confirm forwarding resumes with a new entry and the original entry remains unique.
    [Tags]             SP-T521
    ${log_dir}         Set Variable    /var/log/ghaf-journal/shared
    Switch to vm       ${AUDIO_VM}
    ${marker}          Run Command    printf 'ghaf-replay-%s' "$(cat /proc/sys/kernel/random/uuid)"
    ${boot_id}         Run Command    cat /proc/sys/kernel/random/boot_id
    Run Command        logger -t ghaf-replay-test -- '${marker}'
    Run Command        journalctl --sync    sudo=True
    Switch to vm       ${ADMIN_VM}
    Wait Until Keyword Succeeds    10s    2s    Verify Received Journal Entry Count    ${log_dir}    ${marker}
    Restart VM         ${AUDIO_VM}
    Switch to vm       ${AUDIO_VM}
    ${boot_id_after}   Run Command    cat /proc/sys/kernel/random/boot_id
    Should Not Be Equal    ${boot_id_after}    ${boot_id}    ${AUDIO_VM} did not reboot: boot_id is unchanged
    Run Command        logger -t ghaf-replay-test -- '${marker}-after-reboot'
    Run Command        journalctl --sync    sudo=True
    Switch to vm       ${ADMIN_VM}
    Wait Until Keyword Succeeds    15s    2s    Run Keywords
    ...    Verify Received Journal Entry Count    ${log_dir}    ${marker}-after-reboot
    ...    AND    Verify Received Journal Entry Count    ${log_dir}    ${marker}
    [Teardown]    Run Keyword If Test Failed    Save Journal Forwarding Logs    ${AUDIO_VM}    ${log_dir}

Log sealing works after clock change
    [Documentation]  Verify that log sealing passes before, during, and after VM clock changes
    [Tags]           SP-T377
    ${failures}    Create Dictionary
    Verify Time And Log Sealing In VMs    ${failures}    0    log_sealing_before_clock_change_${BUILD_ID}   @{VM_LIST}
    Change Time And Verify Log Sealing In VMs    ${failures}    1800    log_sealing_after_clock_change_${BUILD_ID}    @{VM_LIST}
    Restore Time And Verify Log Sealing In VMs   ${failures}    log_sealing_after_clock_restore_${BUILD_ID}    @{VM_LIST}
    IF    $failures    FAIL    Log sealing checks failed: ${failures}
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
    [Documentation]    Verify clock offset and log sealing in VMs
    [Arguments]        ${failures}    ${expected_offset_seconds}    ${log}    @{vms}
    FOR    ${vm}    IN    @{vms}
        Switch To Vm    ${vm}
        TRY
            Check System Time Offset    ${expected_offset_seconds}
            Verify Log Sealing In Current VM    ${vm}    ${log}
        EXCEPT    AS    ${error}
            Set To Dictionary    ${failures}    ${vm}=Initial check: ${error}
        END
    END

Change Time And Verify Log Sealing In VMs
    [Documentation]    Change time and verify log sealing in VMs
    [Arguments]        ${failures}    ${offset_seconds}    ${log}    @{vms}
    FOR    ${vm}    IN    @{vms}
        ${service_name}    Set Variable If   '${vm}' == '${NET_VM}'    chronyd.service    systemd-timesyncd.service
        Switch To Vm    ${vm}
        TRY
            Stop Timesync Daemon    ${service_name}
            Set System Time Offset    ${offset_seconds}
            Verify Log Sealing In Current VM    ${vm}    ${log}
        EXCEPT    AS    ${error}
            Set To Dictionary    ${failures}    ${vm}=Clock change: ${error}
        END
    END

Restore Time And Verify Log Sealing In VMs
    [Documentation]    Restore time and verify log sealing in VMs
    [Arguments]        ${failures}    ${log}    @{vms}
    FOR    ${vm}    IN    @{vms}
        ${service_name}    Set Variable If    '${vm}' == '${NET_VM}'    chronyd.service    systemd-timesyncd.service
        Switch To Vm    ${vm}
        TRY
            Restore System Time
            Start Timesync Daemon    ${service_name}
            Wait Until Keyword Succeeds    30s    2s    Check System Time Offset    0
            Verify Log Sealing In Current VM    ${vm}    ${log}
        EXCEPT    AS    ${error}
            Set To Dictionary    ${failures}    ${vm}=Clock restore: ${error}
        END
    END
