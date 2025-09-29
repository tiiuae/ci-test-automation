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

Check Grafana logs
    [Documentation]  Check that all virtual machines are sending logs to Grafana
    [Tags]           SP-T172
    Check Internet Connection
    Switch to vm    ${ADMIN_VM}
    ${id}           Execute Command  cat /etc/common/device-id  sudo=True  sudo_password=${PASSWORD}
    ${date}          DateTime.Get Current Date  result_format=%Y-%m-%d
    Wait Until Keyword Succeeds  60s  2s  Check Logs Are available  ${date}  ${id}


*** Keywords ***
Check Internet Connection
    [Documentation]  Check that DUT is able to connect to internet
    ${output}          Execute Command  ping -c1 google.com
    Should Contain     ${output}    1 received

Check Logs Are available
    [Documentation]  Check that virtual machine's logs are available in Grafana
    [Arguments]  ${date}  ${id}
    FOR  ${vm}  IN  @{VMS}
        Set Log Level  NONE
        ${out}         Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" '{machine="${id}", host="${vm}"}'
        Set Log Level  INFO
        Log            ${out}
        Run Keyword And Continue On Failure  Should Contain  ${out}  ${date}
        Run Keyword And Continue On Failure  Should Not Contain  ${out}  Query failed
    END
