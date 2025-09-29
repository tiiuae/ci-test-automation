# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing time synchronization
Force Tags          timesync

Library             ../../lib/TimeLibrary.py
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
    ...                  - In this test we expect adapter is not used -> Set Wi-Fi ON to enable net-vm to address net.
    [Tags]            bat  regression  SP-T97   nuc  orin-agx  orin-agx-64  orin-nx  riscv  lenovo-x1  darter-pro  dell-7330  fmo

    Switch to vm   ghaf-host
    Check that time is correct  timezone=UTC

    Stop timesync daemon
    Set RTC time  ${wrong_time}
    Check time was changed

    Start timesync daemon
    Check that time is correct

    [Teardown]  Timesync Teardown

Update system time from internet in Gui-vm
    [Tags]            bat  SP-T217  lenovo-x1  darter-pro  dell-7330
    [Template]        Update system time from internet in ${vm}
    ${GUI_VM}

Update system time from internet in VMs
    [Tags]            regression  SP-T217  lenovo-x1  darter-pro  dell-7330
    [Template]        Update system time from internet in ${vm}
    FOR    ${vm}    IN    @{VMS}
        ${vm}
    END

*** Keywords ***

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
    Execute Command        systemctl stop systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=inactive  expected_state=dead

Start timesync daemon
    Execute Command        systemctl start systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=active  expected_state=running
    ${output}              Execute Command    timedatectl -a

Restart timesync daemon
    Execute Command        systemctl restart systemd-timesyncd.service  sudo=True  sudo_password=${PASSWORD}
    Verify service status  service=systemd-timesyncd.service  expected_status=active  expected_state=running
    ${output}              Execute Command    timedatectl -a

Check that time is correct
    [Documentation]   Check that current system time is correct (time tolerance = 30 sec)
    [Arguments]       ${timezone}=UTC

    ${is_synchronized} =   Set Variable    False
    FOR    ${i}    IN RANGE    30
        ${output}      Execute Command    timedatectl -a
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
    Execute Command       hwclock --set --date="${time}"  sudo=True  sudo_password=${PASSWORD}
    Execute Command       hwclock -s  sudo=True  sudo_password=${PASSWORD}
    ${output}             Execute Command  timedatectl -a

Check time was changed
    [Documentation]   Check that current system time is equal to given time tolerance.
    [Arguments]       ${expected_time}=${wrong_time}  ${timezone}=UTC
    ${output}         Execute Command    timedatectl -a
    ${local_time}  ${universal_time}  ${rtc_time}  ${device_time_zone}  ${is_synchronized}   Parse time info  ${output}
    ${now}            Get Time  epoch
    ${time_diff}      Evaluate  ${now} - ${original_time}
    IF  '${expected_time}' != 'None'
        ${expected_time}  Convert To UTC  ${expected_time}
        Log               Comparing device time: ${universal_time} and time which was set ${expected_time}    console=True
        ${time_close}     Is time close  ${universal_time}  ${expected_time}  tolerance_seconds=${time_diff}
        Should Be True    ${time_close}
    ELSE
        ${actual_time}    Get Current Time
        Log               Comparing device time: ${universal_time} and actual time    console=True
        ${time_close}     Is time close  ${universal_time}  ${actual_time}  tolerance_seconds=${time_diff}
        Should Not Be True    ${time_close}
    END
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

Set system time
    [Arguments]         ${time}=${wrong_time}
    ${original_time}    Get Time	epoch
    Set Test Variable   ${original_time}  ${original_time}
    ${output}           Execute Command   sudo date -s '${time}'  sudo=True  sudo_password=${PASSWORD}
    ${output}           Execute Command   timedatectl -a

Disable Wifi passthrough from NetVM
    Check Network Availability    8.8.8.8   expected_result=True
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=False
    Sleep               1
    Remove Wifi configuration  ${TEST_WIFI_SSID}

Block internet traffic
    Execute Command    iptables -I OUTPUT -p udp --dport 123 -j DROP  sudo=True  sudo_password=${PASSWORD}
    Execute Command    iptables -I OUTPUT -p tcp -m multiport --dports 80,443 -j DROP  sudo=True  sudo_password=${PASSWORD}
    Execute Command    iptables -I OUTPUT -p udp -m multiport --dports 80,443 -j DROP  sudo=True  sudo_password=${PASSWORD}

Unblock internet traffic
    Execute Command    iptables -D OUTPUT -p udp --dport 123 -j DROP  sudo=True  sudo_password=${PASSWORD}
    Execute Command    iptables -D OUTPUT -p tcp -m multiport --dports 80,443 -j DROP  sudo=True  sudo_password=${PASSWORD}
    Execute Command    iptables -D OUTPUT -p udp -m multiport --dports 80,443 -j DROP  sudo=True  sudo_password=${PASSWORD}

Timesync Teardown
     Switch to vm   ghaf-host
     Run Keyword If Test Failed  Check If Known Error
     Set RTC from system clock
     Start timesync daemon

Check If Known Error
    IF  "AGX" in "${DEVICE}"
        ${journal_log}    Execute Command  journalctl --since "20 minutes ago"
        Log  ${journal_log}
        ${error_present}  Run Keyword And Return Status  Should Contain  ${journal_log}   ${error_msg}
        IF  ${error_present}   Skip    Known issue: SSRCSP-6423 (AGX)
    END