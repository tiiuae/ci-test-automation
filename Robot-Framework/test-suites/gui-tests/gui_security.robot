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
    [Tags]    SP-T362   SP-T210  SP-T209  SP-T211   lenovo-x1  darter-pro
    [Template]    Check Access List In Trusted Browser Template
    # Pages outside access list shouldn't be available via Trusted Browser. Http and https has different errors
    https://yle.fi                          text_to_find=This site can’t be reached
    http://yle.fi                           text_to_find=Access Denied

    # Access List consist of several files with multiple sections. These pages are 1 per section.
    https://graph.microsoft.com             text_to_find=Microsoft Graph
    https://excel.cloud.microsoft.com       text_to_find=Welcome to Excel
    https://word.cloud.microsoft            text_to_find=Welcome to Word
    https://powerpoint.cloud.microsoft      text_to_find=start using PowerPoint
    https://teams.live.com                  text_to_find=Video calls with anyone
    https://www.msn.com                     text_to_find=MSN
    https://onedrive.live.com               text_to_find=Microsoft 365
    https://www.akamai.com/                 text_to_find=Akamai
    https://ghaflogs.vedenemo.dev           text_to_find=Welcome to Grafana
    https://www.google.com                  text_to_find=Google
    https://thenationalnews.com             text_to_find=The National
    https://access.clarivate.com            text_to_find=innovation at Clarivate
    https://hcm22.sapsf.com                 text_to_find=SAP SuccessFactors
    https://jira.atlassian.com              text_to_find=Jira Software

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
