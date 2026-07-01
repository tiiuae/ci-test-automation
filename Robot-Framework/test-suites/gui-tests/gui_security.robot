# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing security via GUI
Force Tags          gui-security

Test Timeout        10 minutes
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource

Test Setup          Run keywords      Start screen recording
Test Teardown       Run keywords      Switch to vm            ${GUI_VM}  user=${USER_LOGIN}        AND
...                                   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

*** Test Cases ***
Check Access List In Trusted Browser
    [Tags]    SP-T209  SP-T210  SP-T211  SP-T362  lenovo-x1  darter-pro
    [Template]    Check Access List In Trusted Browser Template
    # Pages outside access list shouldn't be available via Trusted Browser. Http and https has different errors
    https://yle.fi                          text_to_find=This site can’t be reached
    http://yle.fi                           text_to_find=Access Denied

    # Access List consist of several files with multiple sections. These pages are 1 per section.
    https://graph.microsoft.com             text_to_find=Microsoft Graph
    https://excel.cloud.microsoft.com       text_to_find=Welcome to Excel
    https://word.cloud.microsoft            text_to_find=Welcome to Word
    https://powerpoint.cloud.microsoft      text_to_find=start using PowerPoint
    https://teams.live.com                  text_to_find=Video calls
    https://www.msn.com                     text_to_find=MSN
    https://onedrive.live.com               text_to_find=OneDrive
    https://www.akamai.com/                 text_to_find=Akamai
    https://ghaflogs.vedenemo.dev           text_to_find=Welcome to Grafana
    https://www.google.com                  text_to_find=Google
    https://thenationalnews.com             text_to_find=The National
    https://access.clarivate.com            text_to_find=innovation at Clarivate
    https://hcm22.sapsf.com                 text_to_find=SAP SuccessFactors
    https://jira.atlassian.com              text_to_find=Jira Software

Account lockout after failed GUI login
    [Documentation]     Try to login to the device with a wrong password for several times, then check that user account is locked.
    ...                 Remove account from the lock list and log back in with the correct password.
    [Tags]              SP-T267  lenovo-x1  darter-pro
    Log out and verify
    Check faillock entry count    0
    # Account is locked after wrong password is given 5 times
    FOR   ${i}   IN RANGE   1   6
        Log              Typing wrong password (iteration #${i})   console=True
        Log in via GUI   password=wrong_password   sleep_seconds=1
        Wait Until Keyword Succeeds    10x    1s    Check faillock entry count    ${i}
    END
    Log     Trying to login with correct password   console=True
    Run Keyword And Expect Error     *    Log in, unlock and verify
    [Teardown]       Run keywords    Unlock account and login
    ...                       AND    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

*** Keywords ***

Check Access List In Trusted Browser Template
    [Documentation]    Running Trusted Browser and trying to find text on the opened page.
    ...                If page is blocked by access list, error depends on the protocol used:
    ...                   https: 'This site can’t be reached'
    ...                   http:  'Access Denied'
    [Arguments]    ${url}   ${text_to_find}
    Start application in VM   "Trusted Browser"   ${BUSINESS_VM}   google-chrome    params_string=-- ${url}    always_check_vm=True
    Switch to vm              ${GUI_VM}    user=${USER_LOGIN}

    Wait Until Keyword Succeeds     10x                        1s
    ...                             Verify Text Is On The Screen    ${text_to_find}

    [Teardown]    Run keywords      Switch to vm           ${BUSINESS_VM}    AND
    ...                             Kill process by name   google-chrome

Unlock account and login
    [Documentation]  Unlock the user account and log back in
    [Setup]          Switch to vm     ${GUI_VM}
    Run Command      faillock --user ${USER_LOGIN} --reset   sudo=True
    Switch to vm     ${GUI_VM}  user=${USER_LOGIN}
    # First login after unlocking the account fails
    Log in via GUI   password=reset_login   sleep_seconds=1
    Log in, unlock and verify

Check faillock entry count
    [Documentation]    Verify that the current faillock entry count matches ${expected_count}
    [Arguments]        ${expected_count}
    [Setup]       Switch to vm    ${GUI_VM}
    ${count}      Run Command    faillock --user ${USER_LOGIN} | grep -c '^[0-9]'    sudo=True    rc_match=skip
    Should Be Equal As Integers    ${count}    ${expected_count}
    Log           Wrong password detected ${expected_count} times    console=True
    [Teardown]    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
