*** Settings ***
Library    OperatingSystem

*** Variables ***
${DEVICE}  ${DEVICE}

${SERIAL_PORT}  ${EMPTY}
${DEVICE_IP_ADDRESS}  ${EMPTY}
${SOCKET_IP_ADDRESS}  ${EMPTY}
${PLUG_USERNAME}  ${EMPTY}
${PLUG_PASSWORD}  ${EMPTY}

*** Keywords ***
Set Variables
    [Arguments]  ${device}

    ${config}=     Read Config
    Set Suite Variable  ${SERIAL_PORT}  ${config['addresses']['${DEVICE}']['serial_port']}
    Set Suite Variable  ${DEVICE_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['device_ip_address']}
    Set Suite Variable  ${SOCKET_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['socket_ip_address']}

    Set Suite Variable  ${LOGIN}   ${config['credentials']['device']['login']}
    Set Suite Variable  ${PASSWORD}   ${config['credentials']['device']['password']}

    Set Suite Variable  ${PLUG_USERNAME}   ${config['credentials']['plug']['login']}
    Set Suite Variable  ${PLUG_PASSWORD}   ${config['credentials']['plug']['password']}

Read Config
    [Arguments]  ${file_path}=Robot-Framework/config/test_config.json

    ${file_data}=    OperatingSystem.Get File    ${file_path}
    ${source_data}=    Evaluate    json.loads('''${file_data}''')    json

    RETURN  ${source_data}