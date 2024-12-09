# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Library             ../lib/parse_power_data.py
Library             SSHLibrary
Library             DateTime

*** Variables ***
${SSH_MEASUREMENT}        ${EMPTY}
${start_timestamp}        ${EMPTY}
${RPI_IP_ADDRESS}         ${EMPTY}


*** Keywords ***

Check variable availability
    ${value}=    Get Variable Value    ${RPI_IP_ADDRESS}
    IF  $value!='${EMPTY}'
        RETURN  ${True}
    ELSE
        RETURN  ${False}
    END

Start power measurement
    [Documentation]    Connect to the measurement agent and run script to start collecting measurement results
    [Arguments]        ${id}=power_data   ${timeout}=200
    ${availability}            Check variable availability
    IF  ${availability}==False
        Log To Console    Power measurement agent IP address not defined. Ignoring all power measurement related keywords.
        Set Global Variable   ${SSH_MEASUREMENT}  ${EMPTY}
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

Connect to measurement agent
    [Documentation]         Set up SSH connection to the measurement agent
    [Arguments]             ${IP}=${RPI_IP_ADDRESS}    ${PORT}=22    ${target_output}=ghaf@raspberrypi
    # Use existing connection if available
    ${status}  ${output}    Run Keyword And Ignore Error  Switch Connection       ${SSH_MEASUREMENT}
    IF  '${status}'=='PASS'
        Log To Console          Switched connection to measurement agent.
        Set Global Variable     ${SSH_MEASUREMENT}  ${SSH_MEASUREMENT}
        RETURN                  ${SSH_MEASUREMENT}
    END
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
    Run Keyword And Ignore Error  SSHLibrary.Get File           /home/ghaf/ghaf/power_data/${file_name}  ../../../power_measurements/

Save power measurement interval
    [Documentation]   Extract measurement data within given time interval
    [Arguments]       ${file_name}   ${start_time}   ${end_time}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    Log To Console    Extract power data from given time interval
    ${time_interval}  DateTime.Subtract Date From Date  ${end_time}  ${start_time}    exclude_millis=True
    IF  ${time_interval} < 0
        Log To Console    Invalid timestamp critera for extracting power data
        RETURN
    END
    Run Keyword And Ignore Error    Extract time interval   ../../../power_measurements/${file_name}  ${start_time}   ${end_time}

Generate power plot
    [Documentation]   Extract power data from start_timestamp to current time.
    ...               Plot power vs time and save to png file.
    [Arguments]       ${id}   ${test_name}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    ${end_timestamp}                  Get current timestamp
    Run Keyword And Ignore Error      Connect to measurement agent
    Run Keyword And Ignore Error      Get power record    ${id}.csv
    Run Keyword And Ignore Error      Save power measurement interval   ${id}.csv  '${start_timestamp}'  '${end_timestamp}'
    Run Keyword And Ignore Error      Generate graph    power_interval.csv  ${test_name}
    Run Keyword And Ignore Error      Log   <img src="power_test.png" alt="Power plot" width="1200">    HTML

Set start timestamp
    ${current_time}   DateTime.Get Current Date  exclude_millis=yes
    Set Global Variable  ${start_timestamp}    ${current_time}
    Log To Console       ${start_timestamp}

Get current timestamp
    ${current_time}   DateTime.Get Current Date  exclude_millis=yes
    RETURN            ${current_time}

Log average power
    [Arguments]       ${file_name}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        Log To Console    No connection to power measurement device. Ignoring all power measurement related keywords.
        RETURN
    END
    ${keyword_status}   ${mean_P}     Run Keyword And Ignore Error  Mean power  ${file_name}
    # TODO: With the statistics tools of performance testing also average power values could be plotted and monitored
