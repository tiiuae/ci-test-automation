# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Checking VM's firewall
Test Tags           firewall
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/serial_keywords.resource
Library             OperatingSystem

Suite Setup         Suite Setup


*** Variables ***
${port}             5432


*** Test Cases ***

Network traffic passes through all VMs' firewall
    [Tags]            SP-T288  lenovo-x1  darter-pro  dell-7330
    [Template]        Network traffic passes through ${vm} firewall
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        IF  '${vm}' != '${GUI_VM}'
            ${vm}
        END
    END

Check that internal ping flooding triggers blacklisting
    [Tags]            SP-T299  SP-T299-1  lenovo-x1  darter-pro  dell-7330
    [Template]        Ping Flood Test ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        IF  '${vm}' != '${ZATHURA_VM}' and '${vm}' != '${NET_VM}'
            ${vm}
        END
    END
    [Teardown]      Run Keyword If Test Failed    Blacklist Teardown

Check that internal tcp syn flooding triggers blacklisting
    [Tags]            SP-T299  SP-T299-2  lenovo-x1  darter-pro  dell-7330
    [Template]        Tcp Syn Flood Test ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        IF  '${vm}' != '${ZATHURA_VM}' and '${vm}' != '${NET_VM}'
            ${vm}
        END
    END
    [Teardown]      Run Keyword If Test Failed    Blacklist Teardown

Check that external ping flooding triggers blacklisting
    [Tags]            SP-T299  SP-T299-3  darter-pro  orin-agx  orin-nx  lab-only
    [Documentation]   Validate that ping flooding from the test agent to net-vm triggers firewall blacklisting.
    ${ext_attacker_ip}    Get External Attacker IP
    External Ping Flood NetVM
    Verify NetVM Blacklist Contains IP Via Serial    ${ext_attacker_ip}
    Clear NetVM Blacklist Via Serial    ${ext_attacker_ip}
    [Teardown]      Run Keyword If Test Failed    Blacklist Teardown

Check that external tcp syn flooding triggers blacklisting
    [Tags]            SP-T299  SP-T299-4  darter-pro  orin-agx  orin-nx  lab-only
    [Documentation]   Validate that tcp syn probing from the test agent to net-vm triggers firewall blacklisting.
    ${ext_attacker_ip}    Get External Attacker IP
    External Tcp Syn Flood NetVM
    Verify NetVM Blacklist Contains IP Via Serial    ${ext_attacker_ip}
    Clear NetVM Blacklist Via Serial    ${ext_attacker_ip}
    [Teardown]      Run Keyword If Test Failed    Blacklist Teardown


*** Keywords ***

Network traffic passes through ${vm} firewall
    [Documentation]    Network traffic passes through VM firewall
    Log    | | Check that traffic passes through ${vm} firewall    console=True
    Switch to vm       ${vm}
    Create firewall logging rules
    IF  '${vm}' == '${HOST}'
        ${vm-ip}           Get VM IP  virbr0
    ELSE
        ${vm-ip}           Get VM IP
    END

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
    IF  $IS_LAPTOP == 'True'
        @{VM_LIST_WITH_HOST}  Get VM list    with_host=True
        Set Suite Variable    @{VM_LIST_WITH_HOST}
        Switch to vm          ${ZATHURA_VM}
        ${output}             Run Command    ifconfig
        ${attacker_ip}        Get ip from ifconfig    ${output}   eth
        Set Suite Variable    ${attacker_ip}
    END

Create firewall logging rules
    Run Command  iptables -t filter -I nixos-fw-log-refuse -j LOG --log-prefix "Packet passed through firewall: "  sudo=True
    Run Command  iptables -t filter -I INPUT -p tcp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True
    Run Command  iptables -t filter -I INPUT -p udp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True

Remove rules
    Run Command  iptables -t filter -D nixos-fw-log-refuse -j LOG --log-prefix "Packet passed through firewall: "  sudo=True
    Run Command  iptables -t filter -D INPUT -p tcp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True
    Run Command  iptables -t filter -D INPUT -p udp --dport ${port} -j LOG --log-prefix "Packet arrived: "  sudo=True

Send connection request to closed port
    [Arguments]        ${ip}    ${port}
    Log                Sending tcp and udp traffic to ip ${ip}, port ${port}     console=True
    ${timestamp_tcp}   Run Command    date +%s
    Set Test Variable  ${time_tcp}  ${timestamp_tcp}
    Run Command        nc -v -w1 ${ip} ${port}   rc_match=skip
    Sleep              1
    ${timestamp_udp}   Run Command    date +%s
    Set Test Variable  ${time_udp}  ${timestamp_udp}
    Run Command        printf 'ping' | nc -u -w1 -N ${ip} ${port}
    Sleep              1
    ${timestamp_end}   Run Command    date +%s
    Set Test Variable  ${time_end}  ${timestamp_end}

Check that packet arrived
    [Arguments]        ${since}    ${until}    ${port}    ${protocol}
    ${output}          Run Command    journalctl -k --since @${since} --until @${until} | grep 'kernel: Packet arrived'
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
    ${output}          Run Command    journalctl -k --since @${since} --until @${until} | grep 'kernel: Packet passed through firewal'
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
    ${output}          Run Command    journalctl -k --since @${since} --until @${until} | grep 'refused connection:'
    ${status1}         Run Keyword And Return Status   Should contain    ${output}    DPT=${port}
    ${status2}         Run Keyword And Return Status   Should contain    ${output}    PROTO=TCP
    IF    ${status1} and ${status2}
        Log    TCP connection is refused for DPT=${port}     console=True
    ELSE
        Log    There is no message that TCP connection is refused for DPT=${port}     console=True
        Run Keyword And Continue On Failure    FAIL    There is no message that TCP connection is refused for DPT=${port}
    END

Log journalctl
    Run Command    journalctl -k --since @${time_tcp} --until @${time_end}

Ping Flood Test ${vm}
    Log                Ping flood test targeting ${vm}     console=True
    Switch to vm       ${ZATHURA_VM}
    Run Command        ping -i 0.1 -c 20 ${vm}    sudo=True
    Check And Clear Blacklist   ${vm}

Tcp Syn Flood Test ${vm}
    Log                   hping test targeting ${vm}     console=True
    Switch to vm          ${ZATHURA_VM}
    Elevate to superuser
    Run Nix Shell         hping
    Write                 hping3 -S -p 22 -i u10000 -c 20 ${vm}
    SSHLibrary.Read Until    [nix-shell:
    Check And Clear Blacklist   ${vm}

Check Attacker IP on Blacklist
    [Arguments]        ${vm}    ${expect_blacklisting}=${True}
    Switch to vm       ${vm}
    ${output}          Run Command        ipset list BLACKLIST   sudo=True
    ${status}          Run Keyword And Return Status   Should Contain   ${output}   ${attacker_ip}
    IF  not ${status} and ${expect_blacklisting}
        FAIL    IP blacklisting was not triggered in ${vm}
    ELSE IF  ${expect_blacklisting}
        Log     Blacklisting triggered succesfully in ${vm}    console=True
    END
    IF  ${status} and not ${expect_blacklisting}
        FAIL    Clearing attacker IP address from blacklist of ${vm} failed
    ELSE IF  not ${expect_blacklisting}
        Log     Clearing attacker IP address from blacklist of ${vm} succeeded    console=True
    END

Check And Clear Blacklist
    [Arguments]        ${vm}
    Switch to vm       ${vm}
    Check Attacker IP on Blacklist  ${vm}
    Run Command        ipset del BLACKLIST ${attacker_ip}    sudo=True
    Check Attacker IP on Blacklist  ${vm}   expect_blacklisting=${False}

Verify NetVM Blacklist Contains IP Via Serial
    [Arguments]        ${ip}
    [Documentation]    Verify that the provided IP is found from net-vm's BLACKLIST via serial tunnel.
    ${output}=         Run Command on VM Via Serial    ${NET_VM}    echo ${PASSWORD} | sudo -S ipset list BLACKLIST
    Should Contain     ${output}    ${ip}

Clear NetVM Blacklist Via Serial
    [Arguments]        ${ip}
    [Documentation]    Remove the attacker IP from net-vm BLACKLIST using serial access.
    Run Command on VM Via Serial    ${NET_VM}    echo ${PASSWORD} | sudo -S ipset del BLACKLIST ${ip}
    Wait Until Keyword Succeeds    5x    5s    Verify External Connectivity Restored    ${ip}

Verify External Connectivity Restored
    [Arguments]    ${ip}
    ${output}    Run Process    sh   -c   ping -c 2 ${DEVICE_IP_ADDRESS}   shell=true
    Should Be Equal As Integers    ${output.rc}    0     Ping to ${DEVICE_IP_ADDRESS} failed

Get External Attacker IP
    [Documentation]    Return source IP that the test agent uses to reach the target device.
    ${output}    Run Process    sh   -c   /run/current-system/sw/bin/ip route get ${DEVICE_IP_ADDRESS}   shell=true
    Should Be Equal As Integers    ${output.rc}    0    Failed to resolve route to ${DEVICE_IP_ADDRESS}
    ${ext_attacker_ip}   Get Source Ip For Route    ${output.stdout}
    RETURN    ${ext_attacker_ip}

External Ping Flood NetVM
    [Documentation]    Trigger ICMP flood from the agent towards net-vm interface.
    ${first_burst}    Run Process    sh   -c   ping -i 0.1 -c 20 ${DEVICE_IP_ADDRESS}   shell=true
    Log               ${first_burst.stdout}
    Should Be Equal As Integers    ${first_burst.rc}    0     hping command failed
    Should Contain    ${first_burst.stdout}    bytes from
    ${second_burst}   Run Process    sh   -c   ping -i 0.1 -c 20 ${DEVICE_IP_ADDRESS}   shell=true
    Log               ${second_burst.stdout}
    Should Contain    ${second_burst.stdout}    0 received
    Log To Console    Blacklisting triggered successfully by ping flooding

External Tcp Syn Flood NetVM
    [Documentation]    Trigger TCP SYN probing from the agent towards net-vm interface.
    ${flood_cmd}       Set Variable    rc=1; for i in $(seq 1 20); do timeout 1s nc -z -w 1 "${DEVICE_IP_ADDRESS}" 22 >/dev/null 2>&1 && rc=0; sleep 0.1; done; exit $rc
    ${rc}   ${output}  Run And Return Rc And Output    ${flood_cmd}
    Should Be Equal As Integers    ${rc}    0
    ${rc}   ${output}  Run And Return Rc And Output    ${flood_cmd}
    Should Be Equal As Integers    ${rc}    1
    Log To Console    Blacklisting triggered successfully by tcp syn flooding

Blacklist Teardown
    IF  $IS_LAPTOP == 'True'
        Reboot Laptop
    ELSE
        Reboot Orin
    END
    Close All Connections
    Connect After Reboot
    Run Keyword If    $IS_LAPTOP == 'True'    Login to laptop
