# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Test user authentication

Resource            ../../resources/active-directory.resource
Resource            ../../resources/ssh_keywords.resource

Test Tags           authentication  lenovo-x1  darter-pro  lab-only


*** Variables ***
${ACTIVE_DIRECTORY_SERVER_IP}    20.174.11.80


*** Test Cases ***
Use recovery key to login
    [Documentation]    Get the recovery key from user provisioning logs and use it to log in to gui-vm.
    [Tags]             SP-T302
    Connect to GUI VM with recovery key
    Verify recovery key SSH login

Active Directory server is reachable
    [Documentation]    Verify that the Active Directory server IP address is reachable from ${GUI_VM}.
    [Tags]             SP-T522
    [Setup]            Switch to vm   ${GUI_VM}
    Check Network Availability    ${ACTIVE_DIRECTORY_SERVER_IP}    limit_freq=${False}

Confirm Active Directory connectivity with homed user
    [Documentation]    Navigate the interactive provisioning script and exit after its AD connectivity success message.
    [Tags]             SP-T520
    [Setup]            Switch to vm  ${GUI_VM}
    Check AD Connectivity Through User Provisioning    Enroll AD user to homed    move_down=${True}
    [Teardown]         Run Keyword If Test Failed   SKIP   Known Issue SSRCSP-9169: Enrolling AD user to homed does not work


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
