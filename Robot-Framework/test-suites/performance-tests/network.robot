# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/device_control.resource
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             Collections
Library             JSONLibrary
Library             DebugLibrary
Test Timeout        3 minutes
Suite Setup         Network Suite Setup
Suite Teardown      Network Suite Teardown

*** Variables ***
${PERF_TEST_TIME}  10


*** Test Cases ***
Measure TCP Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]   tcp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T227
    [Timeout]               3 minutes
     IF  "NX" in "${DEVICE}"      
         Clear Iptables Rules
         Stop Iperf Server
         Close All Connections
         Initialize Variables And Connect   
         Select Network Connection To Use
         Set Iptables Rules
         Run iperf server on DUT
    END
    &{speed_data}           Create Dictionary
    # Debug take journal
    Save Current Journal Log

    # DUT sends
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} -R    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    Log                     ${output1.rc}
    Log                     ${output1.stderr}

    IF  "NX" in "${DEVICE}"          NX Check

    Check iperf3 got results     ${output1}
    # DUT receives
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME}    shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output2.stdout}
    
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    #Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    #Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Small Packets" width="1200">    HTML
    #${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    #Determine Test Status   ${statistics}
    [Teardown]    Run keyword if Test Passed     run keywords   Stop iperf server  AND  Clean Iptables Rules

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T228
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure TCP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  tcp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T229
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
    Determine Test Status   ${statistics}

Measure TCP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T230
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure UDP TX Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  tcp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T231
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
    Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T232
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP" Bidir Transfer Small Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure UDP Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]  udp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T233
    &{speed_data}           Create Dictionary
    ${output1}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME} -R   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output1.stdout}
    ${data_not_captured}     Run Keyword And Return Status    Should Contain  ${output1.stdout}  0.00 MBytes/sec
    ${output2}              Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 100G -f M -t ${PERF_TEST_TIME}   shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output2.stdout}
    Check iperf3 got results     ${output1}  ${output2}
    ${bps_tx}               Get Throughput Values  ${output1.stdout}
    ${bps_rx}               Get Throughput Values  ${output2.stdout}  direction=receiver
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  udp  nuc  orin-nx  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T234
    &{speed_data}           Create Dictionary
    ${output}               Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t ${PERF_TEST_TIME} --bidir  shell=True  timeout=${${PERF_TEST_TIME}+10}
    Log                     ${output.stdout}
    Check iperf3 got results     ${output}
    ${bps_tx}               Get Throughput Values  ${output.stdout}  bidir=True
    ${bps_rx}               Get Throughput Values  ${output.stdout}  direction=receiver  bidir=True
    Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Bidir Transfer Big Packets" width="1200">    HTML
    ${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    Determine Test Status   ${statistics}

    [Teardown]   Run Keyword If   "AGX" in "${DEVICE}"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6623 (AGX)"

*** Keywords ***
Select network connection to use
    [Documentation]  Select the connection to be used. This cannot be done in Keyword 'Initialize Variables And Connect'
     ...             since it then breaks the other test suites.
     IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"

         ${CONNECTION}       Connect to netvm
     #ELSE
     #    ${CONNECTION}       Connect to ghaf host
     END
     Set Global Variable  ${CONNECTION}

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

Set Iptables Rules
    Log To Console  Started setting iptables rules
    IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
         Open port 5201 from iptables
    ELSE
         Clear iptables rules
    END
     Log To Console  Done setting iptables rules

Open port 5201 from iptables
    [Documentation]  Firewall rule to open needed port for perf test.
    ${original_rules}  Read iptables rules
    log  ${original_rules}
    Set Global Variable    ${original_rules}

    ${result}  ${rc}  ${stderr}  Execute Command  iptables --policy INPUT ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}  return_stderr=${true}  #originally DROP?
    ${result}  ${rc}  ${stderr}  Execute Command  iptables -I INPUT -m tcp -p tcp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}  return_stderr=${true}
    ${result}  ${rc}  ${stderr}  Execute Command  iptables -I INPUT -m udp -p udp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}  return_stderr=${true}
    # Accept incoming packages that do belong to some already opened connection
    ${result}  ${rc}  ${stderr}  Execute Command  iptables -I INPUT -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT  sudo=True  sudo_password=${PASSWORD}   return_rc=${true}  return_stdout=${true}  return_stderr=${true}

    ${changed_rules}  Read iptables rules
    log  ${changed_rules}

Clear iptables rules
    [Documentation]  Clear IP tables rules to open ports
    Execute Command  iptables -F  sudo=True  sudo_password=${PASSWORD}

Clean Iptables Rules
     IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"  Close port 5201 from iptables

Close port 5201 from iptables
    [Documentation]  Firewall rules to be deleted for port that was used in perf testing
    ${before_closing_rules}  Read iptables rules
    Should Not Be Equal  ${before_closing_rules}  ${original_rules}
    log  ${before_closing_rules}
    ${result}  ${rc}  Execute Command  iptables --policy INPUT DROP  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}
    ${result}  ${rc}  Execute Command  iptables -D INPUT -m tcp -p tcp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}
    ${result}  ${rc}  Execute Command  iptables -D INPUT -m udp -p udp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}

    # Reject also incoming packages that do belong to some already opened connection
    #${result}  ${rc}  Execute Command  iptables -D INPUT -m state RELATED -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}
    #${result}  ${rc}  Execute Command  iptables -D INPUT -m state ESTABLISHED -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}
    ${result}  ${rc}  Execute Command  iptables -D INPUT -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT  sudo=True  sudo_password=${PASSWORD}  return_rc=${true}  return_stdout=${true}

    ${after_test_rules}  Read iptables rules
    Log  ${after_test_rules}
    Should Be Equal  ${after_test_rules}  ${original_rules}

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
    IF   ${status} == False    
        FAIL    Iperf server was not started
    ELSE
        Log To Console  Iperf-s was started
    END

Check iperf3 got results
    [Documentation]     Check if starting iperf3 client was successful or not. (iperf3 is started 1 or 2 times per a test)
    ...                 When starting as expected, output is '<result object with rc 0>'
    ...                 In case of failure, output is: '<result object with rc 1>'
    [Arguments]        ${result1}=${EMPTY}  ${result2}=${EMPTY}
    ${failure}    Run Keyword And Return Status      Should Contain  ${result1}/${result2}    <result object with rc 1>

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

Network Suite Setup
    #IF  "NX" in "${DEVICE}"   Do SoftReboot Device
    Initialize Variables And Connect
    #IF  "NX" in "${DEVICE}"
    #    #Switch Connection    ${GHAF_HOST_SSH}
        #Restart NetVM
    #    Do SoftReboot Device
    #END
    Select network connection to use
    Set Iptables Rules
    Run iperf server on DUT

Network Suite Teardown
    #Stop iperf server
    #Clean Iptables Rules
    Close All Connections


Do SoftReboot Device
    Soft Reboot Device
    Sleep  10
    Check If Device Is Up   30
    Sleep   30   #NX
    Set Variables   ${DEVICE}

Do HardReboot Device
    Reboot Device Via Relay
    Sleep  10
    Check If Device Is Up   30
    Sleep   30   #NX
    Set Variables   ${DEVICE}
            
NX Check
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  "${device_not_available}" == "True"
        Log To Console    Device is down
        Do HardReboot Device
        Initialize Variables And Connect
        #${journal_output}     Execute Command   journalctl --since today
        #Log           ${journal_output}
        #SSHLibrary.Get file   /tmp/output.log     ${OUTPUT_DIR}/iperfs_log.txt
        #OperatingSystem.File Should Exist         ${OUTPUT_DIR}/iperfs_log.txt
        FAIL  'iperf3 -c' did not succeed, No needed results got!
    ELSE
        Log To Console    Device is UP
    END

Save Current Journal Log
    ${journal_output}     Execute Command   journalctl --since today
    Log           ${journal_output}
    #SSHLibrary.Get file   /tmp/output.log     ${OUTPUT_DIR}/iperfs_log.txt
    #OperatingSystem.File Should Exist         ${OUTPUT_DIR}/iperfs_log.txt

Restart NetVM
    [Documentation]    Stop NetVM via systemctl, wait ${delay} and start NetVM
    ...                Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]        ${delay}=5
    Stop NetVM
    Sleep  ${delay}
    Start NetVM
    Check if ssh is ready on vm   ${NET_VM}

Stop NetVM
    [Documentation]     Ensure that NetVM is started, stop it and check the status.
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Verify service status   service=${netvm_service}   expected_status=active   expected_state=running
    Log To Console          Going to stop NetVM
    Execute Command         systemctl stop ${netvm_service}  sudo=True  sudo_password=${PASSWORD}  timeout=120  output_during_execution=True
    Sleep    3
    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=inactive  expected_state=dead
    Verify service shutdown status   service=${netvm_service}
    Set Global Variable     ${NETVM_STATE}   ${state}
    Log To Console          NetVM is ${state}

Start NetVM
    [Documentation]     Try to start NetVM service
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Log To Console          Going to start NetVM
    Execute Command         systemctl start ${netvm_service}  sudo=True  sudo_password=${PASSWORD}  timeout=120  output_during_execution=True
    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running
    Set Global Variable     ${NETVM_STATE}   ${state}
    Log To Console          NetVM is ${state}
    Wait until NetVM service started