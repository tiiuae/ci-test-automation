# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing time synchronization
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Library             ../../lib/TimeLibrary.py
Suite Teardown      Close All Connections


*** Variables ***
${wrong_time}       01/11/23 11:00:00 UTC
${original_time}    ${EMPTY}


*** Test Cases ***

Time synchronization
    [Documentation]   Stop timesyncd, change time on ghaf host and check that time was changed
    ...               Start timesyncd and check that time was synchronized
    [Tags]            bat   SP-T97   nuc  orin-agx  orin-nx  riscv  lenovo-x1

    ${host}  Connect
    Check that time is correct  timezone=UTC

    Stop timesync daemon
    Set time  ${wrong_time}
    Check time was changed

    Start timesync daemon
    Check that time is correct

    [Teardown]        Run Keywords
    ...               Connect  AND  Set RTC from system clock  AND  Start timesync daemon


*** Keywords ***

Stop timesync daemon
    Execute Command        systemctl stop systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=inactive  expected_state=dead

Start timesync daemon
    Execute Command        systemctl start systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=active  expected_state=running
    ${output}              Execute Command    timedatectl -a

Check that time is correct
    [Documentation]   Check that current system time is correct (time tolerance = 30 sec)
    [Arguments]       ${timezone}=UTC

    ${is_synchronized} =   Set Variable    False
    FOR    ${i}    IN RANGE    3
        ${output}      Execute Command    timedatectl -a
        ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
        IF    ${is_synchronized}
            BREAK
        END
        Sleep    1
    END

    ${current_time}   Get current time   ${timezone}
    Log To Console    Comparing device time: ${universal_time} and real time ${current_time}
    ${time_close}     Is time close      ${universal_time}  ${current_time}  tolerance_seconds=30
    Should Be True    ${time_close}  ${universal_time} expected close to ${current_time}, Time was synchronized: ${is_synchronized}
    Compare local and universal time

Set time
    [Arguments]       ${time}=${wrong_time}
    ${original_time}      Get Time	epoch
    Set Test Variable     ${original_time}  ${original_time}
    Log To Console        Setting time ${time}
    Execute Command       hwclock --set --date="${time}"  sudo=True  sudo_password=${PASSWORD}
    Execute Command       hwclock -s  sudo=True  sudo_password=${PASSWORD}
    ${output}             Execute Command  timedatectl -a

Check time was changed
    [Documentation]   Check that current system time is equal to given time tolerance.
    [Arguments]       ${time}=${wrong_time}  ${timezone}=UTC
    ${output}         Execute Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
    ${now}            Get Time  epoch
    ${time_diff}      Evaluate  ${now} - ${original_time}
    ${expected_time}  Convert To UTC  ${time}
    Log To Console    Comparing device time: ${universal_time} and time which was set ${expected_time}
    ${time_close}     Is time close  ${universal_time}  ${expected_time}  tolerance_seconds=${time_diff}
    Should Be True    ${time_close}
    Compare local and universal time

Compare local and universal time
    [Documentation]   Universal time should be UTC,
    ...               Local time should be Asia/Dubai time zone for LenovoX1 and UTC for others
    [Arguments]       ${timezone}=UTC
    ${output}         Execute Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}    Parse time info  ${output}
    ${local_time_utc}  Convert To UTC  ${local_time}
    ${time_close}     Is time close  ${universal_time}  ${local_time_utc}  tolerance_seconds=1
    Should Be True    ${time_close}

Set RTC from system clock
    [Documentation]   Set the Hardware Clock from the System Clock
    ${output}         Execute Command    hwclock -w  sudo=True  sudo_password=${PASSWORD}
    ${output}         Execute Command    timedatectl -a
