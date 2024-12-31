# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing logging
Force Tags          logging  lenovo-x1
Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/connection_keywords.resource
Library             DateTime
Suite Setup         Set Variables   ${DEVICE}
Suite Teardown      Close All Connections


*** Variables ***
${NETVM_SSH}          ${EMPTY}
${GRAFANA_LOGS}       https://loki.ghaflogs.vedenemo.dev


*** Test Cases ***
Check Grafana logs
    [Documentation]  Check that all virtual machines are sending logs to Grafana
    [Tags]           SP-T172
    [Setup]          Connect to netvm
    [Teardown]       Remove Wifi configuration  ${TEST_WIFI_SSID}
    Configure wifi   ${NETVM_SSH}  ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Check Internet Connection
    Connect to ghaf host
    ${mac}           Execute Command  cat /var/lib/private/alloy/MACAddress  sudo=True  sudo_password=${PASSWORD}
    ${date}          DateTime.Get Current Date  result_format=%Y-%m-%d
    Wait Until Keyword Succeeds  60s  2s  Check Logs Are available  ${date}  ${mac}


*** Keywords ***
Check Internet Connection
    [Documentation]  Check that DUT is able to connect to internet
    ${output}          Execute Command  ping -c1 google.com
    Should Contain     ${output}    1 received

Check Logs Are available
    [Documentation]  Check that virtual machine's logs are available in Grafana
    [Arguments]  ${date}  ${mac}
    FOR  ${vm}  IN  @{VMS}
        Set Log Level  NONE
        ${out}         Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" '{systemdJournalLogs="${mac}", nodename="${vm}"}'
        Set Log Level  INFO
        Log            ${out}
        Run Keyword And Continue On Failure  Should Contain  ${out}  ${date}
        Run Keyword And Continue On Failure  Should Not Contain  ${out}  Query failed
    END
