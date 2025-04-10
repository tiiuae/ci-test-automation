# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/common_keywords.resource
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}  ${PERF_DATA_DIR}  ${CONFIG_PATH}   ${PLOT_DIR}
Library             Collections
Library             JSONLibrary
Suite Setup         Network Setup
Suite Teardown      Network Teardown
Test Timeout        3 minutes
Library  DebugLibrary

*** Variables ***
${PERF_TEST_TIME}  10


*** Test Cases ***
Measure TCP Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Timeout]    3 minutes
    [Tags]   tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T227
    &{speed_data}      Create Dictionary
    Log to console  DUT sends
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+20}
    Log To Console     ${output1.stdout}
    Log                ${output1.stdout}
    Log to console  DUT sends DONE
    Log to console  DUT receives
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME}    shell=True  timeout=${${PERF_TEST_TIME}+20}
    Log                ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Small Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}
    #[Teardown]    Run Keyword If Test Failed  Run Keywords  Stop iperf server  AND  Initialize Variables And Connect  AND  Run iperf server on DUT

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T228
    &{speed_data}       Create Dictionary
    ${output}           Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                 ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}           Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}           Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary   ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}       Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics   ${statistics}

Measure TCP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T229
    &{speed_data}      Create Dictionary
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure TCP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T230
    &{speed_data}      Create Dictionary
    ${output}          Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -O 5 -M 9000 -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}          Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}          Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP TX Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T231
    &{speed_data}      Create Dictionary
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Small Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T232
    &{speed_data}      Create Dictionary
    ${output}          Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}          Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}          Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP" Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  udp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T233
    &{speed_data}      Create Dictionary
    ${output1}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output1.stdout}
    ${output2}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}          Get Throughput Values  ${output1.stdout}
    ${bps_rx}          Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  udp  nuc  orin-agx  orin-nx  riscv  lenovo-x1   dell-7330  SP-T234
    &{speed_data}      Create Dictionary
    ${output}          Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}          Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}          Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary  ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}      Save Speed Data   ${TEST NAME}  ${speed_data}
    Report Statistics  ${statistics}

*** Keywords ***
Select network connection to use
    [Documentation]  Select the connection to be used. This cannot be done in Keyword 'Initialize Variables And Connect'
     ...             since it then breaks the  other test suites.
     IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
         ${CONNECTION}       Connect to netvm
     ELSE
         ${CONNECTION}       Connect to ghaf host
     END
     Set Global Variable  ${CONNECTION}

Adjust iptables rules
    [Documentation]  Clears rule tables or opens port 5201 for performance tests.
    IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}"
         Open port 5201 from iptables
         Sleep  5
    ELSE
         Clear iptables rules
    END

Run iperf server on DUT
    [Documentation]   Run iperf on DUT in server mode
    ${command}        Set Variable    iperf -s
    Execute Command   nohup ${command} > /tmp/output.log 2>&1 &
    Check iperf was started

Read iptables rules
    [Documentation]  Read iptables rules from target
    ${result}  ${rc}  Execute Command  iptables -L  sudo=True  sudo_password=${PASSWORD}   return_rc=${true}  return_stdout=${true}
    Should Be Equal   ${rc}  ${0}
    RETURN            ${result}

Clear iptables rules
    [Documentation]  Clear IP tables rules to open ports
    Execute Command  iptables -F  sudo=True  sudo_password=${PASSWORD}

Open port 5201 from iptables
    [Documentation]  Firewall rule to open needed port for perf test.
    ${original_rules}  Read iptables rules
    log  ${original_rules}
    # Save original rules
    ${result}   Execute Command  sudo iptables-save > /tmp/iptables-orig.rules  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    SSHLibrary.Get file   /tmp/iptables-orig.rules    ${OUTPUT_DIR}/iptables-orig-rules.txt
    # Set policy accept & open port 5201
    ${result}  ${rc}  Execute Command  iptables -P INPUT ACCEPT    sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    Should Be Equal   ${rc}  ${0}

    ${result}  ${rc}  Execute Command  sudo iptables -I INPUT -p tcp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    Should Be Equal   ${rc}  ${0}
    ${result}  ${rc}  Execute Command  sudo iptables -I INPUT -p udp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    Should Be Equal   ${rc}  ${0}

    ${result}  ${rc}  Execute Command  sudo iptables -I OUTPUT -p tcp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    Should Be Equal   ${rc}  ${0}
    ${result}  ${rc}  Execute Command  sudo iptables -I OUTPUT -p udp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    Should Be Equal   ${rc}  ${0}

    # Allow incoming packages that do belong to some currently open/created connection,
    ${result}  ${rc}  Execute Command  iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    Should Be Equal   ${rc}  ${0}
    Sleep            1


    ${changed_rules}  Read iptables rules
    Log  ${changed_rules}
    ${result}   Execute Command  sudo iptables-save > /tmp/iptables-tampered.rules  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    SSHLibrary.Get file   /tmp/iptables-tampered.rules    ${OUTPUT_DIR}/iptables-tampered-rules.txt

Close port 5201 from iptables
    [Documentation]  Firewall rule to close the port that was used in per testing
    # Take the original rules back into use
    ${result}   Execute Command  sudo iptables-restore < /tmp/iptables-orig.rules  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}
    ${after_test_rules}  Read iptables rules
    Log  ${after_test_rules}
    # Delete files
    ${rc}=    Execute Command    rm ${OUTPUT_DIR}/iptables-orig-rules.txt
    ${rc}=    Execute Command    rm ${OUTPUT_DIR}/iptables-tampered-rules.txt

Stop iperf server
    ${journal_output}     Execute Command   journalctl --since today
    Log           ${journal_output}

    SSHLibrary.Get file   /tmp/output.log     ${OUTPUT_DIR}/iperfs_log.txt
    OperatingSystem.File Should Exist         ${OUTPUT_DIR}/iperfs_log.txt

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
        ${add_msg}     Create fail message  ${statistics_rx}
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
        ${add_msg}     Create improved message  ${statistics_rx}
        ${pass_msg}=  Set Variable  ${pass_msg}\nRX:\n${add_msg}
    END
    IF  "${statistics_tx}[flag]" == "1" or "${statistics_rx}[flag]" == "1"
        Pass Execution    ${pass_msg}
    END

    ${msg}  Set Variable  ${EMPTY}

Network Setup
    [Timeout]      3 minutes
    Log to console  ..Initialize
    Initialize Variables And Connect
    Log to console  ..Select connection
    Select network connection to use
    Log to console  ..IP tables
    Adjust iptables rules
    Log to console  ..Iperf
    Run iperf server on DUT
    Log to console  ..done

Network Teardown
    [Timeout]      3 minutes
    Stop iperf server
    Close port 5201 from iptables
    Close All Connections


