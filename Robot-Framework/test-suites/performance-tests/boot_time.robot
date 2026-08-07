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
${SHUTDOWN_POWER_LIMIT}    1500
${SHUTDOWN_VERIFIED}       ${False}


*** Test Cases ***

Measure Soft Boot Time
    [Documentation]  Measure how long it takes to device to boot up with soft reboot
    [Tags]           SP-T187  SP-T187-1  lenovo-x1  dell-7330
    Soft Reboot Device
    Get Boot times

Measure Shutdown Time
    [Documentation]  Measure how long it takes to device to shut down with software shutdown
    [Tags]           SP-T83  SP-T83-1  lenovo-x1  darter-pro  dell-7330  lab-only
    Get Shutdown Time
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
    ${use_power_measurement}      Set Variable    ${False}
    ${availability}               Check variable availability  RPI_IP_ADDRESS
    IF  ${availability}
        Start power measurement   ${BUILD_ID}_shutdown   timeout=300
        IF  $SSH_MEASUREMENT!='${EMPTY}'
            ${use_power_measurement}    Set Variable    ${True}
        END
    END
    Soft Shutdown Device
    ${start_time_epoch}           DateTime.Get Current Date   result_format=epoch
    ${shutdown_time_epoch}  ${verified_via_serial}    Verify shutdown via serial    open_serial_port=${False}
    IF  not ${verified_via_serial}
        SKIP    Shutdown time verification via serial failed, fell back to 'Verify shutdown via network' which is not accurate.\nSkipping the test.
    END
    ${shutdown_time}              Evaluate    int(${shutdown_time_epoch}) - int(${start_time_epoch})
    Log                           Shutdown time measured via Serial output: ${shutdown_time}   console=True
    Set Suite Variable            ${SHUTDOWN_VERIFIED}    ${True}
    &{final_results}              Create Dictionary
    Set To Dictionary             ${final_results}  shutdown_time  ${shutdown_time}
    Set To Dictionary             ${final_results}  shutdown_time_power  ${nan}
    IF  ${use_power_measurement}
        ${shutdown_time_power_epoch}    Detect when power went low   ${BUILD_ID}_shutdown
        ${shutdown_time_power}          Evaluate
        ...                             int(${shutdown_time_power_epoch}) - int(${start_time_epoch})
        Log                             Shutdown time by power measured: ${shutdown_time_power}   console=True
        Set To Dictionary               ${final_results}  shutdown_time_power  ${shutdown_time_power}
    END
    Check Result Validity         ${final_results}
    &{statistics}                 Save Boot time Data   ${TEST NAME}  ${final_results}
    IF  ${use_power_measurement}
        Sleep                     5
        Generate power plot       ${BUILD_ID}_shutdown   ${TEST NAME}
        Stop recording power
    END
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="${plot_name}" width="1200">    HTML
    Determine Test Status         ${statistics}  inverted=1
    IF  ${use_power_measurement}
        ${measurement_diff}      Evaluate    abs(${shutdown_time_power} - ${shutdown_time})
        Should Be True           ${measurement_diff} <= 10
        ...                      msg=Shutdown time by power differs ${measurement_diff} sec from serial, expected <= 10 sec
    END

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
         IF  '${value}' == 'nan'
             CONTINUE
         END
         Should Be True  ${value} > 0
    END

Log Journal To Debug
    [Arguments]           ${boot}=0
    ${journal_output}     Run Command   journalctl -b ${boot}

Wait Until Power Is Low
    [Arguments]           ${measurement_id}
    ${retro_interval}     Set Variable    3
    # Give some time for measurement results to accumulate before starting to iterate retrospective time intervals
    Sleep                 ${retro_interval}
    WHILE  True   limit=180 seconds
        ${end_time}        Get current timestamp
        ${end_time_epoch}  Get Time    epoch
        Get power record   ${measurement_id}.csv    use_switch=${True}
        ${start_time}      DateTime.Add Time To Date   ${end_time}   -${retro_interval} seconds
        ...                exclude_millis=yes
        TRY
            ${mean_power}     Calculate average power over interval
            ...               ${measurement_id}  ${start_time}  ${end_time}
            Log               Measured power: ${mean_power}mW   console=True
            IF  ${mean_power} < ${SHUTDOWN_POWER_LIMIT}
                RETURN        ${end_time}    ${end_time_epoch}
            END
        EXCEPT
            Log    Ignoring invalid measured power sample    console=True
        END
        Sleep  0.5
    END

Detect when power went low
    [Documentation]       Detect the moment of power off more accurately by iterating backwards
    [Arguments]           ${measurement_id}
    ${coarse_end_time}    ${coarse_end_epoch}    Wait Until Power Is Low    ${measurement_id}
    ${scan_interval}      Set Variable    2
    ${step_back}          Set Variable    1
    ${last_low_power_time}   Set Variable    ${coarse_end_time}
    ${last_low_power_epoch}  Set Variable    ${coarse_end_epoch}
    ${scan_end_time}      Set Variable    ${coarse_end_time}
    ${scan_end_epoch}     Set Variable    ${coarse_end_epoch}
    WHILE  True   limit=60 seconds
        ${scan_start_time}    DateTime.Add Time To Date   ${scan_end_time}   -${scan_interval} seconds
        ...                   exclude_millis=yes
        TRY
            ${mean_power}     Calculate average power over interval
            ...               ${measurement_id}  ${scan_start_time}  ${scan_end_time}
            Log               Backward scan power: ${mean_power}mW   console=True
            IF  ${mean_power} < ${SHUTDOWN_POWER_LIMIT}
                ${last_low_power_time}   Set Variable    ${scan_end_time}
                ${last_low_power_epoch}  Set Variable    ${scan_end_epoch}
                ${scan_end_time}      DateTime.Add Time To Date   ${scan_end_time}   -${step_back} seconds
                ...                   exclude_millis=yes
                ${scan_end_epoch}     Evaluate    int(${scan_end_epoch}) - int(${step_back})
            ELSE
                RETURN                 ${last_low_power_epoch}
            END
        EXCEPT
            RETURN                     ${last_low_power_epoch}
        END
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
    IF  ${IS_LAPTOP}
        IF  not ${SHUTDOWN_VERIFIED}
            Reboot Laptop
            Check If Device Is Up    retry=110s
            IF  ${IS_AVAILABLE} == False
                Log To Console    Turning device on again...
                Turn Laptop On
                Check If Device Is Up    retry=110s
            END
        ELSE
            Turn Laptop On
            Check If Device Is Up    retry=110s
        END
    ELSE
        Reboot Orin
        IF  "orin-agx" in "${DEVICE_TYPE}"
            # Known issue SSRCSP-8704
            Check If Device Is Up   retry=230s
        ELSE
            Check If Device Is Up   retry=140s
        END
    END
    Connect After Reboot
