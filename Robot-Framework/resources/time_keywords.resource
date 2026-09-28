# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             DateTime
Resource            common_keywords.resource
Resource            ssh_keywords.resource
Resource            service_keywords.resource


*** Keywords ***

Stop Timesync Daemon
    [Arguments]            ${service_name}=systemd-timesyncd.service
    Run Command            systemctl stop ${service_name}    sudo=True
    Verify Service Status  service=${service_name}    expected_state=inactive    expected_substate=dead

Start Timesync Daemon
    [Arguments]            ${service_name}=systemd-timesyncd.service
    Run Command            systemctl start ${service_name}    sudo=True
    Verify Service Status  service=${service_name}    expected_state=active    expected_substate=running
    Run Command            timedatectl -a

Set System Time
    [Arguments]         ${time}    ${rc_match}=equal
    ${original_time}    Get Time    epoch
    Set Test Variable   ${original_time}    ${original_time}
    Run Command         date -s '${time}'    sudo=True    rc_match=${rc_match}
    Run Command         timedatectl -a    rc_match=${rc_match}

Set System Time Offset
    [Arguments]         ${offset_seconds}
    ${current_epoch}    Get Time    epoch
    ${target_epoch}     Evaluate    int(${current_epoch}) + int(${offset_seconds})
    Set System Time     @${target_epoch}
    Check System Time Offset    ${offset_seconds}

Restore System Time
    ${restore_epoch}    Get Time    epoch
    Set System Time     @${restore_epoch}

Restore System Time In VMs
    [Arguments]         @{vms}
    FOR    ${vm}    IN    @{vms}
        TRY
            Switch To Vm    ${vm}
            ${service_name}    Set Variable If
            ...    '${vm}' == '${NET_VM}'    chronyd.service    systemd-timesyncd.service
            Restore System Time
            Run Command    systemctl start ${service_name}    sudo=True    rc_match=skip
        EXCEPT    AS    ${error}
            Log    Failed to restore time in ${vm}: ${error}    console=True
        END
    END

Check System Time Offset
    [Documentation]     Check the current VM clock against the test controller clock
    [Arguments]         ${expected_offset_seconds}    ${tolerance_seconds}=30
    ${remote_epoch}     Run Command    date +%s
    ${controller_epoch}  Get Time    epoch
    ${actual_offset}    Evaluate    int(${remote_epoch}) - int(${controller_epoch})
    ${offset_delta}     Evaluate    abs(int(${actual_offset}) - int(${expected_offset_seconds}))
    Should Be True      ${offset_delta} <= ${tolerance_seconds}
    ...                 Clock offset ${actual_offset}s, expected ${expected_offset_seconds}s (+/-${tolerance_seconds}s)
    RETURN              ${actual_offset}
