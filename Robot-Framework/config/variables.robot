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

*** Keywords ***
Set Variables
    [Arguments]  ${device}

    ${config}=     Read Config
    Set Suite Variable  ${SERIAL_PORT}  ${config['addresses']['${DEVICE}']['serial_port']}
    Set Suite Variable  ${DEVICE_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['device_ip_address']}
    Set Suite Variable  ${SOCKET_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['socket_ip_address']}

Read Config
    [Arguments]  ${file_path}=../config/test_config.json

    ${file_data}=    OperatingSystem.Get File    ${file_path}
    TRY
        ${source_data}=    Evaluate    json.loads('''${file_data}''')    json
    EXCEPT
        FAIL    Couldn't parse test config ${file_path}
    END

    RETURN  ${source_data}
