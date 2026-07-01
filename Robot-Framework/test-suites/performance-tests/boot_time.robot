# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device bootup time.
Test Tags           boot-time

Resource            ../../config/variables.robot
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             DateTime
Library             Collections
Resource            ../../resources/device_control.resource
Resource            ../../resources/measurement_keywords.resource
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Variables           ../../lib/performance_thresholds.py

Suite Teardown      Close All Connections
Test Teardown       Boot Time Test Teardown

*** Variables ***
${PING_TIMEOUT}            180
${SEARCH_TIMEOUT}          60
${SHUTDOWN_POWER_LIMIT}    100


*** Test Cases ***

Measure Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]           SP-T187  SP-T187-1  lenovo-x1  dell-7330
    Soft Reboot Device
    Get Boot times

Measure Shutdown Time
    [Documentation]  Measure how long it takes to device to shut down with software shutdown
    [Tags]           SP-T83  SP-T83-1  lenovo-x1  dell-7330  lab-only
    Get Shutdown Time
    [Teardown]       Shutdown Time Teardown

Measure Shutdown Time By Power
    [Documentation]  Measure Lenovo-X1 shutdown time until power drops below ${SHUTDOWN_POWER_LIMIT}mW
    [Tags]           SP-T83  SP-T83-2  lenovo-x1  lab-only
    Get Shutdown Time By Power
    [Teardown]       Shutdown Time Teardown

Measure Hard Boot Time
    [Documentation]  Measure how long it takes to device to boot up with hard reboot
    [Tags]           SP-T182  SP-T182-1  lenovo-x1  darter-pro  dell-7330  lab-only
    Reboot Laptop
    Get Boot times                plot_name=Hard Boot Times

Measure Orin Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]           SP-T187  SP-T187-2  orin-agx  orin-agx-64  orin-nx
    Soft Reboot Device
    Get Time To Ping

Measure Orin Shutdown Time
    [Documentation]  Measure how long it takes to device to shut down with software shutdown
    [Tags]           SP-T83  SP-T83-1  orin-agx  orin-agx-64  orin-nx  lab-only
    Get Shutdown Time
    [Teardown]       Shutdown Time Teardown

Measure Orin Hard Boot Time
    [Documentation]  Measure how long it takes to device to boot up with hard reboot
    [Tags]           SP-T182  SP-T182-2  orin-agx  orin-agx-64  orin-nx  lab-only
    Log To Console                Shutting down by switching the power off
    Turn Off Power
    Wait Until Device Is Down     power_off=${True}
    Close All Connections
    Log To Console                The device has shut down
    Log To Console                Booting the device by switching the power on
    Turn On Power
    Get Time To Ping              plot_name=Hard Boot Times


*** Keywords ***

Measure Time To Ping
    [Arguments]               ${start_time}
    ${ping_response}          Set Variable  ${EMPTY}
    Log To Console            Start checking ping response
    ${ping_end_time}          Set Variable  False
    WHILE  not $ping_response   limit=${PING_TIMEOUT} seconds
        # Pinging every 3 sec will limit resolution of the measurement to 3s but faster pinging might trigger ghaf firewall rule.
        # Better option could be using arping if that is not limited.
        ${ping_response}      Ping Host  ${DEVICE_IP_ADDRESS}  3
        IF  $ping_response
            ${ping_end_time}  DateTime.Get Current Date  result_format=epoch
            Sleep             ${PING_SPACING}
        END
    END
    IF  not $ping_end_time
        FAIL                  No response to ping within ${PING_TIMEOUT}
    END
    ${ping_response_seconds}  DateTime.Subtract Date From Date  ${ping_end_time}  ${start_time}   exclude_millis=True
    Log                       Response time to ping measured: ${ping_response_seconds}   console=True
    RETURN                    ${ping_response_seconds}

Get Time To Ping
    [Arguments]  ${plot_name}=Soft Boot Times
    ${start_time_epoch}           DateTime.Get Current Date   result_format=epoch
    ${ping_response_seconds}      Measure Time To Ping  ${start_time_epoch}
    &{final_results}              Create Dictionary
    Set To Dictionary             ${final_results}  response_to_ping  ${ping_response_seconds}
    Check Result Validity         ${final_results}
    &{statistics}                 Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    Determine Test Status         ${statistics}  inverted=1

Get Shutdown Time
    [Arguments]  ${plot_name}=Shutdown Times
    ${status}                     Open Serial Port    timeout=10
    IF  not ${status}
        Skip    Failed to connect via serial
    END
    Soft Shutdown Device
    ${start_time_epoch}           DateTime.Get Current Date   result_format=epoch
    ${shutdown_time_epoch}  ${verified_via_serial}    Verify shutdown via serial    open_serial_port=${False}
    ${shutdown_time}              Evaluate    int(${shutdown_time_epoch}) - int(${start_time_epoch})
    Log                           Shutdown time measured: ${shutdown_time}   console=True
    IF  not ${verified_via_serial}
        SKIP    Shutdown time verification via serial failed, fell back to 'Verify shutdown via network' which is not accurate.\nSkipping the test.
    END
    &{final_results}              Create Dictionary
    Set To Dictionary             ${final_results}  shutdown_time  ${shutdown_time}
    Check Result Validity         ${final_results}
    &{statistics}                 Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    Determine Test Status         ${statistics}  inverted=1

Get Shutdown Time By Power
    [Arguments]  ${plot_name}=Shutdown Times
    ${availability}              Check variable availability  RPI_IP_ADDRESS
    IF  ${availability}==False
        SKIP    Power measurement agent IP address not defined. Skipping the test
    END
    Start power measurement       ${BUILD_ID}_${TEST NAME}   timeout=300
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        SKIP    Failed to connect to power measurement agent. Skipping the test
    END
    Soft Shutdown Device
    ${start_time_epoch}           DateTime.Get Current Date   result_format=epoch
    ${shutdown_time_epoch}        Wait Until Power Is Low     ${BUILD_ID}_${TEST NAME}
    ${shutdown_time}              Evaluate
    ...                           int(${shutdown_time_epoch}) - int(${start_time_epoch})
    Log                           Shutdown time measured: ${shutdown_time}   console=True
    &{final_results}              Create Dictionary
    Set To Dictionary             ${final_results}  shutdown_time  ${shutdown_time}
    Check Result Validity         ${final_results}
    &{statistics}                 Save Boot time Data   ${TEST NAME}  ${final_results}
    Generate power plot           ${BUILD_ID}_${TEST NAME}   ${TEST NAME}
    Stop recording power
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    Determine Test Status         ${statistics}  inverted=1

Get Boot times
    [Documentation]  Collect boot times from device
    [Arguments]  ${plot_name}=Soft Boot Times
    ${start_time_epoch}  DateTime.Get Current Date   result_format=epoch
    # For detecting timestamp of Login screen in cosmic desktop
    ${testuser_line}  Catenate  SEPARATOR=\n
    ...  testuser_line=$(journalctl -b --output=short-iso | grep "${USER_LOGIN}: changing state activating-for-acquire")
    ...  echo $testuser_line

    ${ping_response_seconds}    Measure Time To Ping    ${start_time_epoch}
    Switch to vm            ${GUI_VM}
    ${time_to_desktop}      Check Time To Notification  ${testuser_line}   ${start_time_epoch}
    Log                     Boot time to login screen measured: ${time_to_desktop}   console=True
    &{final_results}        Create Dictionary
    Set To Dictionary       ${final_results}  time_to_desktop  ${time_to_desktop}
    Set To Dictionary       ${final_results}  response_to_ping  ${ping_response_seconds}
    # Before saving the data, check that the captured values are positive.
    Check Result Validity   ${final_results}
    &{statistics}           Save Boot time Data   ${TEST NAME}  ${final_results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    # In boot time test decrease in result value is considered improvement -> using inverted argument
    Determine Test Status   ${statistics}   inverted=1

Check Time To Notification
    [Documentation]  Check that correct notification is available in journalctl
    [Arguments]      ${command}   ${start_time}
    ${notification_line}  Set Variable  ${EMPTY}
    WHILE  '${notification_line}' == '${EMPTY}'   limit=${SEARCH_TIMEOUT} seconds
        ${notification_line}    Run Command  ${command}
    END

    IF  '${notification_line}' == '${EMPTY}'
       Fail  The searched journalctl line that is needed for 'time_to_desktop' calculation was not captured.
    END

    ${get_timestamp}      Catenate  SEPARATOR=\n
    ...  desktop_time=$(date -d "$(${command} | tail -1 | awk '{print $1}')" "+%s")
    ...  echo $desktop_time
    ${notification_time}  Run Command  ${get_timestamp}
    ${time}  Subtract Time From Time  ${notification_time}  ${start_time}   exclude_millis=True
    Should Be True  0 < ${time} < 120
    RETURN  ${time}

Check Result Validity
    [Arguments]      ${captured_results}
    FOR  ${key}  ${value}  IN  &{captured_results}
         Should Be True  ${value} > 0
    END

Log Journal To Debug
    [Arguments]           ${boot}=0
    ${journal_output}     Run Command   journalctl -b ${boot}

Wait Until Power Is Low
    [Arguments]           ${measurement_id}
    WHILE  True   limit=180 seconds
        ${end_time}       Get current timestamp
        Get power record  ${measurement_id}.csv
        ${start_time}     DateTime.Add Time To Date   ${end_time}   -3 seconds
        ...               exclude_millis=yes
        ${mean_power}     Calculate average power over interval
        ...               ${measurement_id}  ${start_time}  ${end_time}
        Log               Measured power: ${mean_power}mW   console=True
        IF  ${mean_power} < ${SHUTDOWN_POWER_LIMIT}
            RETURN        ${end_time}
        END
        Sleep             0.5
    END

Boot Time Test Teardown
    Run Keyword If Test Failed   Failed Boot Time Test Teardown
    IF   ${IS_LAPTOP}    Login to laptop

Failed Boot Time Test Teardown
    Hard Reboot Device And Connect
    IF   ${IS_LAPTOP}
        Switch to vm          ${HOST}
        Log Journal To Debug  boot=-1
    END

Shutdown Time Teardown
    Close All Connections
    Delete All Ports
    Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${False}
    Sleep  10
    Hard Reboot Device And Connect
