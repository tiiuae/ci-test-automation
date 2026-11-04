# SPDX-FileCopyrightText: 2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Keywords for Active Directory provisioning and connectivity checks.

Resource            ssh_keywords.resource


*** Keywords ***
Check AD Connectivity Through User Provisioning
    [Documentation]    Open user-provision, select the requested AD flow, and report its connectivity result.
    [Arguments]        ${menu_option}    ${move_down}=${False}
    TRY
        Elevate to superuser
        Log    Opening interactive user provisioning    console=True
        SSHLibrary.Write    user-provision
        SSHLibrary.Read Until    ${menu_option}
        Log    Selecting ${menu_option}    console=True
        IF    ${move_down}
            SSHLibrary.Write Bare    \x1b[B
        END
        SSHLibrary.Write Bare    \r
        SSHLibrary.Read Until    Select domain:
        SSHLibrary.Write Bare    \r
        Log    Domain selected, waiting for connectivity status    console=True
        Wait For AD Connectivity Result
    FINALLY
        # Interrupt user-provision
        Run Keyword And Ignore Error    SSHLibrary.Write Bare    \x03
        SSHLibrary.Write Bare    \r
    END

Wait For AD Connectivity Result
    [Documentation]    Keep terminal output in the keyword log and report a concise connectivity failure.
    TRY
        SSHLibrary.Read Until    AD server reachable:
    EXCEPT    *Cannot connect to AD backend*    type=GLOB
        FAIL    User provisioning could not connect to the configured LDAP/LDAPS backend
    EXCEPT    *Cannot reach AD server:*    type=GLOB
        FAIL    User provisioning could not ping the configured AD server
    EXCEPT    AS    ${error}
        FAIL    Active Directory connectivity test failed: ${error}
    ELSE
        Log    Connection to Active Directory server confirmed   console=True
    END
