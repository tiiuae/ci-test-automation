# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check network related security
Test Tags           network-security
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/security_blacklist_keywords.resource


*** Test Cases ***

Account lockout after failed login
    [Documentation]  Try to connect from the external test agent to the device with a wrong password for several times, then check that
    ...              test agent's ip is blacklisted in net-vm and it is not possible to connect even with correct password.
    ...              Remove IP from blacklist via serial and verify SSH connectivity is restored.
    [Tags]           SP-T268
    ${ip}            Get External Attacker IP
    Try External Login With Wrong Password
    Verify NetVM Blacklist Contains IP Via Serial    ${ip}   f2b-sshBlacklist
    Unban IP Address Via Serial                      ${ip}
    [Teardown]       Account lockout teardown

Check OpenSSL3 is Available In Nix Store
    [Documentation]  Connect to GUI-VM and check that OpenSSL3 is available in NixStore.
    [Tags]           SP-T295  lenovo-x1  darter-pro   dell-7330
    Switch to vm     ${GUI_VM}
    ${output}        Run Command    ls /nix/store | grep openssl-3    rc_match=skip
    Should Not Be Empty    ${output}    msg=Found no openssl in Nix Store

*** Keywords ***

Try External Login With Wrong Password
    [Arguments]     ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${timeout}=10
    ${connection}   Open Connection    ${DEVICE_IP_ADDRESS}    port=22    prompt=\$    timeout=${timeout}
    FOR    ${i}    IN RANGE     5
        TRY
            Log To Console    Trying to log in with the wrong password
            ${status}  ${login_output}   Run Keyword And Ignore Error  Login with timeout  expected_output=${NET_VM}  username=${user}  password=wrong  timeout=${timeout}
        EXCEPT    Keyword timeout ${timeout} seconds exceeded.
            BREAK
        END
    END
    TRY
        Log To Console    Trying to log in with the correct password
        Run Keyword And Ignore Error  Login with timeout  expected_output=${NET_VM}  username=${user}  password=${pw}  timeout=${timeout}
    EXCEPT    Keyword timeout ${timeout} seconds exceeded.
        Log   Failed to connect with correct password in ${timeout} seconds.    console=True
    END
    Close Connection

Account lockout teardown
    ${status}      Verify External Connectivity Restored    SSH
    IF    '${status}' == 'FAIL'
        Reboot Laptop
        Close All Connections
        Connect After Reboot
        Login to laptop
    END
