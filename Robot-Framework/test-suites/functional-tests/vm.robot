# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests that are run in every VM
Force Tags          vms  bat  regression  pre-merge  lenovo-x1  darter-pro  dell-7330  fmo

Library             ../../lib/output_parser.py
Library             Collections
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         VM Suite Setup
Suite Teardown      Close All Connections


*** Test Cases ***

Check internet connection in every VM
    [Documentation]    Pings google from every vm.
    [Tags]             SP-T257
    ${failed_vms}=    Create List
    FOR  ${vm}  IN  @{VM_LIST}
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
    [Tags]             SP-T98-2
    ${failed_new_services}=    Create List
    ${failed_old_services}=    Create List
    ${known_issues}=    Create List
    # Add any known failing services here with the vm name and bug ticket number.
    # ...    vm|service-name|ticket-number

    FOR  ${vm}  IN  @{VM_LIST}
        Connect to VM    ${vm}
        ${status}  ${output}   Run Keyword And Ignore Error   Verify Systemctl status
        IF  $status=='FAIL'
            Log To Console    ${vm}: ${output}
            ${failing_services}    Parse Services To List    ${output}
            ${new_issues}  ${old_issues}  Check VM systemctl status for known issues    ${vm}   ${known_issues}   ${failing_services}
            IF  ${new_issues} != []   Append To List    ${failed_new_services}   ${vm}: ${new_issues}
            IF  ${old_issues} != []   Append To List    ${failed_old_services}   ${vm}: ${old_issues}
        END
    END
    IF  ${failed_new_services} != []    FAIL    Unexpected failed services: ${failed_new_services}, known failed services: ${failed_old_services}
    IF  ${failed_old_services} != []    SKIP    Known failed services: ${failed_old_services}


*** Keywords ***

VM Suite Setup
    Connect to netvm
    Connect to ghaf host
    ${output}       Execute Command    microvm -l
    @{VM_LIST}      Extract VM names   ${output}
    Should Not Be Empty   ${VM_LIST}   VM list is empty
    Set Suite Variable    ${VM_LIST}

Check VM systemctl status for known issues
    [Arguments]    ${vm}   ${known_issues_list}   ${failing_services}
    [Documentation]    Check if failing services in VMs contain issues that are not listed as known
    ${old_issues}=    Create List
    ${new_issues}=    Create List
    FOR    ${failing_service}    IN    @{failing_services}
        ${known}=    Set Variable    False
        FOR    ${entry}    IN    @{known_issues_list}
            ${list_vm}  ${service}  ${issue}   Parse Known Issue   ${entry}

            ${vm_match}=         Run Keyword And Return Status    Should Contain    ${vm}    ${list_vm}
            ${service_match}=    Run Keyword And Return Status    Should Contain    ${failing_service}    ${service}

            IF   ('${vm_match}' == 'True' or '${list_vm}' == 'ANY') and ('${service}' == 'ANY' or '${service_match}') == 'True'
                ${known}=     Set Variable    True
            END
        END
        IF    ${known}   
            Append To List    ${old_issues}    ${failing_service}
        ELSE
            Append To List    ${new_issues}    ${failing_service}
        END
    END
    RETURN    ${new_issues}   ${old_issues}