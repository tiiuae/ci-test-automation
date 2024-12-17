# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/performance_keywords.resource
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${JOB}
Library             Collections
Library             JSONLibrary
Suite Setup         Common Setup
Suite Teardown      Close All Connections


*** Variables ***
${PERF_TEST_TIME}  10


*** Test Cases ***
Measure TCP Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]   tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T227
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    # DUT sends
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    # DUT receives
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME}    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output2.stdout}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Small Packets" width="1200">    HTML
    ${statistics}       Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T228
    [Setup]             Run iperf server on DUT
    [Teardown]          Stop iperf server
    &{speed_data}       Create Dictionary
    ${output}           Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                 ${output.stdout}
    ${bps_tx}           Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}           Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary   ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}       Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics   ${statistics}

Measure TCP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T229
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure TCP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T230
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    ${output}          Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output.stdout}
    ${bps_tx}          Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}          Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP TX Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T231
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output2.stdout}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Small Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T232
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    ${output}          Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output.stdout}
    ${bps_tx}          Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}          Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP" Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  udp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T233
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output2.stdout}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  udp  nuc  orin-agx  orin-nx  riscv  lenovo-x1  SSRCSP-T234
    [Setup]            Run iperf server on DUT
    [Teardown]         Stop iperf server
    &{speed_data}      Create Dictionary
    ${output}          Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output.stdout}
    ${bps_tx}          Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}          Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}


*** Keywords ***
Common Setup
    Set Variables     ${DEVICE}
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    Connect

Run iperf server on DUT
    [Documentation]   Run iperf on DUT in server mode
    Clear iptables rules
    ${command}        Set Variable    iperf -s
    Execute Command   nohup ${command} > /tmp/output.log 2>&1 &
    Check iperf was started

Clear iptables rules
    [Documentation]  Clear IP tables rules to open ports
    Execute Command  iptables -F  sudo=True  sudo_password=${PASSWORD}

Stop iperf server
    @{pid}=  Find pid by name  iperf
    IF  @{pid} != @{EMPTY}
        Log to Console  Close iperf server: @{pid}
        Kill process    @{pid}
    END

Check iperf was started
    [Arguments]       ${timeout}=5
    ${is_started} =   Set Variable    False
    FOR    ${i}    IN RANGE    ${timeout}
        ${output}=     Execute Command    sh -c 'ps aux | grep "iperf" | grep -v grep'
        ${status} =    Run Keyword And Return Status    Should Contain    ${output}    iperf -s
        IF    ${status}
            ${is_started} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    Iperf server was not started

Get Throughput Values
    [Documentation]  Return MB per second value
    [Arguments]  ${output}  ${direction}=sender  ${bidir}=False
    IF  ${bidir}
        IF  '${direction}' == 'sender'
            ${MBps}  Get Regexp Matches  ${output}    (?im).*TX-C.*\\s(\\d+(\\.\\d+)?) MBytes\\/sec.*${direction}  1
        ELSE
            ${MBps}  Get Regexp Matches  ${output}    (?im).*RX-C.*\\s(\\d+(\\.\\d+)?) MBytes\\/sec.*${direction}  1
        END
    ELSE
        ${MBps}  Get Regexp Matches  ${output}    (?im)\\s(\\d+(\\.\\d+)?) MBytes\\/sec.*${direction}  1
    END
    ${expected_throughput}  Set Variable If  ${bidir}  ${85}  ${90}
    Run Keyword And Continue On Failure  Should Be True  ${MBps}[0] > ${expected_throughput}
    RETURN  ${MBps}[0]

Report statistics
    [Documentation]  Check deviation of iperf results
    [Arguments]  ${statistics}
    ${statistics_tx}  Get From Dictionary  ${statistics}  tx
    ${statistics_rx}  Get From Dictionary  ${statistics}  rx

    ${fail_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_tx}[flag]" == "-1"
        ${add_msg}     Create fail message  ${statistics_tx}
        ${fail_msg}=  Set Variable  TX:\n${add_msg}
    END
    IF  "${statistics_rx}[flag]" == "-1"
        ${add_msg}     Create fail message  ${statistics_tx}
        ${fail_msg}=  Set Variable  ${fail_msg}RX:\n${add_msg}
    END
    IF  "${statistics_tx}[flag]" == "-1" or "${statistics_rx}[flag]" == "-1"
        FAIL    ${fail_msg}
    END

    ${pass_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_tx}[flag]" == "1"
        ${add_msg}     Create improved message  ${statistics_tx}
        ${pass_msg}=  Set Variable  TX:\n${add_msg}
    END
    IF  "${statistics_rx}[flag]" == "1"
        ${add_msg}     Create improved message  ${statistics_tx}
        ${pass_msg}=  Set Variable  ${pass_msg}\nRX:\n${add_msg}
    END
    IF  "${statistics_tx}[flag]" == "1" or "${statistics_rx}[flag]" == "1"
        Pass Execution    ${pass_msg}
    END

    ${msg}  Set Variable  ${EMPTY}
