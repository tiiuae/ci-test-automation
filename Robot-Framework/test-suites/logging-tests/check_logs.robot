# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
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
${virtual_machine}  \${vm}
${ta_wifi_ssid}    TII-Testautomation
${netvm_ssh}       ${EMPTY}


*** Test Cases ***
Check Grafana logs
    [Documentation]  Check that all virtual machines are sending logs to Grafana
    [Tags]  SP-T182
    [Setup]  Connect to netvm
    [Teardown]  Remove Wifi configuration
    Configure wifi      ${netvm_ssh}  ${ta_wifi_ssid}  ${TA_WIFI_PSWD}  lenovo=True
    Check Internet Connection
    Connect to ghaf host
    ${mac}  Execute Command  cat /var/lib/private/alloy/MACAddress  sudo=True  sudo_password=${PASSWORD}
    ${username}  Set Variable  --username="${TA_USERNAME}"
    ${pw}  Set Variable  --password="${TA_PSWD}"
    ${addr}  Set Variable  --addr="${GRAFANA_LOGS}"
    ${date}  DateTime.Get Current Date  result_format=%Y-%m-%d
    ${logcli_cmd}  Set Variable  logcli query ${addr} ${pw} ${username} '{systemdJournalLogs="${mac}", nodename="${virtual_machine}"}'
    Wait Until Keyword Succeeds  100s  2s  Check Logs Are available  ${logcli_cmd}  ${date}

*** Keywords ***
Check Internet Connection
    [Documentation]  Check that DUT is able to connect to internet
    ${output}  Execute Command  ping -c1 google.com
    Should Contain   ${output}    1 received

Check Logs Are available
    [Documentation]  Check that virtual machine's logs are available in Grafana
    [Arguments]  ${logcli_cmd}  ${date}

    FOR  ${vm}  IN  @{VMS}
        ${cmd}  Replace Variables  ${logcli_cmd}
        ${out}  Run  ${cmd}
        Log  ${out}
        Run Keyword And Continue On Failure  Should Contain  ${out}  ${date}
    END
