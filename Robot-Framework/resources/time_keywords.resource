# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             DateTime
Library             ../lib/TimeLibrary.py
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

Restart Timesync Daemon
    [Arguments]            ${service_name}=systemd-timesyncd.service
    Run Command            systemctl restart ${service_name}    sudo=True
    Verify Service Status  service=${service_name}    expected_state=active    expected_substate=running
    Run Command            timedatectl -a

Check That Time Is Correct
    [Documentation]    Check that current system time is correct (time tolerance = 30 sec)
    [Arguments]        ${timezone}=UTC
    ${is_synchronized}    Set Variable    ${False}
    FOR    ${i}    IN RANGE    30
        ${output}    Run Command    timedatectl -a
        ${local_time}    ${universal_time}    ${rtc_time}    ${device_time_zone}    ${is_synchronized}
        ...    Parse Time Info    ${output}
        IF    ${is_synchronized}
            BREAK
        END
        Sleep    1
    END
    Log    ${output}
    IF    not ${is_synchronized}
        FAIL    Time was not synchronized!
    END

    ${current_time}    Get Current Time    ${timezone}
    Log To Console    Comparing device time: ${universal_time} and real time ${current_time}
    ${time_close}    Is Time Close    ${universal_time}    ${current_time}    tolerance_seconds=30
    Should Be True    ${time_close}
    ...    ${universal_time} expected close to ${current_time}, Time was synchronized: ${is_synchronized}
    Compare Local And Universal Time

Set RTC Time
    [Arguments]         ${time}
    ${original_time}    Get Time    epoch
    Set Test Variable   ${original_time}    ${original_time}
    Log To Console      Setting time ${time}
    Run Command         hwclock --set --date="${time}" --verbose    sudo=True
    Sleep               3
    # Workaround for SSRCSP-8622
    ${extra_flag}       Set Variable If
    ...                 "${DEVICE_TYPE}" == "lenovo-x1" or "${DEVICE_TYPE}" == "x1-sec-boot"
    ...                 -f /dev/rtc1
    ...                 ${EMPTY}
    Run Command         hwclock -s --verbose ${extra_flag}    sudo=True
    Run Command         timedatectl -a

Check Time Was Changed
    [Documentation]    Check that current system time is equal to given time tolerance.
    [Arguments]        ${expected_time}    ${timezone}=UTC
    ${output}          Run Command    timedatectl -a
    ${local_time}    ${universal_time}    ${rtc_time}    ${device_time_zone}    ${is_synchronized}
    ...    Parse Time Info    ${output}
    ${now}             Get Time    epoch
    ${time_diff}       Evaluate    ${now} - ${original_time}
    IF    '${expected_time}' != 'None'
        ${expected_time}    Convert To UTC    ${expected_time}
        Log    Comparing device time: ${universal_time} and time which was set ${expected_time}    console=True
        ${time_close}    Is Time Close    ${universal_time}    ${expected_time}    tolerance_seconds=${time_diff}
        Should Be True    ${time_close}
        ...    Time was not set, expected close to: ${expected_time}, in fact: ${universal_time}
    ELSE
        ${actual_time}    Get Current Time
        Log    Comparing device time: ${universal_time} and actual time    console=True
        ${time_close}    Is Time Close    ${universal_time}    ${actual_time}    tolerance_seconds=${time_diff}
        Should Not Be True    ${time_close}
        ...    Time was not changed, expected close to: ${actual_time}, in fact: ${universal_time}
    END
    Compare Local And Universal Time

Compare Local And Universal Time
    [Documentation]    Universal time should be UTC,
    ...                Local time should be Asia/Dubai time zone for LenovoX1 and UTC for others
    [Arguments]        ${timezone}=UTC
    ${output}          Run Command    timedatectl -a
    ${local_time}    ${universal_time}    ${rtc_time}    ${device_time_zone}    ${is_synchronized}
    ...    Parse Time Info    ${output}
    ${local_time_utc}  Convert To UTC    ${local_time}
    ${time_close}      Is Time Close    ${universal_time}    ${local_time_utc}    tolerance_seconds=1
    Should Be True     ${time_close}

Set RTC From System Clock
    [Documentation]    Set the Hardware Clock from the System Clock
    Run Command        hwclock -w --verbose    sudo=True
    Run Command        timedatectl -a

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
    Set System Time     @${restore_epoch}    rc_match=skip

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
