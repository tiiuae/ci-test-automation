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
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/measurement_keywords.resource

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
    ${id}              Get Actual Device ID
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

Check logging rate
    [Documentation]    Check that host or vms are not creating too much logs
    [Tags]             SP-T359  log_rate  pre-merge  orin-agx  orin-agx-64  orin-nx

    ${check_interval}     Set Variable   100
    ${saved_entries}      Set Variable   2000
    ${entry_limit}        Set Variable   500
    ${orin_entry_limit}   Set Variable   2000
    ${bytes_per_entry}    Set Variable   200

    &{spam_metrics}       Create Dictionary
    &{ok_metrics}         Create Dictionary
    &{spam_logs}          Create Dictionary
    &{unavailable_vms}    Create Dictionary
    &{entry_history}      Create Dictionary
    &{byte_history}       Create Dictionary

    FOR  ${vm}  IN  @{VM_LIST}
        Set To Dictionary    ${entry_history}    ${vm}=${EMPTY}
        Set To Dictionary    ${byte_history}     ${vm}=${EMPTY}
    END
    FOR  ${vm}  IN  @{VM_LIST}
        ${vm_is_ready}    Run Keyword And Return Status    Check if ssh is ready on vm    ${vm}    timeout=5
        IF  not ${vm_is_ready}
            Log    Skipping ${vm}: ssh is not ready    console=True
            Set To Dictionary    ${unavailable_vms}    ${vm}=ssh not ready
            CONTINUE
        END
        ${switch_status}    ${switch_output}    Run Keyword And Ignore Error    Switch to vm    ${vm}    timeout=10
        IF  '${switch_status}' == 'FAIL'
            Log    Skipping ${vm}: ${switch_output}    console=True
            Set To Dictionary    ${unavailable_vms}    ${vm}=${switch_output}
            Switch to vm    ${HOST}    timeout=10
            CONTINUE
        END
        IF  '${switch_status}' == 'PASS'
            IF  "orin" in "${DEVICE_TYPE}"
                ${vm_entry_limit}   Set Variable   ${orin_entry_limit}
            ELSE
                ${vm_entry_limit}   Set Variable   ${entry_limit}
            END
            ${vm_byte_limit}    Evaluate    ${vm_entry_limit} * ${bytes_per_entry}

            ${byte_status}    ${byte_rate}    Run Keyword And Ignore Error
            ...    Run Command    journalctl --since "$(date -d '${check_interval} seconds ago' '+%Y-%m-%d %H:%M:%S')" | wc -c | awk '{print $1}'
            ${entries_status}    ${entries}    Run Keyword And Ignore Error
            ...    Run Command    journalctl --since "${check_interval} seconds ago" | wc -l
            IF  '${byte_status}' == 'PASS'
                Set To Dictionary    ${byte_history}    ${vm}=${byte_rate}
            END
            IF  '${entries_status}' == 'PASS'
                Set To Dictionary    ${entry_history}    ${vm}=${entries}
            END
            IF  '${entries_status}' == 'PASS' and '${byte_status}' == 'PASS' and (${entries} > ${vm_entry_limit} or ${byte_rate} > ${vm_byte_limit})
                ${recent_logs}       Run Command        journalctl -n ${saved_entries}
                Set To Dictionary    ${spam_logs}       ${vm}=${recent_logs}
                Set To Dictionary    ${spam_metrics}    ${vm}=Entries: ${entries}, Byterate: ${byte_rate}, Limit: ${vm_entry_limit}/${vm_byte_limit}
            ELSE IF  '${entries_status}' == 'PASS' and '${byte_status}' == 'PASS'
                Set To Dictionary    ${ok_metrics}      ${vm}=Entries: ${entries}, Byterate: ${byte_rate}, Limit: ${vm_entry_limit}/${vm_byte_limit}
            END
        END
    END

    ${ok_metrics_report}      Evaluate    '\\n'.join([f'{k}: {v}' for k, v in $ok_metrics.items()]) if $ok_metrics else 'None'
    ${spam_metrics_report}    Evaluate    '\\n'.join([f'{k}: {v}' for k, v in $spam_metrics.items()]) if $spam_metrics else 'None'
    Log                       VMs with acceptable logging rates:\n${ok_metrics_report}       console=True
    Log                       Log spamming detected in these VMs:\n${spam_metrics_report}    console=True

    ${has_unavailable_vms}    Run Keyword And Return Status    Should Not Be Empty    ${unavailable_vms}
    IF  ${has_unavailable_vms}
        Log                VMs not accessible during logging check:\n${unavailable_vms}    console=True
    END
    Save measurement history data    ${TEST NAME}    log_entries    entries/100s    &{entry_history}
    Save measurement history data    ${TEST NAME}    log_byte_rate    bytes/100s    &{byte_history}
    ${status}          Run Keyword And Return Status    Should Be Empty  ${spam_metrics}
    IF  not ${status}
        Log            Sample of ${saved_entries} log entries from VMs demonstrating too high logging rates
        FOR  ${vm}  ${logs}  IN  &{spam_logs}
            Log        ${vm}
            Log        ${logs}
        END
        FAIL           Too high logging rate detected\nmeas interval: ${check_interval}s\n${spam_metrics_report}
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

        IF  $status == ${False}
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
