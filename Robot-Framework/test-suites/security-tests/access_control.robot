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
    Check access   /dev/nvme0n1    expected=False

Check that unauthorised user has limited access to file system
    [Documentation]     Check that test user does not have access to /root
    ...                 and have access to normal directories like: Pictures, Videos, Shares
    [Tags]              SP-T291-1
    Switch to vm        ${GUI_VM}  user=${USER_LOGIN}
    Check access     /root    expected=False
    Check access     /home/testuser/Pictures    expected=True
    Check access     /Shares    expected=True
    Check available directories    /Shares


*** Keywords ***

Setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}

Check access to host devices in ${vm}
    Switch to vm    ${vm}
    IF    '${vm}' == '${HOST}'
        Check access   /dev/nvme0n1    expected=True
    ELSE
        Check access   /dev/nvme0n1    expected=False
    END

Check access
    [Arguments]   ${path}    ${expected}=True
    ${out}  ${err}  ${rc}    Execute Command    ls ${path}    return_stderr=True    return_rc=True
    ${status}    Evaluate    ${rc} == 0
    IF    ${status} != ${expected}
        Run Keyword And Continue On Failure      FAIL    User has access: ${status}, but expected: ${expected}
    END

Check available directories
    [Arguments]   ${path}
    ${out}  ${rc}    Execute Command    ls ${path}     return_rc=True
    Run Keyword And Continue On Failure   Should Contain   ${out}    Unsafe business-vm share
    Run Keyword And Continue On Failure   Should Contain   ${out}    Unsafe chrome-vm share
    Run Keyword And Continue On Failure   Should Contain   ${out}    Unsafe comms-vm share
    @{dirs}          Split To Lines    ${out}
    ${length}        Get Length      ${dirs}
    Run Keyword And Continue On Failure   Should Be Equal As Integers   ${length}   3