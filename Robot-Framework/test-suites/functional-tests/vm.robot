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


*** Test Cases ***

Check internet connection in every VM
    [Documentation]    Pings google from every vm.
    [Tags]             SP-T257
    ${failed_vms}=    Create List
    FOR  ${vm}  IN  @{VM_LIST_WITH_HOST}
        Switch to vm     ${vm}
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
    [Tags]             SP-T98-2   systemctl
    ${failed_new_services}=    Create List
    ${failed_old_services}=    Create List
    ${known_issues}=    Create List
    # Add any known failing services here with the vm name and bug ticket number.
    # ...    vm|service-name|ticket-number
    ...    gui-vm|setup-ghaf-user.service|SSRCSP-7234
    ...    gui-vm|plymouth-quit.service|SSRCSP-7306
    ...    audio-vm|systemd-rfkill.service|SSRCSP-7321

    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm     ${vm}
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

Verify EPT is enabled in every VM
    [Documentation]    Check that ETP is enabled in every vm.
    [Tags]             SP-T274
    ${failed_vms}      Create List
    FOR  ${vm}  IN  @{VM_LIST_WITH_HOST}
        Switch to vm     ${vm}
        ${output}        Execute Command    cat /sys/module/kvm_intel/parameters/ept
        Log              ${output}
        ${result}        Run Keyword And Return Status    Should Contain    ${output}    Y
        IF    not ${result}
            Log To Console    FAIL: ${vm} does not have ETP enabled
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with ETP not enabled: ${failed_vms}

Check user account is only in gui-vm
    [Documentation]    Check that user account is only available in gui-vm
    [Tags]             SP-T291
    ${failed_vms}      Create List
    FOR  ${vm}  IN  @{VM_LIST_WITH_HOST}
        IF   '${vm}' != '${GUI_VM}'
            Switch to vm   ${vm}
            ${output}      Execute Command    users
            ${result}      Run Keyword And Return Status   Should Not Contain    ${output}    ${USER_LOGIN}
            IF    not ${result}
                Log To Console    FAIL: User account available in ${vm}
                Append To List    ${failed_vms}    ${vm}
            END
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with user account available: ${failed_vms}

*** Keywords ***

VM Suite Setup
    Switch to vm    ghaf-host
    ${output}       Execute Command    microvm -l
    @{VM_LIST}      Extract VM names   ${output}
    Should Not Be Empty     ${VM_LIST}   VM list is empty
    Set Suite Variable      @{VM_LIST}
    @{VM_LIST_WITH_HOST}    Create List   @{VM_LIST}   ghaf-host
    Set Suite Variable      @{VM_LIST_WITH_HOST}

Check VM systemctl status for known issues
    [Arguments]    ${vm}   ${known_issues_list}   ${failing_services}
    [Documentation]    Check if failing services in VMs contain issues that are not listed as known
    ${old_issues}=    Create List
    ${new_issues}=    Create List
    FOR    ${failing_service}    IN    @{failing_services}
        ${known}=     Set Variable    False
        ${unit_logs}  Execute command   journalctl -u ${failing_service}
        Log            ${unit_logs}
        FOR    ${entry}    IN    @{known_issues_list}
            ${list_vm}  ${service}  ${issue}   Parse Known Issue   ${entry}

            ${vm_match}=         Run Keyword And Return Status    Should Contain    ${vm}    ${list_vm}
            ${service_match}=    Run Keyword And Return Status    Should Contain    ${failing_service}    ${service}

            IF   (${vm_match} or '${list_vm}' == 'ANY') and (${service_match} or '${service}' == 'ANY')
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