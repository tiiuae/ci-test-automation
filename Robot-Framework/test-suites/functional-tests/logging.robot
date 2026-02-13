# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing logging
Test Tags           logging  bat  lenovo-x1  darter-pro  dell-7330

Library             DateTime
Library             OperatingSystem
Library             Collections
Library             ../../lib/helper_functions.py
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource

Suite Setup         Logging Suite Setup


*** Variables ***
${TEST_LOG}           log_check_${BUILD_ID}


*** Test Cases ***

Logging service is running in all VMs
    [Documentation]    Check that logging service is running in every VM
    [Tags]             SP-T333  pre-merge
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
    [Tags]           SP-T172  pre-merge
    Check Network Availability    8.8.8.8   limit_freq=${False}
    Switch to vm       ${ADMIN_VM}
    ${id}              Run Command  cat /etc/common/device-id
    Run Keyword And Continue On Failure   Create logs in all VMs
    Sleep              5
    ${failed_vms_check_1}   Check Logs Are Available   ${id}  since=3m  word=${TEST_LOG}
    ${check_status}         Run Keyword And Return Status    Should Be Empty   ${failed_vms_check_1}
    IF  not ${check_status}
        ${since_boot}  Get Time Since Last Boot
        ${failed_vms_check_2}   Check Logs Are available   ${id}   since=${since_boot}s
        ${check_status}         Run Keyword And Return Status    Should Be Empty   ${failed_vms_check_2}
        IF  ${check_status}
            ${fail_msg}=    Catenate    SEPARATOR=\n
            ...    Log forwarding stopped for these VMs: ${failed_vms_check_1}
            ...    Verified that log forwarding was working some time after boot for all VMs
            FAIL   ${fail_msg}
        ELSE
            FAIL   Failed to find any logs since last boot for one or more VMs.\nVMs missing all logs since last boot: ${failed_vms_check_2}
        END
    END

Validate Forward Secure Sealing
    [Documentation]   Run Forward Secure Sealing tests in all VMs
    [Tags]            SP-T353
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        ${output}   Run Command   fss-test   sudo=True   return=out,rc   rc_match=skip
        IF   ${output}[1] != 0
            ${cleaned_output}   Remove Colors   ${output}[0]
            Log  ${cleaned_output}
            ${failed_tests}     Get Matching Lines   ${cleaned_output}   FAIL
            ${msg}              Catenate   SEPARATOR=\n   Fss test failed in ${vm}:
            ...    @{failed_tests}
            Run Keyword And Continue On Failure   FAIL   ${msg}
        END
    END
    [Teardown]  Run Keyword If Test Failed   SKIP   Known issue: SSRCSP-7973

*** Keywords ***

Logging Suite Setup
    @{VM_LIST}               Get VM list  with_host=True
    @{HOSTNAME_LIST}         Set Variable   @{VM_LIST}
    Append To List           ${HOSTNAME_LIST}   ${NETVM_NAME}
    Remove Values From List  ${HOSTNAME_LIST}   ${NET_VM}
    Set Suite Variable       @{VM_LIST}
    Set Suite Variable       @{HOSTNAME_LIST}

Check Logs Are Available
    [Documentation]  Check if logs are available from each VM in Grafana
    ...              Without ${word} argument the keyword tries to find any logs
    [Arguments]      ${id}  ${since}=600s  ${word}=${EMPTY}
    ${failed_vms}    Create List
    FOR  ${vm}  IN  @{HOSTNAME_LIST}
        IF  $word=='${EMPTY}'
            ${status}  Check VM Log on Grafana   ${id}   ${vm}   ${since}
        ELSE
            ${status}  Check VM Log on Grafana   ${id}   ${vm}   ${since}   log_entry=${word}
        END

        # Logging from one VM sometimes stops during the run (SSRCSP-7612).
        # To avoid failures in the pipelines the test checks for any logs during the last 10 minutes.
        # 10 minutes should be enough to make sure that logs from previous run are not detected.
        # When the bug is fixed the old version should be taken back into use.
        IF  $status == ${False}
            IF  '${vm}' == '${NETVM_NAME}'
                # Special case for net-vm SSRCSP-7542
                Save net-vm log
            END
            Append To List    ${failed_vms}    ${vm}
        END
    END
    RETURN  ${failed_vms}

Create logs in all VMs
    [Documentation]    Create new SSH connection to all VMs to make sure there are recent logs
    Close All Connections
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        Run Command  logger --priority=user.info "${TEST_LOG}"
        ${out}   Run Command    journalctl --since "1 minute ago" | grep "${TEST_LOG}"
        Run Keyword And Continue On Failure   Should Contain  ${out}   ${TEST_LOG}   Log was not created in ${vm}
    END

Save net-vm log
    Switch to vm   ${NET_VM}
    Run Command   journalctl -b
    [Teardown]     Switch to vm   ${ADMIN_VM}