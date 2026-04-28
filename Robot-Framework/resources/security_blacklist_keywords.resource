# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Shared keywords for external blacklisting checks and recovery
Resource            ../resources/common_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/serial_keywords.resource


*** Keywords ***

Verify NetVM Blacklist Contains IP Via Serial
    [Documentation]    Verify that the provided IP is found from net-vm's ${blacklist} via serial tunnel.
    [Arguments]        ${ip}  ${blacklist}=BLACKLIST
    Log                Checking via serial that ${blacklist} contains the attacker IP    console=True
    ${output}          Run Command on VM Via Serial    ${NET_VM}    echo ${PASSWORD} | sudo -S ipset list ${blacklist}
    Should Contain     ${output}    ${ip}     Blacklist doesn't contain the attacker's IP.

Clear NetVM Blacklist Via Serial
    [Documentation]    Remove the attacker IP from net-vm ${blacklist} using serial access.
    [Arguments]        ${ip}  ${blacklist}=BLACKLIST   ${proto}=ICMP
    Log                Trying to remove the attacker IP from ${blacklist} via serial     console=True
    Run Command on VM Via Serial   ${NET_VM}   echo ${PASSWORD} | sudo -S ipset del ${blacklist} ${ip}
    IF    $proto == 'SSH'
        Unban IP Address Via Serial    ${ip}
    END
    Wait Until Keyword Succeeds    5x    5s    Verify External Connectivity Restored    ${proto}

Unban IP Address Via Serial
    [Arguments]        ${ip}
    Log                Trying to unban the attacker IP via serial     console=True
    Run Command on VM Via Serial   ${NET_VM}   echo ${PASSWORD} | sudo -S fail2ban-client set sshd unbanip ${ip}
    Verify IP Is Not Banned In Fail2ban Jail Via Serial    ${ip}
    Verify External Connectivity Restored    SSH

Verify IP Is Not Banned In Fail2ban Jail Via Serial
    [Documentation]    Verify that the IP is not listed in fail2ban sshd jail banned IP list.
    [Arguments]        ${ip}  ${jail}=sshd
    ${output}          Run Command on VM Via Serial    ${NET_VM}    echo ${PASSWORD} | sudo -S fail2ban-client status ${jail}
    Should Contain     ${output}    Banned IP list:
    Should Not Match Regexp    ${output}    (?m)^\\s*`- Banned IP list:\\s*.*\\b${ip}\\b

Verify External Connectivity Restored
    [Documentation]    Verify that the attacker IP was removed from net-vm ${blacklist} by checking connection.
    ...                Available protocols: ICMP, SSH.
    [Arguments]        ${proto}=ICMP
    Log                Verify that the attacker IP is not blocked anymore     console=True
    IF    $proto == 'ICMP'
        ${output}          Run Process    sh   -c   ping -c 2 ${DEVICE_IP_ADDRESS}   shell=true
        Should Be Equal As Integers       ${output.rc}    0     No connection to ${DEVICE_IP_ADDRESS} with ${proto} protocol
    ELSE IF    $proto == 'SSH'
        Switch to vm    ${NET_VM}
    END

Get External Attacker IP
    [Documentation]    Return source IP that the test agent uses to reach the target device.
    ${output}          Run Process    sh   -c   /run/current-system/sw/bin/ip route get ${DEVICE_IP_ADDRESS}   shell=true
    Should Be Equal As Integers       ${output.rc}    0    Failed to resolve route to ${DEVICE_IP_ADDRESS}
    ${ext_attacker_ip}   Get Source Ip For Route    ${output.stdout}
    RETURN    ${ext_attacker_ip}
