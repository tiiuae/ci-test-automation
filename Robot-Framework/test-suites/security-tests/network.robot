# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check network related security
Force Tags          security  network-security
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource


*** Test Cases ***

Account lockout after failed login
    [Documentation]  Try to connect from Comms-vm to Chrome-vm with a wrong password for several times, then check that
    ...              Comms-vm's ip is blacklisted in Chrome-vm and it is not possible to connect even with correct password
    [Tags]           regression  SP-T268  lenovo-x1  darter-pro
    Switch to vm     ${COMMS_VM}
    ${ip}            Get VM IP
    Try to connect with wrong password    ${CHROME_VM}  jumphost=${COMMS-VM_GHAF_SSH}
    Check ip is in the blacklist  ${CHROME_VM}  ${ip}
    [Teardown]       Remove from the blacklist  ${ip}

Kill switch disconnects WLAN
    [Documentation]  Verify that killswitch disconnect wi-fi connection and make interface unavailable
    [Tags]           regression  SP-T304  lenovo-x1  darter-pro
    [Setup]          Kill switch setup
    Verify nmcli device status    ${wifi_if}  connected
    Check Network Availability    8.8.8.8     expected_result=True    limit_freq=${False}    interface=${wifi_if}
    Block WLAN
    Verify nmcli device status    ${wifi_if}  absent
    Check Network Availability    8.8.8.8     expected_result=False   limit_freq=${False}    interface=${wifi_if}
    Check Network Availability    8.8.8.8     expected_result=True    limit_freq=${False}    interface=${eth_if}
    Unblock WLAN
    Verify nmcli device status    ${wifi_if}  connected
    [Teardown]    Run Keywords    Unblock WLAN    AND    Remove Wifi configuration  ${TEST_WIFI_SSID}


*** Keywords ***

Try to connect with wrong password
    [Arguments]   ${vm_name}    ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${jumphost}=None
    ${connection}       Open Connection    ${vm_name}    port=22    prompt=\$    timeout=30
    FOR    ${i}    IN RANGE     5
        TRY
            ${status}  ${login_output}   Run Keyword And Ignore Error  Login with timeout  username=${user}  password=wrong  jumphost=${jumphost}
        EXCEPT    Keyword timeout 30 seconds exceeded.
            BREAK
        END
    END
    TRY
        Run Keyword And Ignore Error  Login with timeout  username=${user}  password=${pw}  jumphost=${jumphost}
    EXCEPT    Keyword timeout 30 seconds exceeded.
        Log   Failed to connect with correct password in 30 seconds.
    END

Check ip is in the blacklist
    [Arguments]     ${vm}  ${ip}
    Switch to vm    ${vm}
    ${output} 	    Execute Command    ipset list f2b-sshBlacklist   sudo=True    sudo_password=${PASSWORD}
    Log             ${output}
    Should contain  ${output}    ${ip}

Remove from the blacklist
    [Arguments]      ${ip}
    Execute Command  ipset del f2b-sshBlacklist ${ip}   sudo=True    sudo_password=${PASSWORD}

Kill switch setup
    Switch to vm       ${NET_VM}
    ${wifi_if}         Get Wifi Interface name
    Set Test Variable  ${wifi_if}
    ${eth_if}          Get Ethernet Interface name
    Set Test Variable  ${eth_if}
    Configure wifi     ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP
