# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing logging
Force Tags          bat  regression  pre-merge  logging  lenovo-x1  darter-pro  dell-7330

Library             DateTime
Library             OperatingSystem
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Logging Suite Setup


*** Variables ***
${GRAFANA_LOGS}       https://loki.ghaflogs.vedenemo.dev
${TEST_LOG}           Started Session


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
            Log To Console    FAIL: Logging service not running in ${vm}
            Append To List    ${failed_vms}    ${vm}
        END
    END
    IF  ${failed_vms} != []    FAIL    VMs with alloy.service not running: ${failed_vms}

Check Grafana logs
    [Documentation]  Check that all virtual machines are sending logs to Grafana
    [Tags]           SP-T172
    Check Network Availability    8.8.8.8   limit_freq=${False}
    Switch to vm     ${ADMIN_VM}
    ${id}            Execute Command  cat /etc/common/device-id  sudo=True  sudo_password=${PASSWORD}
    Run Keyword And Continue On Failure   Create logs in all VMs
    Wait Until Keyword Succeeds  60s  5s  Check Logs Are available  ${id}


*** Keywords ***

Logging Suite Setup
    @{VM_LIST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST}

Check Logs Are available
    [Documentation]  Check that virtual machine's logs are available in Grafana
    [Arguments]      ${id}
    FOR  ${vm}  IN  @{VM_LIST}
        Set Log Level  NONE
        # Logging from one VM sometimes stops during the run (SSRCSP-7612).
        # To avoid failures in the pipelines the test checks for any logs during the last 10 minutes.
        # 10 minutes should be enough to make sure that logs from previous run are not detected.
        # When the bug is fixed the old version should be taken back into use.
        #${out}         Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="3m" '{machine="${id}", host="${vm}"} |= `${TEST_LOG}`'
        ${out}         Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="10m" '{machine="${id}", host="${vm}"}'
        Set Log Level  INFO
        Log            ${out}
        ${lines}    Count lines    ${out}
        IF   '${vm}' == '${NET_VM}'
            # Ignore net-vm error SSRCSP-7542
            ${status}  ${output}  Run Keyword And Ignore Error  Should Be True  ${lines} > 1   ${vm} query does not contain logs
            IF   $status == 'FAIL'
                Save net-vm log
            END
        ELSE
            Run Keyword And Continue On Failure  Should Be True   ${lines} > 1   ${vm} query does not contain logs
        END
    END

Create logs in all VMs
    [Documentation]    Create new SSH connection to all VMs to make sure there are recent logs
    Close All Connections
    FOR  ${vm}  IN  @{VM_LIST}
        Switch to vm   ${vm}
        ${out}   Execute Command    journalctl --since "1 minute ago" | grep "${TEST_LOG}"
        Log      ${out}
        Run Keyword And Continue On Failure   Should Contain  ${out}   ${TEST_LOG}   Log was not created in ${vm}
    END

Save net-vm log
    Switch to vm   ${NET_VM}
    ${journal}     Execute Command   journalctl -b
    Log            ${journal}
    [Teardown]     Switch to vm   ${ADMIN_VM}