# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Verify that VMs boot into immutable, signed filesystem snapshots
Force Tags          security  regression  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Suite Setup


*** Test Cases ***

VM is wiped after restarting
    [Documentation]     Verify that created file will be removed after restarting VM
    [Tags]              SP-T48
    [Template]          ${vm} is wiped after restarting
    FOR    ${vm}    IN    @{VM_LIST}
        IF    '${vm}' != '${GUI_VM}' and '${vm}' != '${NET_VM}'
            ${vm}
        END
    END


*** Keywords ***

Suite Setup
    @{VM_LIST}      Get VM list
    Set Suite Variable      @{VM_LIST}

${vm} is wiped after restarting
    [Documentation]     Verify that created file will be removed after restarting VM
    [Tags]              SP-T48
    Switch to vm        ${vm}
    Create file         /etc/test.txt    sudo=True
    Close Connection
    Switch to vm        ${HOST}
    Restart VM          ${vm}
    Check Network Availability      ${vm}    expected_result=True    range=15
    Switch to vm        ${vm}
    Log To Console      Check if created file still exists
    Check file doesn't exist    /etc/test.txt    sudo=True
    [Teardown]  Run Keyword If  "${KEYWORD STATUS}" == 'FAIL'   Start VM   ${vm}

Start VM
    [Documentation]         Try to start VM and verify it started
    [Arguments]             ${vm}
    Switch to vm            ${HOST}
    Log                     Going to start ${vm}    console=True
    Execute Command         systemctl start microvm@${vm}.service  sudo=True  sudo_password=${PASSWORD}  timeout=120
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=active  expected_substate=running
    Log                     ${vm} is ${substate}    console=True
    Check if ssh is ready on vm   ${vm}