# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing time synchronization
Test Tags           timesync

Library             ../../lib/TimeLibrary.py
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource


*** Variables ***
${wrong_time}       01/11/23 11:00:00 UTC
${original_time}    ${EMPTY}
${error_msg}        Unrecoverable error detected. Please collect any data possible and then kill the guest


*** Test Cases ***

Time synchronization
    [Documentation]   Stop timesyncd, change time on ghaf host and check that time was changed
    ...               Start timesyncd and check that time was synchronized
    ...               Note!
    ...               - ORIN-AGX: 
    ...                  - Ghaf-host is directly connected to net if wire directly connected to the HW.
    ...                      -Net-vm is not connected to net.
    ...                  - Ghaf-host is connected to net via Net-VM if adapter is used!.
    ...                  - In this test we expect adapter to be used.
    [Tags]            SP-T97  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  fmo

    Switch to vm   ${HOST}
    Check that time is correct  timezone=UTC

    Stop timesync daemon
    Set RTC time  ${wrong_time}
    ${time_changed}  Run Keyword And Return Status  Wait Until Keyword Succeeds  5s  1s  Check time was changed
    IF  ${time_changed} != True
        FAIL    Failed to set RTC time
    END
    Start timesync daemon
    Check that time is correct

    [Teardown]  Timesync Teardown

Update system time from internet in VMs
    [Tags]            SP-T217  lenovo-x1  darter-pro  dell-7330
    [Template]        Update system time from internet in ${vm}
    [Setup]           VM Time Update Setup
    FOR    ${vm}    IN    @{VM_LIST}
        ${vm}
    END

*** Keywords ***

VM Time Update Setup
    @{VM_LIST}      Get VM list
    Remove Values From List  ${VM_LIST}   ${ADMIN_VM}
    Set Suite Variable       @{VM_LIST}

Update system time from internet in ${vm}
    [Documentation]   Disable internet, change time in vm, restart timesyncd, check that time was changed to wrong
    ...               Enable internet and check that time was synchronized
    Switch to vm              ${vm}
    Block internet traffic
    Set system time           ${wrong_time}
    Restart timesync daemon
    Check time was changed    expected_time=None
    Unblock internet traffic
    Check that time is correct
    [Teardown]  Run Keyword If  "${KEYWORD STATUS}" == 'FAIL'   Unblock internet traffic


Stop timesync daemon
    Run Command            systemctl stop systemd-timesyncd.service  sudo=True
    Verify service status  service=systemd-timesyncd.service  expected_state=inactive  expected_substate=dead

Start timesync daemon
    Run Command            systemctl start systemd-timesyncd.service  sudo=True
    Verify service status  service=systemd-timesyncd.service  expected_state=active  expected_substate=running
    Run Command            timedatectl -a

Restart timesync daemon
    Run Command            systemctl restart systemd-timesyncd.service  sudo=True
    Verify service status  service=systemd-timesyncd.service  expected_state=active  expected_substate=running
    Run Command            timedatectl -a

Check that time is correct
    [Documentation]   Check that current system time is correct (time tolerance = 30 sec)
    [Arguments]       ${timezone}=UTC

    ${is_synchronized} =   Set Variable    False
    FOR    ${i}    IN RANGE    30
        ${output}      Run Command    timedatectl -a
        ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
        IF    ${is_synchronized}
            BREAK
        END
        Sleep    1
    END
    Log               ${output}
    Run Keyword If    not ${is_synchronized}    FAIL   Time was not synchronized!

    ${current_time}   Get current time   ${timezone}
    Log To Console    Comparing device time: ${universal_time} and real time ${current_time}
    ${time_close}     Is time close      ${universal_time}  ${current_time}  tolerance_seconds=30
    Should Be True    ${time_close}  ${universal_time} expected close to ${current_time}, Time was synchronized: ${is_synchronized}
    Compare local and universal time

Set RTC time
    [Arguments]       ${time}=${wrong_time}
    ${original_time}      Get Time	epoch
    Set Test Variable     ${original_time}  ${original_time}
    Log To Console        Setting time ${time}
    Run Command     hwclock --set --date="${time}"  sudo=True
    Sleep    3
    Run Command     hwclock -s  sudo=True
    Run Command     timedatectl -a

Check time was changed
    [Documentation]   Check that current system time is equal to given time tolerance.
    [Arguments]       ${expected_time}=${wrong_time}  ${timezone}=UTC
    ${output}         Run Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
    ${now}            Get Time  epoch
    ${time_diff}      Evaluate  ${now} - ${original_time}
    IF  '${expected_time}' != 'None'
        ${expected_time}  Convert To UTC  ${expected_time}
        Log               Comparing device time: ${universal_time} and time which was set ${expected_time}    console=True
        ${time_close}     Is time close  ${universal_time}  ${expected_time}  tolerance_seconds=${time_diff}
        Should Be True    ${time_close}   Time was not set, expected close to: ${expected_time}, in fact: ${universal_time}
    ELSE
        ${actual_time}    Get Current Time
        Log               Comparing device time: ${universal_time} and actual time    console=True
        ${time_close}     Is time close  ${universal_time}  ${actual_time}  tolerance_seconds=${time_diff}
        Should Not Be True    ${time_close}    Time was not changed, expected close to: ${actual_time}, in fact: ${universal_time}
    END
    Compare local and universal time

Compare local and universal time
    [Documentation]   Universal time should be UTC,
    ...               Local time should be Asia/Dubai time zone for LenovoX1 and UTC for others
    [Arguments]       ${timezone}=UTC
    ${output}         Run Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}    Parse time info  ${output}
    ${local_time_utc}  Convert To UTC  ${local_time}
    ${time_close}     Is time close  ${universal_time}  ${local_time_utc}  tolerance_seconds=1
    Should Be True    ${time_close}

Set RTC from system clock
    [Documentation]   Set the Hardware Clock from the System Clock
    Run Command       hwclock -w  sudo=True
    Run Command       timedatectl -a

Set system time
    [Arguments]         ${time}=${wrong_time}
    ${original_time}    Get Time	epoch
    Set Test Variable   ${original_time}  ${original_time}
    Run Command         date -s '${time}'  sudo=True
    Run Command         timedatectl -a

Disable Wifi passthrough from NetVM
    Check Network Availability    8.8.8.8   expected_result=True
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=False
    Sleep               1
    Remove Wifi configuration  ${TEST_WIFI_SSID}

Block internet traffic
    Run Command    iptables -I OUTPUT -p udp --dport 123 -j DROP  sudo=True
    Run Command    iptables -I OUTPUT -p tcp -m multiport --dports 80,443 -j DROP  sudo=True
    Run Command    iptables -I OUTPUT -p udp -m multiport --dports 80,443 -j DROP  sudo=True

Unblock internet traffic
    Run Command    iptables -D OUTPUT -p udp --dport 123 -j DROP  sudo=True
    Run Command    iptables -D OUTPUT -p tcp -m multiport --dports 80,443 -j DROP  sudo=True
    Run Command    iptables -D OUTPUT -p udp -m multiport --dports 80,443 -j DROP  sudo=True

Timesync Teardown
     [Timeout]      2 minutes
     Switch to vm   ${HOST}
     Set RTC from system clock
     Start timesync daemon
