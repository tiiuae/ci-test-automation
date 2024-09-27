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
Suite Setup         Run Keywords  Common Setup  AND  Switch MTU  mtu=9184
Suite Teardown      Run Keywords  Switch MTU  AND  Close All Connections


*** Test Cases ***

TCP speed test
    [Documentation]   Measure RX and TX speed for TCP
    [Tags]            tcp   SP-T91  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    Run iperf server on DUT
    &{tcp_speed}      Run TCP test
    ${statistics}     Save Speed Data   ${TEST NAME}  ${tcp_speed}
    ${statistics_tx}  Get From Dictionary  ${statistics}  tx
    ${statistics_rx}  Get From Dictionary  ${statistics}  rx

    Log               <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Plot" width="1200">    HTML
    [Teardown]        Stop iperf server

    ${fail_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_tx}[flag]" == "-1"
        ${add_msg}     Create fail message  ${statistics_tx}
        ${fail_msg}=  Set Variable  TX:\n${add_msg}
    END
    IF  "${statistics_rx}[flag]" == "-1"
        ${add_msg}     Create fail message  ${statistics_tx}
        ${fail_msg}=  Set Variable  ${fail_msg}\nRX:\n${add_msg}
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


UDP speed test
    [Documentation]   Measure RX and TX speed for UDP
    [Tags]            udp   SP-T92  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    Run iperf server on DUT
    &{udp_speed}      Run UDP test
    ${statistics}     Save Speed Data   ${TEST NAME}  ${udp_speed}
    ${statistics_tx}  Get From Dictionary  ${statistics}  tx
    ${statistics_rx}  Get From Dictionary  ${statistics}  rx

    Log               <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Plot" width="1200">    HTML
    [Teardown]        Stop iperf server

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

Measure TCP TX Throughput Small Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  tcp_iperf_tx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t 10 -R -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure TCP RX Throughput Small Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  tcp_iperf_rx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t 10 -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure TCP Bidir Throughput Small Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  tcp_iperf_bidir
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t 10 -J --bidir  shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}  sum_sent_bidir_reverse
    Get Throughput Values  ${output.stdout}  sum_received_bidir_reverse

Measure UDP TX Throughput Small Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  udp_iperf_tx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 10000G -f M -t 10 -R -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure UDP RX Throughput Small Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  udp_iperf_rx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 10000G -f M -t 10 -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure UDP Bidir Throughput Small Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  udp_iperf_bidir
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 10000G -f M -t 10 -J --bidir  shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}  sum_sent_bidir_reverse
    Get Throughput Values  ${output.stdout}  sum_received_bidir_reverse

Measure TCP TX Throughput Big Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  tcp_iperf_tx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t 10 -R -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure TCP RX Throughput Big Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  tcp_iperf_rx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t 10 -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure TCP Bidir Throughput Big Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  tcp_iperf_bidir
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -M 9000 -f M -t 10 -J --bidir  shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}  sum_sent_bidir_reverse
    Get Throughput Values  ${output.stdout}  sum_received_bidir_reverse

Measure UDP TX Throughput Big Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  udp_iperf_tx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t 10 -R -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure UDP RX Throughput Big Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  udp_iperf_rx
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t 10 -J   shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}

Measure UDP Bidir Throughput Big Packets
    [Documentation]  Start server on agent pc. Send data from dut to agent and measure throughput
    [Tags]  udp_iperf_bidir
    [Setup]  Run iperf server on DUT
    [Teardown]        Stop iperf server
    ${output}         Run Process  iperf3 -c ${DEVICE_IP_ADDRESS} -l 9000 -u -b 10000G -f M -t 10 -J --bidir  shell=True
    Log               ${output.stdout}
    Get Throughput Values  ${output.stdout}  sum_sent_bidir_reverse
    Get Throughput Values  ${output.stdout}  sum_received_bidir_reverse


*** Keywords ***
Common Setup
    Set Variables     ${DEVICE}
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    Connect

Run iperf server on DUT
    [Documentation]   Run iperf on DUT in server mode
    Clear iptables rules
    ${command}        Set Variable    iperf -s
    Execute Command   nohup ${command} > output.log 2>&1 &
    Check iperf was started

Run TCP test
    [Documentation]   Run network test on agent machine
    ${output}         Run Process   iperf3 -c ${DEVICE_IP_ADDRESS} -f M -t 10   shell=True
    Should Contain    ${output.stdout}    iperf Done.
    Log               ${output.stdout}
    &{tcp_speed}      Parse iperf output   ${output.stdout}
    [Return]          &{tcp_speed}

Run UDP test
    ${output}         Run Process   iperf3 -c ${DEVICE_IP_ADDRESS} -u -b 100G -f M -t 10   shell=True
    Should Contain    ${output.stdout}    iperf Done.
    Log               ${output.stdout}
    &{udp_speed}      Parse iperf output   ${output.stdout}
    [Return]          &{udp_speed}

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

Start Iperf Server
    [Documentation]  Start iperf server
    Start Process  iperf -s -D  shell=True

Get Throughput Values
    [Documentation]  Return MB per second value
    [Arguments]  ${output}  ${summary}=sum_received
    ${json_results}  Convert String To Json  ${output}
    ${values}  Get Value From Json  ${json_results}  $..${summary}
    ${MBps}  Evaluate  ${values[0]['bits_per_second']}/1000000
    Should Be True  ${MBps} > ${800}

Switch MTU
    [Documentation]  Set interface mtu to max
    [Arguments]  ${dut_if_name}=enp0s13f0u1  ${agent_if_name}=enp0s31f6  ${mtu}=1500
    Execute Command  ip link set dev ${dut_if_name} mtu ${mtu}  sudo=True  sudo_password=${PASSWORD}
    ${output}  Execute Command  ifconfig
    Log  ${output}
    ${output}  Run   sudo ip link set dev ${agent_if_name} mtu ${mtu}
    Log  ${output}
