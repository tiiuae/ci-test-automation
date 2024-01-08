# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing time synchronization
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Library             ../../lib/TimeLibrary.py
Suite Teardown      Close All Connections


*** Variables ***
${wrong_time}       01/11/23 11:00:00 UTC
${change_time}      ${EMPTY}


*** Test Cases ***

Time synchronization
    [Documentation]   Stop timesyncd, change time on ghaf host and check that time was changed
    ...               Start timesyncd and check that time was synchronized
    [Tags]            bat   SP-T99   SP-T103  nuc  orin-agx  orin-nx  riscv  lenovo-x1

    ${host}  Connect
    Check that time is correct  timezone=UTC

    Stop timesync daemon
    Set time  ${wrong_time}
    Check time was changed

    Start timesync daemon
    Check that time is correct

    [Teardown]        Run Keywords
    ...               Connect  AND  Set RTC from system clock  AND  Start timesync daemon

Time synchronization in NetVM
    [Documentation]   Stop timesyncd, change time on host, restart VMs and check that time was changed in NetVM
    [Tags]            bat   SP-T99-1  nuc  orin-agx  orin-nx  riscv  lenovo-x1

    ${host}  Connect to ghaf host

    ${netvm}  Connect to netvm
    Check that time is correct  UTC
    Switch Connection  ${host}

    Check that time is correct  UTC
    Stop timesync daemon
    Set time
    Check time was changed

    ${netvm}  Connect to netvm
    Check time was changed

    Switch Connection    ${host}
    Start timesync daemon
    Check that time is correct  UTC

    Switch Connection    ${netvm}
    Check that time is correct  UTC

    [Teardown]  Run Keywords  Switch Connection  ${host}  AND  Set RTC from system clock  AND  Start timesync daemon

Time synchronization in virtual machines
    [Documentation]   Stop timesyncd, change time on host, restart VMs and check that time was changed in VMs
    [Tags]            bat   SP-T99-2  lenovo-x1

    ${host}  Connect to ghaf host
    Check that time is correct  UTC
    Stop timesync daemon
    Set time
    Check time was changed
    Connect to netvm

    FOR  ${vm}  IN   ${CHROMIUM_VM_NAME}  ${GUI_VM_NAME}  ${ZATHURA_VM_NAME}  ${GALA_VM_NAME}
        Connect to VM  ${vm}
        Check time was changed
    END

    Switch Connection    ${host}
    Start timesync daemon
    Check that time is correct  UTC

    FOR  ${vm}  IN   ${CHROMIUM_VM_NAME}  ${GUI_VM_NAME}  ${ZATHURA_VM_NAME}  ${GALA_VM_NAME}
        Connect to VM  ${vm}
        Check that time is correct  UTC
    END

    [Teardown]  Run Keywords  Switch Connection  ${host}  AND  Set RTC from system clock  AND  Start timesync daemon


*** Keywords ***

Stop timesync daemon
    Execute Command        systemctl stop systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=inactive  expected_state=dead

Start timesync daemon
    Execute Command        systemctl start systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=active  expected_state=running
    ${output}              Execute Command    timedatectl -a

Check that time is correct
    [Documentation]   Check that current system time is correct (time tolerance = 10 sec)
    [Arguments]       ${timezone}=UTC

    ${is_started} =   Set Variable    False
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
    ${time_close}     Is time close      ${universal_time}  ${current_time}
    Should Be True    ${time_close}
    ...  Time doesn't match: Device time ${universal_time}, actual time ${current_time}, Time was synchronized: ${is_synchronized}
    Compare local and universal time

Set time
    [Arguments]       ${time}=${wrong_time}
    ${change_time}    Get Time	epoch
    ${change_time}    Set Global Variable     ${change_time}
    Log To Console    Setting time ${time}
    Execute Command   hwclock --set --date="${time}"  sudo=True  sudo_password=${PASSWORD}
    Execute Command   hwclock -s  sudo=True  sudo_password=${PASSWORD}
    ${output}         Execute Command  timedatectl -a

Check time was changed
    [Documentation]   Check that current system time is equal to given (time tolerance = 10 sec)
    [Arguments]       ${time}=${wrong_time}  ${timezone}=UTC
    ${output}         Execute Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
    ${now}            Get Time  epoch
    ${time_diff}      Evaluate  ${now} - ${change_time}
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
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
    ${local_time_utc}  Convert To UTC  ${local_time}
    ${time_close}     Is time close  ${universal_time}  ${local_time_utc}  tolerance_seconds=1
    Should Be True    ${time_close}

Set RTC from system clock
    [Documentation]   Set the Hardware Clock from the System Clock
    ${output}         Execute Command    hwclock -w  sudo=True  sudo_password=${PASSWORD}
    ${output}         Execute Command    timedatectl -a
