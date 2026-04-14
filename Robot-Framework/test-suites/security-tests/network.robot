# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check network related security
Test Tags           network-security
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource


*** Test Cases ***

Account lockout after failed login
    [Documentation]  Try to connect from Comms-vm to Chrome-vm with a wrong password for several times, then check that
    ...              Comms-vm's ip is blacklisted in Chrome-vm and it is not possible to connect even with correct password
    [Tags]           SP-T268  lenovo-x1  darter-pro
    Switch to vm     ${COMMS_VM}
    ${ip}            Get VM IP
    Try to connect with wrong password    ${CHROME_VM}  jumphost=${COMMS-VM_GHAF_SSH}
    Check ip is in the blacklist  ${CHROME_VM}  ${ip}
    [Teardown]    Run Keywords  Remove from the blacklist  ${ip}
    ...           AND   Run Keyword If Test Failed    Skip  "Known Issue: SSRCSP-8006"

Check OpenSSL3 is Available In Nix Store
    [Documentation]  Connect to GUI-VM and check that OpenSSL3 is available in NixStore.
    [Tags]           SP-T295  lenovo-x1  darter-pro   dell-7330
    Switch to vm     ${GUI_VM}
    ${output}        Run Command    ls /nix/store | grep openssl-3    rc_match=skip
    Should Not Be Empty    ${output}    msg=Found no openssl in Nix Store

Check Access List In Trusted Browser
    [Tags]    SSRCSP-T362   lenovo-x1  darter-pro   dell-7330
    [Template]    Check Access List In Trusted Browser Template
    # Pages outside access list shouldn't be available via Trusted Browser. Http and https has different errors
    https://yle.fi                          text_to_find=This site can’t be reached
    http://yle.fi                           text_to_find=Access Denied

    # Access List consist of several files with multiple sections. These pages are 1 per section.
    https://graph.microsoft.com             text_to_find=Microsoft Graph
    https://excel.cloud.microsoft.com       text_to_find=Welcome to Excel
    https://teams.live.com                  text_to_find=Video calls with anyone
    https://www.msn.com                     text_to_find=MSN
    https://onedrive.live.com               text_to_find=Microsoft 365
    https://www.akamai.com/                 text_to_find=Akamai
    https://ghaflogs.vedenemo.dev           text_to_find=Welcome to Grafana
    https://www.google.com                  text_to_find=Google
    https://thenationalnews.com             text_to_find=Latest world news
    https://access.clarivate.com            text_to_find=innovation at Clarivate
    https://hcm22.sapsf.com                 text_to_find=SAP SuccessFactors
    https://jira.atlassian.com              text_to_find=Jira Software

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
    ${output} 	    Run Command    ipset list f2b-sshBlacklist   sudo=True
    Should contain  ${output}    ${ip}

Remove from the blacklist
    [Arguments]      ${ip}
    Run Command  ipset del f2b-sshBlacklist ${ip}   sudo=True

Check Access List In Trusted Browser Template
    [Documentation]    Running Trusted Browser and trying to find text on the opened page.
    ...                If page is blocked by access list, error depends on the protocol used:
    ...                   https: 'This site can’t be reached'
    ...                   http:  'Access Denied'
    [Arguments]    ${url}   ${text_to_find}
    Start application in VM   "Trusted Browser"   ${BUSINESS_VM}   google-chrome    params_string=-- ${url}
    Switch to vm              ${GUI_VM}    user=${USER_LOGIN}

    Wait Until Keyword Succeeds     10x                        1s
    ...                             Verify Text Is On The Screen    ${text_to_find}

    [Teardown]    Run keywords      Switch to vm           ${BUSINESS_VM}    AND
    ...                             Kill process by name   google-chrome
