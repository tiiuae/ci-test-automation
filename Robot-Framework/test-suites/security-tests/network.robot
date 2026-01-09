# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check network related security
Test Tags           network-security
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Resource            ../../resources/common_keywords.resource


*** Test Cases ***

Account lockout after failed login
    [Documentation]  Try to connect from Comms-vm to Chrome-vm with a wrong password for several times, then check that
    ...              Comms-vm's ip is blacklisted in Chrome-vm and it is not possible to connect even with correct password
    [Tags]           SP-T268  lenovo-x1  darter-pro
    Switch to vm     ${COMMS_VM}
    ${ip}            Get VM IP
    Try to connect with wrong password    ${CHROME_VM}  jumphost=${COMMS-VM_GHAF_SSH}
    Check ip is in the blacklist  ${CHROME_VM}  ${ip}
    [Teardown]       Remove from the blacklist  ${ip}

Check OpenSSL3 is Available In Nix Store
    [Documentation]  Connect to GUI-VM and check that OpenSSL3 is available in NixStore.
    [Tags]           SP-T295  lenovo-x1  darter-pro   dell-7330
    Switch to vm     ${GUI_VM}
    ${output}        Run Command    ls /nix/store | grep openssl-3    rc_match=skip
    Should Not Be Empty    ${output}    msg=Found no openssl in Nix Store

*** Keywords ***

Try to connect with wrong password
    [Arguments]   ${vm_name}    ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${jumphost}=None   ${timeout}=10
    ${connection}       Open Connection    ${vm_name}    port=22    prompt=\$    timeout=${timeout}
    FOR    ${i}    IN RANGE     5
        TRY
            ${status}  ${login_output}   Run Keyword And Ignore Error  Login with timeout  expected_output=${vm_name}  username=${user}  password=wrong  timeout=${timeout}  jumphost=${jumphost}
        EXCEPT    Keyword timeout ${timeout} seconds exceeded.
            BREAK
        END
    END
    TRY
        Run Keyword And Ignore Error  Login with timeout  expected_output=${vm_name}  username=${user}  password=${pw}  timeout=${timeout}  jumphost=${jumphost}
    EXCEPT    Keyword timeout ${timeout} seconds exceeded.
        Log   Failed to connect with correct password in ${timeout} seconds.
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