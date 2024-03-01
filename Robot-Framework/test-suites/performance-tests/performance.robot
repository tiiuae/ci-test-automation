# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Gathering performance data
Force Tags          performance
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}
Suite Setup         Common Setup
Suite Teardown      Close All Connections


*** Test Cases ***

CPU One thread test
    [Documentation]     Run a CPU benchmark using Sysbench with a duration of 10 seconds and a SINGLE thread.
    ...                 The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-1  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench cpu --time=10 --threads=1 --cpu-max-prime=20000 run
    Log                 ${output}
    &{cpu_data}         Parse Cpu Results   ${output}
    Save Cpu Data       ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML

CPU multimple threads test
    [Documentation]     Run a CPU benchmark using Sysbench with a duration of 10 seconds and MULTIPLE threads.
    ...                 The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T67-2  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench cpu --time=10 --threads=${threads_number} --cpu-max-prime=20000 run
    Log                 ${output}
    &{cpu_data}         Parse Cpu Results   ${output}
    Save Cpu Data       ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML

Memory Read One thread test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T67-3  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=1 run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Write One thread test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T67-4  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=1 run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Read multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T67-5  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=${threads_number} run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Write multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T67-6  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=${threads_number} run
    Log                 ${output}
    &{cpu_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

FileIO test
    [Documentation]     Run a fileio benchmark using Sysbench for 30 seconds with MULTIPLE threads.
    ...                 The benchmark records File Operations, Throughput, Average Events per Thread,
    ...                 and Latency for read and write operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              fileio  SP-T67-7  nuc  orin-agx  orin-nx  lenovo-x1

    Transfer FileIO Test Script To DUT
    Execute Command      ./fileio_test ${threads_number}  sudo=True  sudo_password=${PASSWORD}

    ${fileio_rd_output}  Execute Command    cat sysbench_results/fileio_rd_report
    Log                  ${fileio_rd_output}
    &{fileio_rd_data}    Parse FileIO Read Results   ${fileio_rd_output}
    Save FileIO Data     ${TEST NAME}_read  ${fileio_rd_data}

    ${fileio_wr_output}  Execute Command    cat sysbench_results/fileio_wr_report
    Log                  ${fileio_wr_output}
    &{fileio_wr_data}    Parse FileIO Write Results   ${fileio_wr_output}
    Save FileIO Data     ${TEST NAME}_write  ${fileio_wr_data}

    Log    <img src="${DEVICE}_${TEST NAME}_read.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_${TEST NAME}_write.png" alt="Mem Plot" width="1200">   HTML


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Connect

Transfer FileIO Test Script To DUT
    Put File           performance-tests/fileio_test    /home/ghaf
    Execute Command    chmod 777 fileio_test
