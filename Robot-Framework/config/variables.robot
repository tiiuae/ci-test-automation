*** Variables ***
${DEVICE}  ${DEVICE}
${LOGIN}   ${EMPTY}
${PASSWORD}   ${EMPTY}

${SERIAL_PORT}  ${EMPTY}
${DEVICE_IP_ADDRESS}  ${EMPTY}
${SOCKET_IP_ADDRESS}  ${EMPTY}

*** Keywords ***
Set Device Variables
    [Arguments]  ${device}
    Run Keyword If  '${device}' == 'NUC'
    ...   Run Keywords
    ...   Set Suite Variable  ${SERIAL_PORT}  /dev/ttyUSB0
    ...   AND   Set Suite Variable  ${DEVICE_IP_ADDRESS}  127.0.0.1   # for future
#    ...   AND   Set Suite Variable  ${SOCKET_IP_ADDRESS}  172.18.16.30
    Run Keyword If  '${device}' == 'ORIN'
    ...   Run Keywords
    ...   Set Suite Variable  ${SERIAL_PORT}  /dev/ttyACM0
    ...   AND   Set Suite Variable  ${DEVICE_IP_ADDRESS}  172.18.8.115   # for future
#    ...   AND   Set Suite Variable  ${SOCKET_IP_ADDRESS}  172.18.16.31