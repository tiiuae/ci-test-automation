# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/ParseMeasurementData.py    ${LOGGED_PARAMS_DIR}    ${PLOT_DIR}
Library             DateTime
Library             SSHLibrary
Resource            ../resources/common_keywords.resource
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Variables ***
${SSH_MEASUREMENT}        ${EMPTY}
${RPI_IP_ADDRESS}         ${EMPTY}
${DATA_PROCESS_ERROR}     ${False}


*** Keywords ***

Start power measurement
    [Documentation]    Connect to the measurement agent and run script to start collecting measurement results
    [Arguments]        ${id}=power_data   ${timeout}=200
    ${availability}            Check variable availability  RPI_IP_ADDRESS
    Set Global Variable        ${SSH_MEASUREMENT}  ${EMPTY}
    IF  ${availability}==False
        Log To Console    Power measurement agent IP address not defined. Ignoring all power measurement related keywords.
        RETURN
    ELSE IF    "${DEVICE_TYPE}" == "x1-sec-boot"
        Log To Console    Power measurement is not av available for Secure Boot Lenovo X1. Ignoring all power measurement related keywords.
        RETURN
    END
    ${status}  ${connection}   Run Keyword And Ignore Error   Connect to measurement agent
    IF  '${status}'!='PASS'
        Set Global Variable   ${SSH_MEASUREMENT}  ${EMPTY}
        Log To Console        Power measurement agent not found. Ignoring all power measurement related keywords.
        RETURN
    END
    # Multiple logging processes not allowed (for now)
    Stop recording power
    Start recording power      ${id}  ${timeout}
    Set timestamp              power_meas_start

Connect to measurement agent
    [Documentation]         Set up SSH connection to the measurement agent
    [Arguments]             ${IP}=${RPI_IP_ADDRESS}    ${PORT}=22    ${target_output}=ghaf@raspberrypi
    Log To Console          Connecting to measurement agent
    ${connection}=          Open Connection    ${IP}    port=${PORT}    prompt=\$    timeout=15
    ${output}=              Login     username=${LOGIN_PI}    password=${PASSWORD_PI}
    Should Contain          ${output}    ${target_output}
    Set Global Variable     ${SSH_MEASUREMENT}    ${connection}
    RETURN                  ${SSH_MEASUREMENT}

Start recording power
    [Arguments]       ${file_name}   ${timeout}
    Log To Console    Starting to record power measurements
    Run Keyword And Ignore Error  Execute Command   nohup python /home/ghaf/ghaf/ghaf-power-measurement/measure_power.py ${file_name}.csv ${timeout} > output.log 2>&1 &  timeout=3

Stop recording power
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    Log To Console    Stopping power recording
    Run Keyword And Ignore Error  Execute Command   pkill python  timeout=3

Get power record
    [Arguments]       ${file_name}=power_data.csv
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console            No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    Run Keyword And Ignore Error  Connect to measurement agent
    Run Keyword And Ignore Error  SSHLibrary.Get File           /home/ghaf/ghaf/power_data/${file_name}  ${LOGGED_PARAMS_DIR}

Save measurement interval
    [Documentation]   Extract measurement data within given time interval
    [Arguments]       ${file_name}   ${start_time}   ${end_time}   ${output_filename}  ${check_freq}=${False}  ${divider}=1
    Log To Console    Extract data from given time interval
    ${time_interval}  DateTime.Subtract Date From Date  ${end_time}  ${start_time}  exclude_millis=True
    IF  ${time_interval} < 0
        Log To Console    Invalid timestamp criteria for extracting data
        RETURN
    END
    ${keyword_status}  ${return_value}  Run Keyword And Ignore Error  Extract time interval  ${file_name}  ${start_time}  ${end_time}  ${output_filename}  ${check_freq}  ${divider}
    IF  $keyword_status=='FAIL'
        Set Suite Variable   ${DATA_PROCESS_ERROR}   ${True}
    END

Generate power plot
    [Documentation]   Extract power data from start timestamp to current time.
    ...               Plot power vs time and save to png file.
    [Arguments]       ${id}   ${test_name}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    ${end_timestamp}            Get current timestamp
    Get power record            ${id}.csv
    Save measurement interval   ${id}.csv  '${power_meas_start}'  '${end_timestamp}'  power_interval.csv  ${True}
    IF  ${DATA_PROCESS_ERROR}
        Log To Console          Data processing error. Aborting plot generation.
        RETURN
    END
    Generate power graph        power_interval.csv  ${test_name}
    Log                         <img src="${REL_PLOT_DIR}power_${test_name}.png" alt="Power plot" width="1200">    HTML

Set timestamp
    [Arguments]          ${timestamp_variable_name}
    ${current_time}      DateTime.Get Current Date   UTC  exclude_millis=yes
    Set Global Variable  ${${timestamp_variable_name}}    ${current_time}
    Log                  Setting timestamp ${timestamp_variable_name}: ${${timestamp_variable_name}}    console=True

Get current timestamp
    ${current_time}   DateTime.Get Current Date  UTC  exclude_millis=yes
    RETURN            ${current_time}

Check power during suspension
    [Arguments]       ${id}  ${max_power}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN  ${False}
    END
    Save measurement interval   ${id}.csv  '${suspend_start}'  '${suspend_end}'  suspend_interval.csv  ${False}
    ${max_power_during_suspension}  Measured max power    suspend_interval.csv
    IF   ${max_power_during_suspension} > ${max_power}
        RETURN  ${max_power_during_suspension}
        FAIL    Power consumption exceptionally high during suspension
    END
    RETURN  ${False}

Calculate average power over interval
    [Arguments]      ${id}  ${start_time}  ${end_time}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    Save measurement interval   ${id}.csv  '${start_time}'  '${end_time}'  temp_interval.csv  ${False}
    ${keyword_status}   ${mean_P}     Run Keyword And Ignore Error  Mean power   temp_interval.csv
    RETURN              ${mean_P}

Measure power level change
    [Documentation]   Check that power consumption has not increased between ref and check intervals
    ...               more than max_relative_change given in %
    [Arguments]      ${id}  ${max_relative_change}  ${ref_power_start}  ${ref_power_end}  ${check_power_start}  ${check_power_end}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN  ${False}
    END
    ${power_before_suspension}  Calculate average power over interval   ${id}  ${ref_power_start}    ${ref_power_end}
    ${power_after_suspension}   Calculate average power over interval   ${id}  ${check_power_start}  ${check_power_end}
    ${relative_change}          Evaluate    int((${power_after_suspension} - ${power_before_suspension}) / ${power_before_suspension} * 100)
    IF   ${relative_change} > ${max_relative_change}
        RETURN  ${relative_change}
    END
    RETURN  ${False}

Start BAT0 power logging
    [Arguments]               ${timeout}=180
    Start parameter logging   ${HOST}   bat0_power_logger   5   ${timeout}

Plot BAT0 power log
    Plot parameter log      ${HOST}  power  mW  bat0_power_logger  1000

Start parameter logging
    [Documentation]         Keyword for logging any parameter in given vm on the target device.
    ...                     The actual commands for extracting desired parameters are defined in test-files/log_params
    [Arguments]             ${vm}   ${script}=log_params   ${log_interval}=1   ${timeout}=300
    Switch to vm                    ${vm}
    Kill process by name            ${script}   True   ${False}
    Transfer Shell Script To DUT    ../test-files   ${script}   /tmp
    Log                             Launching ${script} script in ${vm}     console=True
    Set timestamp                   ${script}_log_start
    ${command}                      Set Variable    /tmp/${script} /tmp/${script}.csv ${log_interval} ${timeout}
    Execute Command                 nohup ${command} > /tmp/output.log 2>&1 &

Plot parameter log
    [Documentation]   Extract power data from start timestamp to current time.
    ...               Plot parameter vs time and save to png file.
    [Arguments]                  ${vm}  ${param_label}  ${param_unit}  ${script}=log_params  ${divider}=1
    Switch to vm                 ${vm}
    Kill process by name         ${script}   True   ${False}
    SSHLibrary.Get file          /tmp/${script}.csv   ${LOGGED_PARAMS_DIR}/${script}.csv
    ${end_timestamp}             Get current timestamp
    Save measurement interval    ${script}.csv  '${${script}_log_start}'  '${end_timestamp}'  ${script}_interval.csv  ${False}  ${divider}
    IF  ${DATA_PROCESS_ERROR}
        Log To Console           Data processing error. Aborting plot generation.
        RETURN
    END
    Generate param graph         ${script}_interval.csv  ${param_label}  ${param_unit}  ${BUILD_ID}
    Log                          <img src="${PLOT_DIR}${param_label}_${BUILD_ID}.png" alt="Stats plot" width="1200">    HTML
