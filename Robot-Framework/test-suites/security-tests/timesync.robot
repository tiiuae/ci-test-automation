# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing time synchronization
Test Tags           timesync  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  fmo

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Resource            ../../resources/time_keywords.resource


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
    [Tags]            SP-T97

    Switch to vm   ${HOST}
    Check that time is correct  timezone=UTC

    Stop timesync daemon
    Set RTC time  ${wrong_time}
    ${time_changed}  Run Keyword And Return Status
    ...    Wait Until Keyword Succeeds    5s    1s    Check Time Was Changed    ${wrong_time}
    IF  ${time_changed} != True
        FAIL    Failed to set RTC time
    END
    Start timesync daemon
    Check that time is correct

    [Teardown]  Timesync Teardown

Update system time from internet in VMs
    [Tags]            SP-T217
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
    IF    "${vm}" != "${NET_VM}"
        Restart timesync daemon
    ELSE
        Restart timesync daemon    chronyd.service
    END
    Check time was changed    expected_time=None
    Unblock internet traffic
    Check that time is correct
    [Teardown]  Run Keyword If  "${KEYWORD STATUS}" == 'FAIL'   Run Keyword  Unblock internet traffic

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
