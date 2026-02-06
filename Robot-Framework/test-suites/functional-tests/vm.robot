# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests that are run in every VM
Test Tags           vms  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  fmo

Library             ../../lib/output_parser.py
Library             Collections
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         VM Suite Setup


*** Variables ***
# Add any known failing services here with the vm name and bug ticket number.
# device|vm|service-name|ticket-number
@{known_issues}=    ANY|audio-vm|systemd-rfkill.service|SSRCSP-7321
             ...    dell-7330|ghaf-host|autovt@ttyUSB0.service|SSRCSP-6667
             ...    ANY|gui-vm|plymouth-start.service|SSRCSP-7306
             ...    ANY|gui-vm|plymouth-quit.service|SSRCSP-7306
             ...    ANY|gui-vm|setup-ghaf-user.service|SSRCSP-7234
             ...    ANY|ANY|tuned.service|SSRCSP-7717
             ...    ANY|ANY|fail2ban.service|SSRCSP-7759
             ...    ANY|ANY|journal-fss-verify.service|SSRCSP-7973
             ...    orin|ghaf-host|nvfancontrol.service|SSRCSP-6303
             ...    orin-agx|ghaf-host|systemd-rfkill.service|SSRCSP-6303
             ...    orin|ghaf-host|systemd-oomd.service|SSRCSP-6685
             ...    orin|admin-vm|audit-rules-nixos.service|SSRCSP-8066
             ...    orin|net-vm|audit-rules-nixos.service|SSRCSP-8066
             ...    orin|admin-vm|stunnel.service|SSRCSP-8067
             ...    orin|admin-vm|alloy.service|SSRCSP-8071
             ...    orin|admin-vm|ghaf-journal-alloy-recover.service|SSRCSP-8071

# Container for test message. Keyword `Set Test Message` doesn't work properly with Templates.
# Accumulates messages from tests that use 'Check systemctl status Template' to be added to the main test message in teardown
${found_known_issues_message}=


*** Test Cases ***

Check internet connection in every VM
    [Documentation]    Pings google from every vm.
    [Tags]             SP-T257   orin-agx  orin-agx-64  orin-nx
    ${failed_vms}=    Create List
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
    [Template]    Check systemctl status Template
    [Teardown]    Set Test Message    append=${True}  separator=\n    message=${found_known_issues_message}
    [Tags]             SP-T98  systemctl  orin-agx  orin-agx-64  orin-nx
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END

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
    [Tags]             SP-T351  SP-T351-2  orin-agx  orin-agx-64  orin-nx
    ${host_device_id}  Get Actual Device ID
    @{VM_LIST}         Get VM list
    ${failed_vms}      Create List
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        ${id}          Run Command  cat /etc/common/device-id
        Log            Device ID in ${vm}: ${id}, expected be te same as in host: ${host_device_id}     console=True
        ${result}      Run Keyword And Return Status    Should Be Equal As Strings
        ...            ${id}    ${host_device_id}    ignore_case=True
        IF    not ${result}
            Log To Console    FAIL: Device ID in ${vm} is ${id}, but device ID in host is ${host_device_id}
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with different Device IDs: ${failed_vms}


*** Keywords ***

Check systemctl status Template
    [Arguments]    ${vm}
    ${failed_new_services}=    Create List
    ${failed_old_services}=    Create List

    Switch to vm     ${vm}
    ${status}   ${failed_units}   Verify Systemctl status
    Should not be true    '${status}' == 'starting'      msg=Current systemctl status is ${status}. Failed processes?: ${failed_units}

    # Filter out interactive user provisioning service (we use the non-interactive version in tests)
    ${filtered_failed_units}    Evaluate   [u for u in ${failed_units} if "user-provision-interactive.service" not in u]
    Log    ${filtered_failed_units}

    IF     ${filtered_failed_units}
        Check systemctl status for known issues    ${DEVICE_TYPE}   ${vm}   ${known_issues}   ${filtered_failed_units}
    END

VM Suite Setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}
