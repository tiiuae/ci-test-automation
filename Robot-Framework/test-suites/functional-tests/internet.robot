# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Internet tests
Force Tags          internet
Resource            ../../__framework__.resource
Resource            ../../resources/ssh_keywords.resource
Suite Setup         Connect to netvm
Suite Teardown      Close All Connections

*** Test Cases ***

Check all VMs have internet connection
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
