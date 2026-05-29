# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Verify that VMs boot into immutable, signed filesystem snapshots
Test Tags           immutability  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         Suite Setup
Suite Teardown      Ensure Robot sudoers is installed in all VMs   skip_boot_check=True


*** Test Cases ***

VM is wiped after restarting
    [Documentation]     Verify that created file will be removed after restarting VM
    [Tags]              SP-T48
    [Template]          ${vm} is wiped after restarting
    FOR    ${vm}    IN    @{VM_LIST}
        IF    '${vm}' != '${GUI_VM}' and '${vm}' != '${NET_VM}' and '${vm}' != '${ADMIN_VM}'
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
    Restart VM          ${vm}   restore_sudoers=False
    Check Network Availability      ${vm}    expected_result=True    range=15
    Switch to vm        ${vm}
    Log To Console      Check if created file still exists
    Check file doesn't exist    /etc/test.txt    sudo=True
    [Teardown]  Run Keyword If  "${KEYWORD STATUS}" == 'FAIL'   Restart VM   ${vm}   start_only=True   restore_sudoers=False