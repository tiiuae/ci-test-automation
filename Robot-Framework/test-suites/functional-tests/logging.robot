# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing logging
Test Tags           logging  pre-merge  bat  lenovo-x1  darter-pro  dell-7330

Library             DateTime
Library             OperatingSystem
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource

Suite Setup         Logging Suite Setup


*** Variables ***
${TEST_LOG}           log_check_${BUILD_ID}


*** Test Cases ***

Logging service is running in all VMs
    [Documentation]    Check that logging service is running in every VM
    [Tags]             SP-T333
    ${failed_vms}      Create List
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        IF   '${vm}' == '${ADMIN_VM}'
            ${status}  ${output}   Run Keyword And Ignore Error   Verify service status  range=15   service=stunnel.service  expected_state=active  expected_substate=running
        ELSE
            ${status}  ${output}   Run Keyword And Ignore Error   Verify service status  range=15   service=alloy.service  expected_state=active  expected_substate=running
        END
        Log   ${output}
        IF    '${status}' == 'FAIL'
            Log    FAIL: Logging service not running in ${vm}   console=True
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with alloy.service not running: ${failed_vms}

Check Grafana logs
    [Documentation]  Check that all virtual machines are sending logs to Grafana
    [Tags]           SP-T172
    Check Network Availability    8.8.8.8   limit_freq=${False}
    Switch to vm     ${ADMIN_VM}
    ${id}            Run Command  cat /etc/common/device-id
    Run Keyword And Continue On Failure   Create logs in all VMs
    Wait Until Keyword Succeeds  60s  5s  Check Logs Are available  ${id}


*** Keywords ***

Logging Suite Setup
    @{VM_LIST}               Get VM list  with_host=True
    @{HOSTNAME_LIST}         Set Variable   @{VM_LIST}
    Append To List           ${HOSTNAME_LIST}   ${NETVM_NAME}
    Remove Values From List  ${HOSTNAME_LIST}   ${NET_VM}
    Set Suite Variable       @{VM_LIST}
    Set Suite Variable       @{HOSTNAME_LIST}

Check Logs Are Available
    [Documentation]  Check that virtual machine's logs are available in Grafana
    [Arguments]      ${id}
    FOR  ${vm}  IN  @{HOSTNAME_LIST}
        ${status}   Check VM Log on Grafana    ${id}   ${vm}   10

        # Logging from one VM sometimes stops during the run (SSRCSP-7612).
        # To avoid failures in the pipelines the test checks for any logs during the last 10 minutes.
        # 10 minutes should be enough to make sure that logs from previous run are not detected.
        # When the bug is fixed the old version should be taken back into use.
        IF   $status == ${False}
            IF   '${vm}' == '${NETVM_NAME}'
                # Ignore net-vm error SSRCSP-7542
                Save net-vm log
            ELSE
                Run Keyword And Continue On Failure   FAIL   ${vm} query does not contain logs
            END
        END
    END

Create logs in all VMs
    [Documentation]    Create new SSH connection to all VMs to make sure there are recent logs
    Close All Connections
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        Run Command  logger --priority=user.info "${TEST_LOG}"    sudo=True
        ${out}   Run Command    journalctl --since "1 minute ago" | grep "${TEST_LOG}"
        Run Keyword And Continue On Failure   Should Contain  ${out}   ${TEST_LOG}   Log was not created in ${vm}
    END

Save net-vm log
    Switch to vm   ${NET_VM}
    Run Command   journalctl -b
    [Teardown]     Switch to vm   ${ADMIN_VM}