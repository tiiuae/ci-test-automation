# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library    OperatingSystem


*** Variables ***

${BUILD_ID}        ${EMPTY}
${SWITCH_TOKEN}    ${EMPTY}
${SWITCH_SECRET}   ${EMPTY}
${TEST_WIFI_SSID}  ${EMPTY}
${TEST_WIFI_PSWD}  ${EMPTY}
${DEVICE_TYPE}     ${EMPTY}
${LOGIN}           ghaf


*** Keywords ***

Set Variables
    [Arguments]  ${device}

    ${config}=     Read Config
    Set Global Variable  ${SERIAL_PORT}        ${config['addresses']['${DEVICE}']['serial_port']}
    Set Global Variable  ${RELAY_SERIAL_PORT}  ${config['addresses']['relay_serial_port']}
    Set Global Variable  ${DEVICE_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['device_ip_address']}
    Set Global Variable  ${SOCKET_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['socket_ip_address']}
    Set Global Variable  ${PLUG_TYPE}          ${config['addresses']['${DEVICE}']['plug_type']}
    Set Global Variable  ${THREADS_NUMBER}     ${config['addresses']['${DEVICE}']['threads']}
    Set Global Variable  ${SWITCH_BOT}         ${config['addresses']['${DEVICE}']['switch_bot']}
    Set Global Variable  ${NETVM_NAME}         net-vm
    Set Global Variable  ${CHROMIUM_VM_NAME}   chromium-vm
    Set Global Variable  ${GUI_VM_NAME}        gui-vm
    Set Global Variable  ${ZATHURA_VM_NAME}    zathura-vm
    Set Global Variable  ${GALA_VM_NAME}       gala-vm
    Set Global Variable  ${NETVM_SERVICE}      microvm@${NETVM_NAME}.service
    Set Global Variable  ${NETVM_IP}           192.168.101.1
    Set Global Variable  ${GUI_VM}             gui-vm
    Set Global Variable  ${CHROME_VM}          chrome-vm
    Set Global Variable  ${GALA_VM}            gala-vm
    Set Global Variable  ${ZATHURA_VM}         zathura-vm
    Set Global Variable  ${COMMS_VM}           comms-vm
    Set Global Variable  ${APPFLOWY_VM}        appflowy-vm
    Set Global Variable  ${BUSINESS_VM}        business-vm
    Set Global Variable  ${ADMIN_VM}           admin-vm
    Set Global Variable  @{VMS}                ${GUI_VM}  ${CHROME_VM}  ${GALA_VM}  ${ZATHURA_VM}  ${COMMS_VM}  ${BUSINESS_VM}  ${ADMIN_VM}
    Run Keyword And Ignore Error    Set Global Variable  ${RELAY_NUMBER}      ${config['addresses']['${DEVICE}']['relay_number']}

    Set Log Level       NONE


    Run Keyword And Ignore Error    Set Global Variable  ${RPI_IP_ADDRESS}    ${config['addresses']['measurement_agent']['device_ip_address']}
    ${result} 	Run Process    sh    -c    cat /run/secrets/pi-login  shell=true
    Set Global Variable        ${LOGIN_PI}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/pi-pass  shell=true
    Set Global Variable        ${PASSWORD_PI}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/dut-pass       shell=true
    Set Global Variable        ${PASSWORD}         ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/plug-login     shell=true
    Set Global Variable        ${PLUG_USERNAME}    ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/plug-pass      shell=true
    Set Global Variable        ${PLUG_PASSWORD}    ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/switch-token   shell=true
    Set Global Variable        ${SWITCH_TOKEN}     ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/switch-secret  shell=true
    Set Global Variable        ${SWITCH_SECRET}    ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/wifi-ssid      shell=true
    Set Global Variable        ${TEST_WIFI_SSID}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/wifi-password  shell=true
    Set Global Variable        ${TEST_WIFI_PSWD}   ${result.stdout}
    Set Global Variable        ${USER_LOGIN}       testuser
    Set Global Variable        ${USER_PASSWORD}    testpw

    Set Log Level       INFO

    IF  $BUILD_ID != '${EMPTY}'
        ${config}=     Read Config  ../config/${BUILD_ID}.json
        Set Global Variable    ${JOB}    ${config['Job']}
    END


Read Config
    [Arguments]  ${file_path}=../config/test_config.json

    ${file_data}=    OperatingSystem.Get File    ${file_path}
    TRY
        ${source_data}=    Evaluate    json.loads('''${file_data}''')    json
    EXCEPT
        FAIL    Couldn't parse test config ${file_path}
    END

    RETURN  ${source_data}
