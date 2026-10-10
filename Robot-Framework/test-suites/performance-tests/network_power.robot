# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network load power consumption tests

Library             OperatingSystem
Library             Process
Library             String
Library             Collections
Resource            ../../config/variables.robot
Resource            ../../resources/measurement_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Run Keywords    Check Network Power Iperf Server Variables
...                 AND             Ensure balanced power profile


*** Variables ***

${NETWORK_LOAD_TIMEOUT}          60
${MIRROR_BENCH_WINDOW}           75
${MIRROR_BENCH_TIMEOUT}          300
${IPERF_SERVER_TIMEOUT}          300
${POWER_LOG_TIMEOUT}             420

${MIRROR_BENCH_ITERATIONS}       1
${MIRROR_BENCH_START_ATTEMPTS}   5
${MIRROR_BENCH_START_INTERVAL}   5s
${MIRROR_BENCH_SCRIPT}           ${CURDIR}/run-mirror-bench.sh
${LOCAL_IPERF_SERVER}            ${EMPTY}
${MIRROR_BENCH_IPERF_SERVER}     ${EMPTY}
${IPERF_SERVER_CONNECTION}       ${EMPTY}
${IPERF_SERVER_STARTED}          ${False}

# For testing, to be defined in ghaf-infra
${TEST_SERVER_IP}                172.18.16.12


*** Test Cases ***
Measure Physical Power During Mirror Network Load
    [Documentation]    Measure external power for 60s idle and 60s during mirror benchmark network load.
    [Tags]             network-load-power  lenovo-x1  lab-only
    [Setup]            Run Keywords    Require Power Measurement Agent
    ...                AND             Prepare Network Power Iperf Server
    [Teardown]         Physical Power Test Teardown

    Start Required Power Measurement    ${BUILD_ID}-mirror-network-load    timeout=${POWER_LOG_TIMEOUT}

    Set timestamp       physical_idle_start
    Wait                ${NETWORK_LOAD_TIMEOUT}
    Set timestamp       physical_idle_end

    Run Mirror Bench And Measure Load Window
    ...    physical_load_start
    ...    physical_load_end
    ...    physical_mirror_bench_end

    Get power record    ${BUILD_ID}-mirror-network-load.csv
    ${idle_power}       Calculate average power over interval
    ...                 ${BUILD_ID}-mirror-network-load
    ...                 ${physical_idle_start}
    ...                 ${physical_idle_end}
    ${load_power}       Calculate average power over interval
    ...                 ${BUILD_ID}-mirror-network-load
    ...                 ${physical_load_start}
    ...                 ${physical_load_end}
    &{plot_events}      Create Dictionary
    Set To Dictionary   ${plot_events}    ${physical_load_start}          Mirror bench started
    Set To Dictionary   ${plot_events}    ${physical_mirror_bench_end}    Mirror bench finished
    Log                 Physical idle average power: ${idle_power} mW    console=True
    Log                 Physical load average power: ${load_power} mW    console=True
    Generate power plot
    ...    ${BUILD_ID}-mirror-network-load
    ...    Network load effect on power consumption
    ...    ${plot_events}

Measure BAT0 Power During Mirror Network Load
    [Documentation]    Measure BAT0-reported power for 60s idle and 60s during mirror benchmark network load.
    ...                This test case if meant for local reference measurement only when external power measurement
    ...                equipment is not available.
    ...                To be run on battery, charger unplugged (otherwise bat0 does not represent power consumption)
    [Tags]             network-load-bat0
    [Setup]            Run Keywords    Multiply Test Timing Variables    2
    ...                AND             Require BAT0 Discharging
    ...                AND             Prepare Network Power Iperf Server
    [Teardown]         BAT0 Power Test Teardown

    Start BAT0 power logging    timeout=${POWER_LOG_TIMEOUT}    overwrite=true

    Set timestamp       bat0_idle_start
    Wait                ${NETWORK_LOAD_TIMEOUT}
    Set timestamp       bat0_idle_end

    Run Mirror Bench And Measure Load Window    bat0_load_start    bat0_load_end    bat0_mirror_bench_end

    &{plot_events}      Create Dictionary
    Set To Dictionary   ${plot_events}    ${bat0_load_start}          Mirror bench started
    Set To Dictionary   ${plot_events}    ${bat0_mirror_bench_end}    Mirror bench finished
    Plot BAT0 power log    ${plot_events}
    ${idle_power}       Calculate BAT0 average power over interval    ${bat0_idle_start}    ${bat0_idle_end}
    ${load_power}       Calculate BAT0 average power over interval    ${bat0_load_start}    ${bat0_load_end}
    Log                 BAT0 idle average power: ${idle_power} mW    console=True
    Log                 BAT0 load average power: ${load_power} mW    console=True


*** Keywords ***
Multiply Test Timing Variables
    [Arguments]    ${multiplier}=1
    IF  ${multiplier} == 1
        RETURN
    END
    ${network_load_timeout}=    Evaluate    int(${NETWORK_LOAD_TIMEOUT} * ${multiplier})
    ${mirror_bench_window}=     Evaluate    int(${MIRROR_BENCH_WINDOW} * ${multiplier})
    ${mirror_bench_timeout}=    Evaluate    int(${MIRROR_BENCH_TIMEOUT} * ${multiplier})
    ${iperf_server_timeout}=    Evaluate    int(${IPERF_SERVER_TIMEOUT} * ${multiplier})
    ${power_log_timeout}=       Evaluate    int(${POWER_LOG_TIMEOUT} * ${multiplier})
    Set Test Variable    ${NETWORK_LOAD_TIMEOUT}     ${network_load_timeout}
    Set Test Variable    ${MIRROR_BENCH_WINDOW}      ${mirror_bench_window}
    Set Test Variable    ${MIRROR_BENCH_TIMEOUT}     ${mirror_bench_timeout}
    Set Test Variable    ${IPERF_SERVER_TIMEOUT}     ${iperf_server_timeout}
    Set Test Variable    ${POWER_LOG_TIMEOUT}        ${power_log_timeout}

Start Required Power Measurement
    [Arguments]    ${id}    ${timeout}=240
    Start power measurement    ${id}    timeout=${timeout}
    IF  $SSH_MEASUREMENT=='${EMPTY}'
        SKIP    Power measurement agent is not available.
    END

Require BAT0 Discharging
    Switch to vm    ${HOST}
    TRY
        ${battery_status}=    Run Command    cat /sys/class/power_supply/BAT0/status
    EXCEPT
        SKIP    BAT0 power supply is not available.
    END
    ${battery_status}=    Strip String    ${battery_status}
    IF  '${battery_status}' != 'Discharging'
        SKIP    BAT0 status is ${battery_status}; run this test without charger connected.
    END

Run Mirror Bench And Measure Load Window
    [Arguments]    ${load_start_timestamp}    ${load_end_timestamp}    ${bench_end_timestamp}=${EMPTY}
    ${safe_test_name}=    Replace String    ${TEST NAME}    ${SPACE}    _
    ${bench_dir}=        Set Variable       ${OUTPUT_DIR}/mirror-bench/${safe_test_name}
    ${marker}=           Set Variable       ${bench_dir}/load-start.marker
    ${process_log}=      Set Variable       ${bench_dir}/robot-process.log
    @{iperf_args}=       Create List
    IF  '${MIRROR_BENCH_IPERF_SERVER}' != '${EMPTY}'
        Append To List    ${iperf_args}    --iperf-server    ${MIRROR_BENCH_IPERF_SERVER}
    END
    Create Directory    ${bench_dir}
    Run Keyword And Ignore Error    OperatingSystem.Remove File    ${marker}
    ${previous_log_level}=    Set Log Level    NONE
    TRY
        Start Process
        ...    ${MIRROR_BENCH_SCRIPT}
        ...    --ip
        ...    ${DEVICE_IP_ADDRESS}
        ...    --window
        ...    ${MIRROR_BENCH_WINDOW}
        ...    --iterations
        ...    ${MIRROR_BENCH_ITERATIONS}
        ...    --no-host-bench
        ...    @{iperf_args}
        ...    --password
        ...    ${PASSWORD}
        ...    --out
        ...    ${bench_dir}
        ...    alias=mirror-bench
        ...    stdout=${process_log}
        ...    stderr=STDOUT
        ...    env:MIRROR_BENCH_LOAD_MARKER=${marker}
    FINALLY
        Set Log Level    ${previous_log_level}
    END
    Wait For Mirror Bench Load Marker    ${marker}    ${process_log}
    Set timestamp         ${load_start_timestamp}
    Wait                  ${NETWORK_LOAD_TIMEOUT}
    Set timestamp         ${load_end_timestamp}
    ${result}=            Wait For Process
    ...                   mirror-bench
    ...                   timeout=${MIRROR_BENCH_TIMEOUT}
    ...                   on_timeout=terminate
    IF  '${bench_end_timestamp}' != '${EMPTY}'
        Set timestamp     ${bench_end_timestamp}
    END
    Should Be Equal As Integers    ${result.rc}    0

Wait For Mirror Bench Load Marker
    [Arguments]    ${marker}    ${process_log}
    FOR    ${index}    IN RANGE    ${MIRROR_BENCH_START_ATTEMPTS}
        ${marker_exists}=    Run Keyword And Return Status    OperatingSystem.File Should Exist    ${marker}
        IF  ${marker_exists}
            RETURN
        END
        ${is_running}=      Process.Is Process Running    mirror-bench
        IF  not ${is_running}
            ${log_exists}=  Run Keyword And Return Status    OperatingSystem.File Should Exist    ${process_log}
            ${log}=         Set Variable If    ${log_exists}    ${EMPTY}    Process log was not created.
            IF  ${log_exists}
                ${log}=     OperatingSystem.Get File    ${process_log}
            END
            FAIL    Mirror benchmark exited before load marker was created.${\n}${log}
        END
        Sleep    ${MIRROR_BENCH_START_INTERVAL}
    END
    FAIL    ${marker} was not created before mirror benchmark start timeout.

Prepare Network Power Iperf Server
    IF  '${LOCAL_IPERF_SERVER}' != '${EMPTY}'
        Log    Using local Robot runner iperf3 server; TCP 5201 must already be allowed.    console=True
        Set Suite Variable    ${MIRROR_BENCH_IPERF_SERVER}    ${EMPTY}
        RETURN
    END
    Connect To Dedicated Iperf Server
    Open Dedicated Iperf Server Port
    Start Dedicated Iperf Server
    Set Suite Variable    ${MIRROR_BENCH_IPERF_SERVER}    ${TEST_SERVER_IP}

Check Network Power Iperf Server Variables
    IF  '${LOCAL_IPERF_SERVER}' != '${EMPTY}'
        RETURN
    END
    TRY
        Require Dedicated Iperf Server Variables
    EXCEPT    AS    ${message}
        SKIP    ${message}
    END

Require Dedicated Iperf Server Variables
    ${previous_log_level}=    Set Log Level    NONE
    ${server_ip}=            Check variable availability    TEST_SERVER_IP
    ${server_login}=         Check variable availability    LOGIN_SERVER
    ${server_password}=      Check variable availability    PASSWORD_SERVER
    Set Log Level            ${previous_log_level}
    IF  not ${server_ip}
        FAIL    TEST_SERVER_IP is not defined. Set LOCAL_IPERF_SERVER to use the Robot runner instead.
    END
    IF  not ${server_login} or not ${server_password}
        FAIL    LOGIN_SERVER or PASSWORD_SERVER is not defined for the dedicated iperf server.
    END

Connect To Dedicated Iperf Server
    ${connection}=    Open Connection    ${TEST_SERVER_IP}    prompt=$    timeout=15
    Login            username=${LOGIN_SERVER}    password=${PASSWORD_SERVER}
    Set Suite Variable    ${IPERF_SERVER_CONNECTION}    ${connection}

Open Dedicated Iperf Server Port
    Switch Connection    ${IPERF_SERVER_CONNECTION}
    ${out}    ${err}    ${rc}=    Execute Command
    ...    iptables -I INPUT -p tcp --dport 5201 -j ACCEPT
    ...    sudo=True
    ...    sudo_password=${PASSWORD_SERVER}
    ...    return_stderr=True
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}    0    Failed to open TCP 5201 on iperf server: ${err}

Start Dedicated Iperf Server
    Switch Connection    ${IPERF_SERVER_CONNECTION}
    ${out}    ${err}    ${rc}=    Execute Command
    ...    pgrep -f "[i]perf3.*-[s]"
    ...    return_stderr=True
    ...    return_rc=True
    IF  ${rc} == 0
        Log    Reusing iperf3 server on ${TEST_SERVER_IP}:5201    console=True
        Set Suite Variable    ${IPERF_SERVER_STARTED}    ${False}
        RETURN
    END
    ${server_command}=    Set Variable    timeout ${IPERF_SERVER_TIMEOUT} iperf3 -s
    Execute Command    nohup nix-shell -p iperf3 --run '${server_command}' > /tmp/robot-iperf3-server.log 2>&1 &
    Wait Until Keyword Succeeds    60s    2s    Check Dedicated Iperf Server Running
    Set Suite Variable    ${IPERF_SERVER_STARTED}    ${True}

Check Dedicated Iperf Server Running
    ${out}    ${err}    ${rc}=    Execute Command
    ...    pgrep -f "[i]perf3.*-[s]"
    ...    return_stderr=True
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}    0    Failed to start iperf3 server: ${err}

Close Dedicated Iperf Server
    IF  '${LOCAL_IPERF_SERVER}' != '${EMPTY}' or '${IPERF_SERVER_CONNECTION}' == '${EMPTY}'
        RETURN
    END
    TRY
        Switch Connection    ${IPERF_SERVER_CONNECTION}
        Close Dedicated Iperf Server Port
        IF  ${IPERF_SERVER_STARTED}
            Execute Command    pkill -f "[i]perf3.*-[s]"
        END
    EXCEPT    AS    ${error}
        Log    Close Dedicated Iperf Server failed: ${error}    console=True
    END

Close Dedicated Iperf Server Port
    ${out}    ${err}    ${rc}=    Execute Command
    ...    iptables -D INPUT -p tcp --dport 5201 -j ACCEPT
    ...    sudo=True
    ...    sudo_password=${PASSWORD_SERVER}
    ...    return_stderr=True
    ...    return_rc=True
    IF  ${rc} != 0
        Log    TCP 5201 cleanup on iperf server skipped or failed: ${err}    console=True
    END

Calculate BAT0 average power over interval
    [Arguments]    ${start_time}    ${end_time}
    Save measurement interval
    ...    bat0_power_logger.csv
    ...    '${start_time}'
    ...    '${end_time}'
    ...    bat0_power_interval.csv
    ...    ${False}
    ...    1000
    ${mean_power}=    Mean power    bat0_power_interval.csv
    RETURN            ${mean_power}

Physical Power Test Teardown
    Terminate Process    mirror-bench    kill=True
    Stop recording power
    Close Dedicated Iperf Server
    Close All Connections

BAT0 Power Test Teardown
    Terminate Process    mirror-bench    kill=True
    TRY
        Switch to vm    ${HOST}
        Kill process by name    bat0_power_logger    True    ${False}
    EXCEPT    AS    ${error}
        Log    BAT0 logger cleanup failed on ${HOST}: ${error}    console=True
        Log    BAT0 logger will anyway terminate soon due to internal timeout    console=True
    END
    Close Dedicated Iperf Server
    Close All Connections
