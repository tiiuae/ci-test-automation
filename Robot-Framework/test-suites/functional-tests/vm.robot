# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests that are run in every VM
Force Tags          vms
Resource            ../../__framework__.resource
Resource            ../../resources/ssh_keywords.resource
Suite Setup         Connect to netvm
Suite Teardown      Close All Connections

*** Test Cases ***

Check internet connection in every VM
    [Documentation]    Pings google from every vm.
    [Tags]             bat  regression  SP-T257  lenovo-x1  dell-7330
    ${failed_vms}=    Create List
    FOR  ${vm}  IN  @{VMS}
        Connect to VM    ${vm}
        ${output}=       Execute Command    ping -c1 google.com
        Log              ${output}
        ${result}=       Run Keyword And Return Status    Should Contain    ${output}    1 received
        IF    not ${result}
            Log To Console    FAIL: ${vm} does not have internet connection
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with no internet connection: ${failed_vms}


Check systemctl status in every VM
    [Documentation]    Check that systemctl status is running in every vm.
    [Tags]             bat  regression  SP-T98-2  lenovo-x1  dell-7330
    ${failed_vms}=    Create List
    FOR  ${vm}  IN  @{VMS}
        Connect to VM    ${vm}
        ${status}=       Run Keyword And Ignore Error   Verify Systemctl status
        Log              ${status}
        IF    $status[0]=='FAIL'
            Log To Console    ${vm}: ${status}[1]
            Append To List    ${failed_vms}    ${vm}
        END
        Sleep    1
    END
    # This test case has been added to collect information about failed services.
    # If no service is routinely failing it can be changed from Skip to Fail.
    IF  ${failed_vms} != []    Skip    VMs with non-running systemctl status: ${failed_vms}
