# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Verify access rights and isolation across memory zones, virtual machines, and system resources
Force Tags          regression  security  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/ssh_keywords.resource

Suite Setup         Setup


*** Test Cases ***

Check access to host devices
    [Documentation]     Check that ghaf user has access to host devices in ghaf-host
    ...                 and does not have the access inside VMs
    [Tags]              SP-T265
    [Template]          Check access to host devices in ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END

Check that unauthorised user has no access to host devices
    [Documentation]     Check that test user does not have access to host devices in Gui-vm
    [Tags]              SP-T265
    Switch to vm        ${GUI_VM}  user=${USER_LOGIN}
    ${nvme0n1_access}   Check access   /dev/nvme0n1
    Run Keyword And Continue On Failure 	Should Not Be True  ${nvme0n1_access}


*** Keywords ***

Setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}

Check access to host devices in ${vm}
    Switch to vm    ${vm}
    ${nvme0n1_access}   Check access   /dev/nvme0n1
    IF    '${vm}' == 'ghaf-host'
        Run Keyword And Continue On Failure 	Should Be True  ${nvme0n1_access}
    ELSE
        Run Keyword And Continue On Failure 	Should Not Be True  ${nvme0n1_access}
    END

Check access
    [Arguments]   ${path}
    ${out}  ${err}  ${rc}    Execute Command    ls -ld ${path}    return_stderr=True    return_rc=True
    ${status}    Evaluate    ${rc} == 0
    RETURN       ${status}
