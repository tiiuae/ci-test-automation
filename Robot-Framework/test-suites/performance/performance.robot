# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Gathering performance data
Force Tags          performance
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}
Suite Setup         Common Setup
Suite Teardown      Close All Connections


*** Test Cases ***

CPU One thread test
    [Documentation]     Run a CPU benchmark using Sysbench with a duration of 10 seconds and a SINGLE thread.
    ...                 The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-1
    ${output}           Execute Command    sysbench cpu --time=10 --threads=1 --cpu-max-prime=20000 run
    Log                 ${output}
    &{cpu_data}         Parse Cpu Results   ${output}
    Save Cpu Data       ${TEST NAME}  ${BUILD_ID}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML

CPU multimple threads test
    [Documentation]     Run a CPU benchmark using Sysbench with a duration of 10 seconds and MULTIPLE threads.
    ...                 The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-2
    ${output}           Execute Command    sysbench cpu --time=10 --threads=${threads_number} --cpu-max-prime=20000 run
    Log                 ${output}
    &{cpu_data}         Parse Cpu Results   ${output}
    Save Cpu Data       ${TEST NAME}  ${BUILD_ID}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML

Memory Read One thread test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-3
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=1 run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${BUILD_ID}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Write One thread test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-4
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=1 run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${BUILD_ID}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Read multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-5
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=${threads_number} run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${BUILD_ID}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Write multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-6
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=${threads_number} run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${BUILD_ID}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Connect
