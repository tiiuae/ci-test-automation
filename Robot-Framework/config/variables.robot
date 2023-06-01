# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library    OperatingSystem

*** Variables ***
${DEVICE}  ${DEVICE}

${SERIAL_PORT}        ${EMPTY}
${DEVICE_IP_ADDRESS}  ${EMPTY}
${SOCKET_IP_ADDRESS}  ${EMPTY}
${LOGIN}              ${EMPTY}
${PASSWORD}           ${EMPTY}
${PLUG_USERNAME}      ${EMPTY}
${PLUG_PASSWORD}      ${EMPTY}
${netvm_service}      ${EMPTY}

*** Keywords ***
Set Variables
    [Arguments]  ${device}

    ${config}=     Read Config
    Set Global Variable  ${SERIAL_PORT}        ${config['addresses']['${DEVICE}']['serial_port']}
    Set Global Variable  ${DEVICE_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['device_ip_address']}
    Set Global Variable  ${SOCKET_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['socket_ip_address']}
    ${nuc_in_variable}   Run Keyword And Return Status    Should Contain    ${DEVICE}   NUC
    ${orin_in_variable}  Run Keyword And Return Status    Should Contain    ${DEVICE}   ORIN
    Run Keyword If       ${nuc_in_variable}    Set Global Variable   ${netvm_service}   microvm@netvm-generic-x86_64-debug.service
    Run Keyword If       ${orin_in_variable}   Set Global Variable   ${netvm_service}   microvm@netvm-nvidia-jetson-orin-debug.service


Read Config
    [Arguments]  ${file_path}=../config/test_config.json

    ${file_data}=    OperatingSystem.Get File    ${file_path}
    TRY
        ${source_data}=    Evaluate    json.loads('''${file_data}''')    json
    EXCEPT
        FAIL    Couldn't parse test config ${file_path}
    END

    RETURN  ${source_data}
