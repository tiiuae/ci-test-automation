# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
#Resource            ../../resources/common_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/connection_keywords.resource
Library             ../../lib/output_parser.py
#Library             ../../lib/TimeLibrary.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             Collections
Library             JSONLibrary
#Library             DebugLibrary
Suite Setup         Run keywords  Initialize Variables And Connect
...                 AND  Select network connection to use
...                 AND  Restart netvm if needed
Suite Teardown      Run keywords  Stop iperf server
...                 AND  Close port 5201 from iptables
...                 AND  Close All Connections


*** Variables ***
${PERF_TEST_TIME}  10


*** Test Cases ***
Measure TCP Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in reverse mode to get tx speed
    [Tags]   tcp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T227
    ${journal_log}    Execute command  journalctl --since "20 minutes ago"
    Log     ${journal_log}
    #Debug
    # Debug Ensure times
   # ${current_time_mikko}   Get current time   UTC
     ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running   range=1
     Log to console  Netvm:${status} - ${state}
    #Set time  ${current_time_mikko}
    #Sleep   10
    #${output}        Execute Command   timedatectl -a
    #${local_time}    ${universal_time}    ${rtc_time}    ${device_time_zone}    ${is_synchronized}   Parse Time Info   ${output}
    #${time_close}    Is Time Close   ${universal_time}    ${local_time}    tolerance_seconds=30
    #${time_close2}   Is Time Close   ${universal_time}    ${rtc_time} UTC    tolerance_seconds=30
    #Should be True   ${time_close}
    #Should be True   ${time_close2}
    #Log to console   Times are checked rtc=local=universal
    #Run keyword and continue on failure  Verify service status   service=${netvm_service}   expected_status=active   expected_state=running
    #   Log To Console          Going to start NetVM
    #${net-vm-status}    execute command  systemctl status microvm@net-vm.service
    #log  ${net-vm-status}
    #${what2}    Run keyword and continue on failure   Execute Command         systemctl start ${netvm_service}  sudo=True  sudo_password=${PASSWORD}  timeout=120  output_during_execution=True
    #sleep  5
    #${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running   range=1
    #IF  not ${status} and ${state}
        # Restart NetVM
     #Actual test
    #Run iperf server on DUT
    
    
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
    #Set To Dictionary       ${speed_data}  tx  ${bps_tx}  rx  ${bps_rx}
    #Log                     <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Transfer Small Packets" width="1200">    HTML
    #${statistics}           Save Speed Data   ${TEST NAME}  ${speed_data}
    #Determine Test Status   ${statistics}

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  tcp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T228
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
    [Tags]  tcp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T229
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
    [Tags]  tcp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T230
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
    [Tags]  tcp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T231
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
    [Tags]  tcp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T232
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
    [Tags]  udp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T233
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
    Determine Test Status   ${statistics}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on DUT. Send data from agent PC in bidir mode to get bi-directional speed
    [Tags]  udp  nuc  orin-agx  orin-agx-64  riscv  lenovo-x1   dell-7330  SP-T234
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

Run iperf server on DUT
    [Documentation]   Run iperf on DUT in server mode
    IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
         Open port 5201 from iptables
    ELSE
         Clear iptables rules
    END

    ${command}        Set Variable    iperf -s
    Execute Command   nohup ${command} > /tmp/output.log 2>&1 &
    Check iperf was started

Clear iptables rules
    [Documentation]  Clear IP tables rules to open ports
    Execute Command  iptables -F  sudo=True  sudo_password=${PASSWORD}

Open port 5201 from iptables
    [Documentation]  Firewall rule to open needed port for perf test.
    Execute Command  iptables -I INPUT -m tcp -p tcp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -I INPUT -m udp -p udp --dport 5201 -j ACCEPT  sudo=True  sudo_password=${PASSWORD}

    # Accept incoming packages that do belong to some already opened connection
    Execute Command  iptables -I INPUT -m state RELATED, ESTABLISHED -j ACCEPT  sudo=True  sudo_password=${PASSWORD}
    Sleep        1

Close port 5201 from iptables
    [Documentation]  Firewall rule to close the port that was used in per testing
    Execute Command  iptables -I INPUT -m tcp -p tcp --dport 5201 -j DROP  sudo=True  sudo_password=${PASSWORD}
    Execute Command  iptables -I INPUT -m udp -p udp --dport 5201 -j DROP  sudo=True  sudo_password=${PASSWORD}

    # Reject also incoming packages that do belong to some already opened connection
    Execute Command  iptables -I INPUT -m state RELATED, ESTABLISHED -j DROP  sudo=True  sudo_password=${PASSWORD}

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

Set time
    [Arguments]       ${time}=${wrong_time}
    ${original_time}      Get Time	epoch
    Set Test Variable     ${original_time}  ${original_time}
    Log To Console        Setting time ${time}
    Execute Command       hwclock --set --date="${time}"  sudo=True  sudo_password=${PASSWORD}
    Execute Command       hwclock -s  sudo=True  sudo_password=${PASSWORD}
    ${output}             Execute Command  timedatectl -a

Restart netvm if needed
    ${net-vm-status}    execute command  systemctl status microvm@net-vm.service
    log  ${net-vm-status}

    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running   #range=15
    IF  "NX" in "${DEVICE}"
        IF  not ${status}
            Switch Connection   ${GHAF_HOST_SSH}
            Restart NetVM
            #Stop NetVM
            #Sleep  5
            #Start NetVM
            Check if ssh is ready on netvm
    
        #Close All Connections
        #Connect to ghaf host
        #Check Network Availability      ${NETVM_IP}    expected_result=True    range=15
        #Connect to netvm
        END
     END

Restart NetVM
    [Documentation]    Stop NetVM via systemctl, wait ${delay} and start NetVM
    ...                Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]        ${delay}=5
    Stop NetVM
    Sleep  ${delay}
    Start NetVM
    Check if ssh is ready on netvm

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