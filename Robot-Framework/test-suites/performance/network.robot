# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}
Suite Setup         Common Setup
Suite Teardown      Close All Connections


*** Test Cases ***

TCP speed test
    [Documentation]   Measure RX and TX speed for TCP
    [Tags]            tcp   SP-T91
    Run iperf server on DUT
    &{tcp_speed}      Run TCP test
    Save Speed Data   ${TEST NAME}  ${buildID}  ${tcp_speed}
    Log               <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Plot" width="1200">    HTML

UDP speed test
    [Documentation]   Measure RX and TX speed for UDP
    [Tags]            udp   SP-T92
    Run iperf server on DUT
    &{udp_speed}      Run UDP test
    Save Speed Data   ${TEST NAME}  ${buildID}  ${udp_speed}
    Log               <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Plot" width="1200">    HTML


*** Keywords ***

Common Setup
    Set Variables     ${DEVICE}
    Connect
    Install iperf tool

Run iperf server on DUT
    [Documentation]   Run iperf on DUT in server mode
    ${command}        Set Variable    iperf -s
    Execute Command   nohup ${command} > output.log 2>&1 &

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
