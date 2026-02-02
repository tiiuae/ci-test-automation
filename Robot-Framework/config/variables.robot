# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library    OperatingSystem
Library    Process
Library    String


*** Variables ***

${BUILD_ID}               ${EMPTY}
${SWITCH_TOKEN}           ${EMPTY}
${SWITCH_SECRET}          ${EMPTY}
${TEST_WIFI_SSID}         ${EMPTY}
${TEST_WIFI_PSWD}         ${EMPTY}
${DEVICE_TYPE}            ${EMPTY}
${JOB}                    ${EMPTY}
${LOGIN}                  ghaf
${CONFIG_PATH}            ../config
${LOGGED_PARAMS_DIR}      ../../../logged_parameters/
${PERF_DATA_DIR}          ../../../Performance_test_results/
${PLOT_DIR}               ./
${REL_PLOT_DIR}           ./


*** Keywords ***

Set Variables
    [Arguments]  ${device}
    ${DIR_BODY}   ${DIR_END}     Split String From Right    ${OUTPUT_DIR}   /   1
    IF  $DIR_END != 'test-suites'
        Set Global Variable  ${LOGGED_PARAMS_DIR}  ${OUTPUT_DIR}/outputs/logged_parameters/
        Set Global Variable  ${PERF_DATA_DIR}  ${OUTPUT_DIR}/outputs/Performance_test_results/
        Set Global Variable  ${PLOT_DIR}  ${OUTPUT_DIR}/outputs/performance_plots/
        Set Global Variable  ${REL_PLOT_DIR}  ./outputs/performance_plots/
    END
    IF  $CONFIG_PATH == 'None'
        Log To Console    No path for test_config.json given. Ignore reading the config variables.
        Set Global Variable  ${RELAY_SERIAL_PORT}   NONE
    ELSE
        ${config}=     Read Config    ${CONFIG_PATH}/test_config.json
        Set Global Variable  ${SERIAL_PORT}        ${config['addresses']['${DEVICE}']['serial_port']}
        Set Global Variable  ${RELAY_SERIAL_PORT}  ${config['addresses']['relay_serial_port']}
        Set Global Variable  ${DEVICE_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['device_ip_address']}
        Set Global Variable  ${THREADS_NUMBER}     ${config['addresses']['${DEVICE}']['threads']}
        Run Keyword And Ignore Error    Set Global Variable  ${STATIC_DEVICE_ID}   ${config['addresses']['${DEVICE}']['device_id']}
        Run Keyword And Ignore Error    Set Global Variable  ${STATIC_NETVM_NAME}  ${config['addresses']['${DEVICE}']['netvm_hostname']}
        Run Keyword And Ignore Error    Set Global Variable  ${SOCKET_IP_ADDRESS}  ${config['addresses']['${DEVICE}']['socket_ip_address']}
        Run Keyword And Ignore Error    Set Global Variable  ${PLUG_TYPE}          ${config['addresses']['${DEVICE}']['plug_type']}
        Run Keyword And Ignore Error    Set Global Variable  ${SWITCH_BOT}         ${config['addresses']['${DEVICE}']['switch_bot']}
        Run Keyword And Ignore Error    Set Global Variable  ${RELAY_NUMBER}       ${config['addresses']['${DEVICE}']['relay_number']}
        Run Keyword And Ignore Error    Set Global Variable  ${RPI_IP_ADDRESS}     ${config['addresses']['measurement_agent']['device_ip_address']}
    END
    IF  "${DEVICE_TYPE}" == "lenovo-x1" or "${DEVICE_TYPE}" == "dell-7330" or "${DEVICE_TYPE}" == "darter-pro" or "${DEVICE_TYPE}" == "x1-sec-boot"
        Set Global Variable  ${IS_LAPTOP}           True
    ELSE
        Set Global Variable  ${IS_LAPTOP}           False
    END
    Set Global Variable  ${NET_VM}             net-vm
    Set Global Variable  ${NETVM_SERVICE}      microvm@${NET_VM}.service
    Set Global Variable  ${HOST}               ghaf-host
    Set Global Variable  ${ADMIN_VM}           admin-vm
    Set Global Variable  ${AUDIO_VM}           audio-vm
    Set Global Variable  ${BUSINESS_VM}        business-vm
    Set Global Variable  ${CHROME_VM}          chrome-vm
    Set Global Variable  ${COMMS_VM}           comms-vm
    Set Global Variable  ${DOCKER_VM}          docker-vm
    Set Global Variable  ${FLATPAK_VM}         flatpak-vm
    Set Global Variable  ${GUI_VM}             gui-vm
    Set Global Variable  ${ZATHURA_VM}         zathura-vm
    Set Global Variable  ${PERF_LOW_LIMIT}     1

    # Ghaf firewall rules allow max 60 pings per minute
    Set Global Variable  ${PING_SPACING}   1

    Set Log Level       NONE

    ${result} 	Run Process    sh    -c    cat /run/secrets/fleetdm_enroll_secret    shell=true
    Set Global Variable        ${FLEETDM_ENROLL_SECRET}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/fleetdm_api_token    shell=true
    Set Global Variable        ${FLEETDM_API_TOKEN}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/pi-login  shell=true
    Set Global Variable        ${LOGIN_PI}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/pi-pass  shell=true
    Set Global Variable        ${PASSWORD_PI}   ${result.stdout}
    ${result} 	Run Process    sh    -c    cat /run/secrets/dut-pass       shell=true
    IF  $result.stdout != '${EMPTY}'
        Set Global Variable        ${PASSWORD}         ${result.stdout}
    END
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
    ${result} 	Run Process    sh    -c    cat /etc/secrets/testuser       shell=true
    IF  $result.stdout != '${EMPTY}'
        Set Global Variable        ${USER_LOGIN}         ${result.stdout}
    ELSE
        Set Global Variable        ${USER_LOGIN}         testuser
    END
    ${result} 	Run Process    sh    -c    cat /etc/secrets/testpw         shell=true
    IF  $result.stdout != '${EMPTY}'
        Set Global Variable        ${USER_PASSWORD}      ${result.stdout}
    ELSE
        Set Global Variable        ${USER_PASSWORD}      testpw
    END

    Set Log Level       INFO

    IF  $BUILD_ID != '${EMPTY}'
        ${config}=     Read Config  ${CONFIG_PATH}/${BUILD_ID}.json
        Set Global Variable    ${JOB}    ${config['Job']}
    ELSE
        IF  $JOB == '${EMPTY}'
            Set Global Variable    ${JOB}    dummy_job
        END
    END

    Set Global Variable  ${GRAFANA_LOGS}    https://loki.ghaflogs.vedenemo.dev

Read Config
    [Arguments]  ${file_path}

    ${file_data}=    OperatingSystem.Get File    ${file_path}
    TRY
        ${source_data}=    Evaluate    json.loads('''${file_data}''')    json
    EXCEPT
        FAIL    Couldn't parse test config ${file_path}
    END

    RETURN  ${source_data}
