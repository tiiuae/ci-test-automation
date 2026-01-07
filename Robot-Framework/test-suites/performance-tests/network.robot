# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          network  performance

Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             Collections
Library             JSONLibrary
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Run Keywords  Connect
...                 AND  Run iperf server on DUT
Suite Teardown      Run Keywords   Kill App By Name   iperf
...                 AND  Close port 5201 from iptables
...                 AND  Close All Connections


*** Variables ***
${PERF_TEST_TIME}  10


*** Test Cases ***
Measure TCP Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]   SP-T227  tcp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    # DUT sends
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    # DUT receives
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME}    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  SP-T228  tcp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}

Measure TCP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  SP-T229  tcp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}

Measure TCP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  SP-T230  tcp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}

Measure UDP TX Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  SP-T231  tcp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  SP-T232  tcp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP" Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}
    # [Teardown]  Run Keyword If   "${DEVICE_TYPE}" == "dell-7330"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6774"

Measure UDP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  SP-T233  udp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  SP-T234  udp  lenovo-x1  darter-pro  dell-7330
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    # Measurement result based PASS/FAIL criteria disabled for this test case
    # Determine Test Status   ${statistics}
    # [Teardown]   Run Keyword If   "AGX" in "${DEVICE}"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6623 (AGX)"

*** Keywords ***
Run iperf server on DUT
    [Documentation]   Run iperf on DUT in server mode
    Open port 5201 from iptables
    ${command}                      Set Variable    iperf -s
    Execute Command                 nohup ${command} > /tmp/output.log 2>&1 &
    Check iperf was started

Open port 5201 from iptables
    [Documentation]  Firewall rule to open needed port for perf test.
    Execute Command  iptables -A ghaf-fw-in-filter -p tcp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -A ghaf-fw-in-filter -p udp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}
    Sleep        1

Close port 5201 from iptables
    [Documentation]  Firewall rule to close the port that was used in per testing
    Execute Command  iptables -A ghaf-fw-in-filter -p tcp --dport 5201 -j DROP  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -A ghaf-fw-in-filter -p udp --dport 5201 -j DROP  sudo=True  sudo_password=${PASSWORD}

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

Check iperf3 got results
    [Documentation]     Check if starting iperf3 client was successful or not. (iperf3 is started 1 or 2 times per a test)
    ...                 When starting as expected, output is '<result object with rc 0>'
    ...                 In case of failure, output is: '<result object with rc 1>'
    [Arguments]        ${result1}=${EMPTY}  ${result2}=${EMPTY}
    ${failure}    Run Keyword And Return Status      Should Contain  ${result1}/${result2}    <result object with rc 1>
    Run Keyword If  ${failure}  FAIL  'iperf3 -c' did not succeed, No needed results got!

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
    ${status}    Run Keyword And Return Status   Should Not Be Empty  ${MBps}
    IF  not ${status}
        Log      Failed to get the result from ${TEST NAME}   console=yes
    END
    RETURN  ${MBps}[0]
