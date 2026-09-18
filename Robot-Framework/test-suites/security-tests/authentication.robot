# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Test user authentication
Test Tags           authentication  lenovo-x1  darter-pro

Resource            ../../resources/ssh_keywords.resource


*** Test Cases ***

Use recovery key to login
    [Documentation]    Get the recovery key from user provisioning logs and use it to log in to gui-vm.
    [Tags]             SP-T302  lab-only
    Connect to GUI VM with recovery key
    Verify recovery key SSH login


*** Keywords ***

Connect to GUI VM with recovery key
    Switch to vm           ${GUI_VM}
    Set Log Level          NONE
    ${journal}             Run Command    journalctl -u user-provision-test.service --no-pager -o cat    sudo=True
    ${recovery_keys}       Get Regexp Matches    ${journal}    [a-z-]{71}
    Should Not Be Empty    ${recovery_keys}    Recovery key was not found in user-provision-test.service logs
    Set Log Level          INFO
    Open VM connection with recovery key     ${GUI_VM}    ${USER_LOGIN}    ${recovery_keys}[0]
    [Teardown]             Set Log Level    INFO

Verify recovery key SSH login
    ${logged_in_user}    Run Command         whoami
    Should Be Equal      ${logged_in_user}   ${USER_LOGIN}    Failed to log in to gui-vm as ${USER_LOGIN} using the recovery key
    [Teardown]           Close Connection
