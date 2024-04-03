# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Network performance tests
...                 Requires iperf installed on test running PC (sudo apt install iperf)
Force Tags          performance  network
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             Process
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${JOB}
Suite Setup         Common Setup
Suite Teardown      Close All Connections


*** Test Cases ***

TCP speed test
    [Documentation]   Measure RX and TX speed for TCP
    [Tags]            tcp   SP-T91  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    Run iperf server on DUT
    &{tcp_speed}      Run TCP test
    Save Speed Data   ${TEST NAME}  ${tcp_speed}
    Log               <img src="${DEVICE}_${TEST NAME}.png" alt="TCP Plot" width="1200">    HTML
    [Teardown]        Stop iperf server

UDP speed test
    [Documentation]   Measure RX and TX speed for UDP
    [Tags]            udp   SP-T92  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    Run iperf server on DUT
    &{udp_speed}      Run UDP test
    Save Speed Data   ${TEST NAME}  ${udp_speed}
    Log               <img src="${DEVICE}_${TEST NAME}.png" alt="UDP Plot" width="1200">    HTML
    [Teardown]        Stop iperf server


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
