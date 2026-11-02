# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Tests that are run in every VM

Library             ../../lib/output_parser.py
Library             Collections
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         VM Suite Setup

Test Tags           vms  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  fmo


*** Variables ***
# Add any known failing services here with the vm name and bug ticket number.
# device|vm|service-name|ticket-number
@{known_issues}     ANY|ghaf-host|systemd-rfkill.service|SSRCSP-7321
             ...    darter|ghaf-host|systemd-tpm2-setup.service|SSRCSP-8357
             ...    darter|ghaf-host|systemd-pcrlogin@901.service|SSRCSP-8776
             ...    ANY|disp-vm|systemd-modules-load.service|SSRCSP-9041

# Container for test message. Keyword `Set Test Message` doesn't work properly with Templates.
# Accumulates messages from tests that use 'Check systemctl status Template' to be added to the main test message in teardown
${found_known_issues_message}


*** Test Cases ***
Check internet connection in every VM
    [Documentation]    Pings google from every vm.
    [Tags]             SP-T257  orin-agx  orin-agx-64  orin-nx
    ${failed_vms}     Create List
    FOR  ${vm}  IN  @{VM_LIST_WITH_HOST}
        Switch to vm     ${vm}
        ${status}     Run Keyword And Return Status   Check Network Availability   8.8.8.8   limit_freq=${False}
        IF    not ${status}
            Log To Console    FAIL: ${vm} does not have internet connection
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with no internet connection: ${failed_vms}

Check systemctl status in every VM
    [Documentation]    Check that systemctl status is running in every vm.
    [Tags]             SP-T98  systemctl  orin-agx  orin-agx-64  orin-nx
    [Template]    Check systemctl status Template
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END
    [Teardown]    Set Test Message    append=${True}  separator=\n    message=${found_known_issues_message}

Verify EPT is enabled in every VM
    [Documentation]    Check that ETP is enabled in every vm.
    [Tags]             SP-T274
    ${failed_vms}      Create List
    FOR  ${vm}  IN  @{VM_LIST_WITH_HOST}
        Switch to vm     ${vm}
        ${output}        Run Command    cat /sys/module/kvm_intel/parameters/ept
        ${result}        Run Keyword And Return Status    Should Contain    ${output}    Y
        IF    not ${result}
            Log To Console    FAIL: ${vm} does not have ETP enabled
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with ETP not enabled: ${failed_vms}

Check Device ID in every VM
    [Documentation]    Check that Device ID is the same in every vm.
    [Tags]             SP-T468  orin-agx  orin-agx-64  orin-nx
    ${host_device_id}  Get Actual Device ID
    @{VM_LIST}         Get VM list
    ${failed_vms}      Create List
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        ${id}          Get Actual Device ID
        Log            Device ID in ${vm}: ${id}, expected to be the same as in host: ${host_device_id}     console=True
        ${result}      Run Keyword And Return Status    Should Be Equal As Strings
        ...            ${id}    ${host_device_id}    ignore_case=True
        IF    not ${result}
            Log To Console    FAIL: Device ID in ${vm} is ${id}, but device ID in host is ${host_device_id}
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with different Device IDs: ${failed_vms}

VMs use net-vm as DNS server
    [Documentation]    Check that every VM except net-vm uses 192.168.100.1 as its current and configured DNS server.
    [Tags]             SP-T515  orin-agx  orin-agx-64  orin-nx
    @{vms}             Get VM list
    Remove Values From List    ${vms}    ${NET_VM}
    FOR    ${vm}    IN    @{vms}
        Run Keyword And Continue On Failure    Verify VM uses net-vm as DNS server    ${vm}
    END


*** Keywords ***
Verify VM uses net-vm as DNS server
    [Arguments]     ${vm}
    Switch to vm    ${vm}
    ${output}       Run Command    resolvectl status
    FOR    ${field}    IN    Current DNS Server    DNS Servers
        ${value}    Get Regexp Matches    ${output}    (?m)^\\s*${field}: (.+)$    1
        Should Be Equal    ${value}[0]    192.168.100.1     msg=${vm}: ${field} is ${value}[0], expected 192.168.100.1
    END

Check systemctl status Template
    [Arguments]    ${vm}   ${timeout}=2 minutes
    ${failed_new_services}     Create List
    ${failed_old_services}     Create List
    Switch to vm    ${vm}
    ${status}   ${failed_units}   Verify Systemctl status

    Should Not Be True    '${status}' == 'starting'      msg=Current systemctl status is ${status}. Failed processes?: ${failed_units}

    # Filter out interactive user provisioning service (we use the non-interactive version in tests)
    ${filtered_failed_units}    Evaluate   [u for u in ${failed_units} if "user-provision-interactive.service" not in u]
    Log    ${filtered_failed_units}

    IF     ${filtered_failed_units}
        Check systemctl status for known issues    ${DEVICE_TYPE}   ${vm}   ${known_issues}   ${filtered_failed_units}
    END
    [Teardown]   Reboot Orin if ssh connection dropped

VM Suite Setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}
