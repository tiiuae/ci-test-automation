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

*** Variables ***
${FAILED_SSH_LOGIN_ATTACK_COUNT}    12


*** Test Cases ***

Account lockout after failed SSH login
    [Documentation]  Try to connect from the external test agent to the device with a wrong password for several times, then check that
    ...              it is not possible to connect even with correct password.
    ...              Wait for the lockout window to pass and verify SSH connectivity is restored.
    [Tags]           SP-T268  lenovo-x1  darter-pro  lab-only
    Close All Connections
    ${blacklisted_at}    Set Variable    ${None}
    Try External Login With Wrong Password
    ${blacklisted_at}    Get Time    epoch
    [Teardown]       Account lockout teardown    ${blacklisted_at}

Check OpenSSL3 is Available In Nix Store
    [Documentation]  Connect to GUI-VM and check that OpenSSL3 is available in NixStore.
    [Tags]           SP-T295  lenovo-x1  darter-pro  dell-7330
    Switch to vm     ${GUI_VM}
    ${output}        Run Command    ls /nix/store | grep openssl-3    rc_match=skip
    Should Not Be Empty    ${output}    msg=Found no openssl in Nix Store

*** Keywords ***

Try External Login With Wrong Password
    [Arguments]     ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${timeout}=10
    Log To Console    Trying to log in with the wrong password
    ${wrong_password_cmd}   Set Variable
    ...    nix shell nixpkgs#sshpass -c sh -c 'for i in $(seq 1 ${FAILED_SSH_LOGIN_ATTACK_COUNT}); do sshpass -p wrong ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o PasswordAuthentication=yes -o KbdInteractiveAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${DEVICE_IP_ADDRESS} true; done'
    ${result}   Run Process
    ...    sh
    ...    -c
    ...    ${wrong_password_cmd}
    ...    timeout=120
    Log    Wrong-password attempt stdout:\n${result.stdout}
    Log    Wrong-password attempt stderr:\n${result.stderr}
    Should Not Be Equal As Integers    ${result.rc}    0    Wrong-password login unexpectedly succeeded
    Should Contain    ${result.stderr}    Permission denied    Wrong-password attempt did not fail as an SSH authentication error
    Should Not Contain    ${result.stderr}    command not found
    Should Not Contain    ${result.stderr}    error:
    ${connection}   Open Connection    ${DEVICE_IP_ADDRESS}    port=22    prompt=\$    timeout=${timeout}
    TRY
        Log To Console    Trying to log in with the correct password
        ${status}  ${login_output}   Run Keyword And Ignore Error
        ...    Login with timeout
        ...    expected_output=${NET_VM}
        ...    username=${user}
        ...    password=${pw}
        ...    timeout=${timeout}
        Should Not Be Equal    ${status}    PASS    Correct-password login unexpectedly succeeded after failed login attempts
    EXCEPT    Keyword timeout ${timeout} seconds exceeded.
        Log   Failed to connect with correct password in ${timeout} seconds.    console=True
    FINALLY
        Run Keyword And Ignore Error    Close Connection
    END

Account lockout teardown
    [Arguments]     ${blacklisted_at}
    Close All Connections
    IF    $blacklisted_at == None
        Log    Skipping lockout wait because the blacklist timestamp was not set.    console=True
        RETURN
    END
    # Wait for the lockout window to pass before verifying SSH access is restored.
    ${now}            Get Time    epoch
    ${elapsed}        Evaluate    int(${now}) - int(${blacklisted_at})
    ${remaining_wait}    Evaluate    max(0, 60 - int(${elapsed}))
    IF    ${remaining_wait} > 0
        Log To Console    Waiting ${remaining_wait}s before verifying SSH access is restored
        Wait    ${remaining_wait}
    END
    ${connectivity_restored}    Run Keyword And Return Status    Verify External Connectivity Restored    SSH
    IF    not ${connectivity_restored}
        Log    SSH access was not restored after waiting, falling back to hard reboot.    console=True
        Hard Reboot Device And Connect   verify_shutdown=False
    END
