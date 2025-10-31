# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing logging
Force Tags          bat  regression  pre-merge  logging  lenovo-x1  darter-pro  dell-7330

Library             DateTime
Library             OperatingSystem
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Switch to vm   ${NET_VM}


*** Variables ***
${GRAFANA_LOGS}       https://loki.ghaflogs.vedenemo.dev


*** Test Cases ***

Logging service is running in all VMs
    [Documentation]    Check that logging service is running in every VM
    [Tags]             SP-T333
    ${failed_vms}      Create List
    @{vm_list}         Get VM list    with_host=True
    FOR  ${vm}  IN  @{vm_list}
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
    ${date}          DateTime.Get Current Date  result_format=%Y-%m-%d
    Wait Until Keyword Succeeds  60s  5s  Check Logs Are available  ${date}  ${id}


*** Keywords ***

Check Logs Are available
    [Documentation]  Check that virtual machine's logs are available in Grafana
    [Arguments]  ${date}  ${id}
    @{vm_list}         Get VM list    with_host=True
    FOR  ${vm}  IN  @{vm_list}
        Set Log Level  NONE
        ${out}         Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" '{machine="${id}", host="${vm}"}'
        Set Log Level  INFO
        Log            ${out}
        Run Keyword And Continue On Failure  Should Contain  ${out}  ${date}
        Run Keyword And Continue On Failure  Should Not Contain  ${out}  Query failed
    END
