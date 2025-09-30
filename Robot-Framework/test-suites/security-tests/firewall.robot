# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Checking VM's firewall
Force Tags          security  firewall
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Suite Setup


*** Variables ***
${port}             5432


*** Test Cases ***

Network traffic passes through all VMs' firewall
    [Tags]            regression  SP-T288  lenovo-x1  darter-pro  dell-7330
    [Template]        Network traffic passes through ${vm} firewall
    FOR    ${vm}    IN    @{VM_LIST}
        IF  '${vm}' != '${GUI_VM}'
            ${vm}
        END
    END


*** Keywords ***

Network traffic passes through ${vm} firewall
    [Documentation]    Network traffic passes through VM firewall
    Log    | | Check that traffic passes through ${vm} firewall    console=True
    Switch to vm       ${vm}
    Create firewall logging rules
    ${vm-ip}           Get VM IP

    Switch to vm       ${GUI_VM}
    Send connection request to closed port    ${vm-ip}    ${port}

    Switch to vm       ${vm}
    Check that packet arrived    ${time_tcp}    ${time_udp}    ${port}    TCP
    Check that packet refused    ${time_tcp}    ${time_udp}    ${port}    TCP
    Check that TCP connection refused    ${time_tcp}    ${time_udp}    ${port}
    Check that packet arrived    ${time_udp}    ${time_end}    ${port}    UDP
    Check that packet refused    ${time_udp}    ${time_end}    ${port}    UDP

    [Teardown]         Run Keywords
    ...                Log journalctl    AND
    ...                Remove rules

Suite Setup
    Switch to vm    ${HOST}
    ${output}       Execute Command    microvm -l
    @{VM_LIST}      Extract VM names   ${output}
    Should Not Be Empty     ${VM_LIST}   VM list is empty
    Set Suite Variable      @{VM_LIST}

Create firewall logging rules
    Execute Command  iptables -t filter -I nixos-fw-log-refuse -j LOG --log-prefix "Packet passed through firewall: "  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -t filter -I INPUT -p tcp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -t filter -I INPUT -p udp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True  sudo_password=${PASSWORD}

Remove rules
    Execute Command  iptables -t filter -D nixos-fw-log-refuse -j LOG --log-prefix "Packet passed through firewall: "  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -t filter -D INPUT -p tcp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -t filter -D INPUT -p udp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True  sudo_password=${PASSWORD}

Get VM IP
    ${output}     Execute Command    ifconfig
    ${ip}         Get ip from ifconfig    ${output}   eth
    RETURN        ${ip}

Send connection request to closed port
    [Arguments]        ${ip}    ${port}
    Log                Sending tcp and udp traffic to ip ${ip}, port ${port}     console=True
    ${timestamp_tcp}   Execute Command    date +%s
    Set Test Variable  ${time_tcp}  ${timestamp_tcp}
    ${output}          Execute Command    nc -v -w1 ${ip} ${port}       return_rc=True
    Sleep              1
    ${timestamp_udp}   Execute Command    date +%s
    Set Test Variable  ${time_udp}  ${timestamp_udp}
    ${output}          Execute Command    printf 'ping' | nc -u -w1 -N ${ip} ${port}    return_rc=True
    Sleep              1
    ${timestamp_end}   Execute Command    date +%s
    Set Test Variable  ${time_end}  ${timestamp_end}

Check that packet arrived
    [Arguments]        ${since}    ${until}    ${port}    ${protocol}
    ${output}          Execute Command    journalctl -k --since @${since} --until @${until} | grep 'kernel: Packet arrived'
    ${status1}         Run Keyword And Return Status   Should contain    ${output}    DPT=${port}
    ${status2}         Run Keyword And Return Status   Should contain    ${output}    ${protocol}
    IF    ${status1} and ${status2}
        Log    ${protocol} Packet arrived for DPT=${port}     console=True
    ELSE
        Log    Packet arrived for DPT=${port}: ${status1}, ${protocol} packet arrived: ${status2}     console=True
        Run Keyword And Continue On Failure    FAIL   Didn't find needed messages in log
    END

Check that packet refused
    [Arguments]        ${since}    ${until}    ${port}    ${protocol}
    ${output}          Execute Command    journalctl -k --since @${since} --until @${until} | grep 'kernel: Packet passed through firewal'
    ${status1}         Run Keyword And Return Status   Should contain    ${output}    DPT=${port}
    ${status2}         Run Keyword And Return Status   Should contain    ${output}    ${protocol}
    IF    ${status1} and ${status2}
        Log    ${protocol} Packet passed through firewall for DPT=${port}     console=True
    ELSE
        Log    Packet passed through firewall for DPT=${port}: ${status1}, ${protocol} packet arrived: ${status2}     console=True
        Run Keyword And Continue On Failure    FAIL    Didn't find needed messages in log
    END

Check that TCP connection refused
    [Arguments]        ${since}    ${until}    ${port}
    ${output}          Execute Command    journalctl -k --since @${since} --until @${until} | grep 'refused connection:'
    ${status1}         Run Keyword And Return Status   Should contain    ${output}    DPT=${port}
    ${status2}         Run Keyword And Return Status   Should contain    ${output}    PROTO=TCP
    IF    ${status1} and ${status2}
        Log    TCP connection is refused for DPT=${port}     console=True
    ELSE
        Log    There is no message that TCP connection is refused for DPT=${port}     console=True
        Run Keyword And Continue On Failure    FAIL    There is no message that TCP connection is refused for DPT=${port}
    END

Log journalctl
    ${output}    Execute Command    journalctl -k --since @${time_tcp} --until @${time_end}
    Log          ${output}
