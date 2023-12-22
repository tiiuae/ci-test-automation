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

Time synchronization in virtual machines
    [Documentation]   Stop timesyncd, change time on host, restart VMs and check that time was changed in VMs
    [Tags]            bat   SP-T99-1  lenovo-x1

    ${host}  Connect to ghaf host
    Check that time is correct  UTC
    Stop timesync daemon
    Set time
    Check time was changed
    Connect to netvm

    FOR  ${vm}  IN   ${CHROMIUM_VM_NAME}    #${GUI_VM_NAME}
#    FOR  ${vm}  IN   ${CHROMIUM_VM_NAME}  ${GUI_VM_NAME}  ${ZATHURA_VM_NAME}  ${GALA_VM_NAME}
        Switch Connection    ${host}
        Restart VM  ${vm}
        Connect to VM  ${vm}
        Check time was changed
    END

    Switch Connection    ${host}
    Start timesync daemon
    Check that time is correct  UTC

    FOR  ${vm}  IN   ${CHROMIUM_VM_NAME}  #  ${GUI_VM_NAME}
        Restart VM  ${vm}
    END

    [Teardown]  Run Keywords  Switch Connection  ${host}  AND  Set RTC from system clock  AND  Start timesync daemon


# Test Template    Time syncronization test    $arg1

# Test Case 1    Data1
# Test Case 2    Data3



*** Keywords ***

Time syncronization test
    [Arguments]    ${vm}
    Log    Check Time Syncronization inside VM ${vm}
    # ... your test steps ...

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
    ${output}         Execute Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}    Parse time info  ${output}
    ${current_time}   Get current time   ${timezone}
    ${time_close}     Is time close      ${universal_time}  ${current_time}
    Should Be True    ${time_close}      Time doesn't match: Device time ${universal_time}, actual time ${current_time}
    Compare local and universal time

Set time
    [Arguments]       ${time}=${wrong_time}
    ${change_time}    Get Time	epoch
    ${change_time}    Set Global Variable     ${change_time}
    Execute Command   hwclock --set --date="${time}"  sudo=True  sudo_password=${PASSWORD}
    Execute Command   hwclock -s  sudo=True  sudo_password=${PASSWORD}
    ${output}         Execute Command  timedatectl -a

Check time was changed
    [Documentation]   Check that current system time is equal to given (time tolerance = 10 sec)
    [Arguments]       ${time}=${wrong_time}  ${timezone}=UTC
    ${output}         Execute Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}    Parse time info  ${output}
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
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}    Parse time info  ${output}
    ${local_time_utc}  Convert To UTC  ${local_time}
    ${time_close}     Is time close  ${universal_time}  ${local_time_utc}  tolerance_seconds=1
    Should Be True    ${time_close}

Set RTC from system clock
    [Documentation]   Set the Hardware Clock from the System Clock
    ${output}         Execute Command    hwclock -w  sudo=True  sudo_password=${PASSWORD}
    ${output}         Execute Command    timedatectl -a

#Stop NetVM
#    [Documentation]     Ensure that NetVM is started, stop it and check the status.
#    ...                 Pre-condition: requires active ssh connection to ghaf host.
#    Verify service status   service=${netvm_service}   expected_status=active   expected_state=running
#    Log To Console          Going to stop NetVM
#    Execute Command         systemctl stop ${netvm_service}  sudo=True  sudo_password=${PASSWORD}
#    Sleep    3
#    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=inactive  expected_state=dead
#    Verify service shutdown status   service=${netvm_service}
#    Set Global Variable     ${netvm_state}   ${state}
#    Log To Console          NetVM is ${state}
#
#Start NetVM
#    [Documentation]     Try to start NetVM service
#    ...                 Pre-condition: requires active ssh connection to ghaf host.
#    Log To Console          Going to start NetVM
#    Execute Command         systemctl start ${netvm_service}  sudo=True  sudo_password=${PASSWORD}
#    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running
#    Set Global Variable     ${netvm_state}   ${state}
#    Log To Console          NetVM is ${state}
#    Wait until NetVM service started
#
#Restart NetVM
#    [Documentation]    Stop NetVM via systemctl, wait ${delay} and start NetVM
#    ...                Pre-condition: requires active ssh connection to ghaf host.
#    [Arguments]        ${delay}=3
#    Stop NetVM
#    Sleep  ${delay}
#    Start NetVM
#    Check if ssh is ready on netvm
