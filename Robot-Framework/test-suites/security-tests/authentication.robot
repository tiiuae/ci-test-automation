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
    [Documentation]    Get the recovery key from storage and use it to log in to gui-vm.
    ...                This test only works if user was created with Create user.
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


*** Keywords ***
Connect to GUI VM with recovery key
    Switch to vm            ${GUI_VM}
    TRY
        ${previous_log_level}   Set Log Level    NONE
        ${recovery_key}         Run Command      cat /etc/common/recovery-key   sudo=True
    FINALLY
        Set Log Level    ${previous_log_level}
    END
    Open VM connection with recovery key    ${GUI_VM}    ${USER_LOGIN}    ${recovery_key}

Verify recovery key SSH login
    ${logged_in_user}    Run Command         whoami
    Should Be Equal      ${logged_in_user}   ${USER_LOGIN}    Failed to log in to gui-vm as ${USER_LOGIN} using the recovery key
    [Teardown]           Close Connection
