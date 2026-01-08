# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests that are run in every VM
Force Tags          vms  pre-merge  bat  regression  lenovo-x1  darter-pro  dell-7330  fmo

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
        ${status}     Run Keyword And Return Status   Check Network Availability   8.8.8.8   limit_freq=${False}
        IF    not ${status}
            Log To Console    FAIL: ${vm} does not have internet connection
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with no internet connection: ${failed_vms}

Check systemctl status in every VM
    [Documentation]    Check that systemctl status is running in every vm.
    [Tags]             SP-T98  SP-T98-2   systemctl
    ${failed_new_services}=    Create List
    ${failed_old_services}=    Create List
    ${known_issues}=    Create List
    # Add any known failing services here with the vm name and bug ticket number.
    # ...    vm|service-name|ticket-number
    ...    audio-vm|systemd-rfkill.service|SSRCSP-7321
    ...    ghaf-host|autovt@ttyUSB0.service|SSRCSP-6667
    ...    gui-vm|plymouth-quit.service|SSRCSP-7306
    ...    gui-vm|setup-ghaf-user.service|SSRCSP-7234
    ...    ANY|tuned.service|SSRCSP-7717
    ...    ANY|fail2ban.service|SSRCSP-7759

    FOR  ${vm}  IN  @{VM_LIST_WITH_HOST}
        Switch to vm     ${vm}
        Run Keyword And Ignore Error   Verify Systemctl status
        Log    ${failed_units}

        # Filter out interactive user provisioning service (we use the non-interactive version in tests)
        ${filtered_failed_units}    Evaluate   [u for u in ${failed_units} if "user-provision-interactive.service" not in u]
        Log   ${filtered_failed_units}

        IF    ${filtered_failed_units}
            Run Keyword And Continue On Failure   Check systemctl status for known issues    ${vm}   ${known_issues}   ${filtered_failed_units}
        END
    END

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

*** Keywords ***

VM Suite Setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}
