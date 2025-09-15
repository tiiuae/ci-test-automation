# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network

Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             Collections
Library             JSONLibrary
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Run Keywords  Connect to device
...                 AND  Connect to netvm
...                 AND  Run iperf server on DUT
Suite Teardown      Run Keywords  Stop iperf server
...                 AND  Close port 5201 from iptables
...                 AND  Close All Connections


*** Variables ***
${PERF_TEST_TIME}  10


*** Test Cases ***
Measure TCP Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    ...              Note. Using Default buffer length 128 KB
    ...              (-l The length of buffers to read or write. Default is 128 KB for TCP, 8 KB for UDP)
    [Tags]   tcp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T227
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
    Log  tx ${bps_tx}, rx:${bps_rx}  console=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    ...              Note. Using Default buffer length 128 KB
    ...              (-l The length of buffers to read or write. Default is 128 KB for TCP, 8 KB for UDP)
    [Tags]  tcp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T228
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Log  tx ${bps_tx}, rx:${bps_rx}  console=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure TCP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    ...              Note. Using Default buffer length 128 KB
    ...              (-l The length of buffers to read or write. Default is 128 KB for TCP, 8 KB for UDP)
    [Tags]  tcp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T229
    &{speed_data}           Create Dictionary
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    Log                     ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Log  tx ${bps_tx}, rx:${bps_rx}  console=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure TCP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T230
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Log  tx ${bps_tx}, rx:${bps_rx}  console=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure UDP TX Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    ...              Note. Using Default buffer length 8 KB
    ...              (-l The length of buffers to read or write.  Default is 128 KB for TCP, 8 KB for UDP)
    [Tags]  tcp  nuc  riscv    orin-nx  orin-agx  orin-agx-64  novo-x1  darter-pro   dell-7330  SP-T231
    &{speed_data}           Create Dictionary
    ${bandwidth}            Set Variable If  "Orin" in "${DEVICE}"  50M  100G
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b ${bandwidth} -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b ${bandwidth} -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Log  tx ${bps_tx}, rx:${bps_rx}  console=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    ...              Note. Using Default buffer length 8 KB
    ...              (-l The length of buffers to read or write.  Default is 128 KB for TCP, 8 KB for UDP)
    [Tags]  tcp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T232
    &{speed_data}           Create Dictionary
    #    IF  "Orin" in "${DEVICE}"
    #        ${bandwidth}   Set Variable  75M
    #    ELSE IF  "Darter" in "${DEVICE}"
    #        ${bandwidth}  Set Variable  900M
    #    ELSE
    #        ${bandwidth}  Set Variable  100G
    #    END
    ${bandwidth}    Set Variable  100G
    Log to console  Chosen bandwidth: ${bandwidth}

    FOR  ${i}  IN RANGE  0  5
        ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b ${bandwidth} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
        Log                     ${output.stdout}
        Check iperf3 got results     ${output}
        ${bps_tx}                   Get Throughput Values  ${output.stdout}
        ${bps_rx}                   Get Throughput Values  ${output.stdout}  direction=receiver 
        ${accepted}                 Result Check    ${output.stdout}   ${bps_tx}  ${bps_rx}
        Exit for Loop If            ${accepted}
    END
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP" Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

    [Teardown]  Run Keyword If   "Dell" in "${DEVICE}"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6774"

Measure UDP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  udp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T233
    &{speed_data}           Create Dictionary

    #IF  "Orin" in "${DEVICE}"
    #    ${bandwidth}   Set Variable  75M
    #ELSE IF  "Darter" in "${DEVICE}"
    #    ${bandwidth}  Set Variable  900M
    #ELSE
    #    ${bandwidth}  Set Variable  100G
    #END
    ${bandwidth}    Set Variable  100G
    Log to console  Chosen bandwidth: ${bandwidth}

    FOR  ${i}  IN RANGE  0  5
        ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b ${bandwidth} -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
        Log                     ${output1.stdout}  #console=True
        Extra Debug
        ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b ${bandwidth} -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
        Log                     ${output2.stdout}  #console=True
        Check iperf3 got results     ${output1}  ${output2}
        ${bps_tx}               Get Throughput Values  ${output1.stdout}
        ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
        ${accepted}             Result Check    ${output2.stdout}  ${bps_tx}  ${bps_rx}  accepted_failure_percent=30
        Exit for Loop If        ${accepted}
    END

    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  udp  nuc  riscv  orin-nx  orin-agx  orin-agx-64  lenovo-x1   darter-pro   dell-7330  SP-T234
    &{speed_data}           Create Dictionary
    
     #IF  "Orin" in "${DEVICE}"
     #       ${bandwidth}   Set Variable  75M
     #   ELSE IF  "Darter" in "${DEVICE}"
     #       ${bandwidth}  Set Variable  900M
     #   ELSE
     #       ${bandwidth}  Set Variable  10000G
     #   END
    ${bandwidth}    Set Variable  10000G
    Log to console  Chosen bandwidth: ${bandwidth}

    #ORIG  ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
     FOR  ${i}  IN RANGE  0  7
        ${output}                   Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b ${bandwidth} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
        Log                         ${output.stdout}
        Check iperf3 got results    ${output}
        ${bps_tx}                   Get Throughput Values  ${output.stdout}
        ${bps_rx}                   Get Throughput Values  ${output.stdout}  direction=receiver 
        ${accepted}                 Result Check    ${output.stdout}  ${bps_tx}  ${bps_rx}  accepted_failure_percent=30
        Exit for Loop If           ${accepted} 
    END
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

    [Teardown]   Run Keyword If   "AGX" in "${DEVICE}"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6623 (AGX)"

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

Stop iperf server
    @{pid}=  Find pid by name  iperf
    IF  @{pid} != @{EMPTY}
        Log             Close iperf server: @{pid}  console=True
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

Check Received Loss Percentage
    [Arguments]    ${data1}=${EMPTY}   #${data2}=${EMPTY}
    Run keyword if  $data1 == '${EMPTY}"'  FAIL  No input data given!   console=True
    # reqexp would be nice
    ${lines}    Get Lines Matching pattern  ${data1}  *receiver*
    ${temp}     Fetch From Right  ${lines}  (
    ${loss}     Fetch From Left  ${temp}  %
    ${loss_nb}  Convert To Number  ${loss}

    RETURN  ${loss_nb}
    
Result Check
    [Documentation]    
    [Arguments]    ${result_data}=""  ${bps_tx}=  ${bps_rx}=  ${accepted_failure_percent}=15
    ${lost_rx_data}   Check Received Loss Percentage   ${result_data}

        Log  ==== tx ${bps_tx}, rx: ${bps_rx}, rx failure%: ${lost_rx_data}% ====  console=True
        ${upper}    Evaluate    1.1*${bps_tx}
        ${lower}    Evaluate    0.4*${bps_tx}
        ${upper}    Convert to Number  ${upper}  2
        ${lower}    Convert to Number  ${lower}  2
        ${verdict}  Run Keyword And Return Status  Should Be True  (2 < ${bps_tx}) and (2 < ${bps_rx}) and (${lost_rx_data} < ${accepted_failure_percent})

        RETURN  ${verdict}
        
Extra Debug
        ${receiver_buffer_1}    Execute command  ss -un
        ${receiver_buffer_2}    Execute command  ip -s link
        ${ifconfig}             Execute command  ifconfig
        ${load_avg}             Execute command  cat /proc/loadavg
        ${load_interrupts}      Execute command  cat /proc/interrupts
        log  ${receiver_buffer_1}
        log  ${receiver_buffer_2}
        log  ${ifconfig}
        log  ${load_avg}
        log  ${load_interrupts}        