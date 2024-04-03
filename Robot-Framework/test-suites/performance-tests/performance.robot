# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Gathering performance data
Force Tags          performance
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${JOB}
Library             Collections
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
    &{mem_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${mem_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Read multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T67-5  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=${threads_number} run
    Log                 ${output}
    &{mem_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${mem_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML

Memory Write multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T67-6  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=${threads_number} run
    Log                 ${output}
    &{mem_data}         Parse Memory Results   ${output}
    Save Memory Data    ${TEST NAME}  ${mem_data}
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

Sysbench test in NetVM
    [Documentation]      Run CPU and Memory benchmark using Sysbench in NetVM.
    [Tags]               SP-T67-8    nuc  orin-agx  orin-nx  lenovo-x1

    Transfer Sysbench Test Script To NetVM
    ${output}            Execute Command    ./sysbench_test 1  sudo=True  sudo_password=${PASSWORD}

    &{threads}    	            Create Dictionary	 net-vm=1
    Save sysbench results       net-vm   _1thread

    Read CPU csv and plot  net-vm_${TEST NAME}_cpu_1thread
    Read Mem csv and plot  net-vm_${TEST NAME}_memory_read_1thread
    Read Mem csv and plot  net-vm_${TEST NAME}_memory_write_1thread

    Log    <img src="${DEVICE}_net-vm_${TEST NAME}_cpu_1thread.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${DEVICE}_net-vm_${TEST NAME}_memory_read_1thread.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_net-vm_${TEST NAME}_memory_write_1thread.png" alt="Mem Plot" width="1200">    HTML

Sysbench test in VMs on LenovoX1
    [Documentation]      Run CPU and Memory benchmark using Sysbench in Virtual Machines
    ...                  for 1 thread and MULTIPLE threads if there are more than 1 thread in VM.
    [Tags]               SP-T67-9    lenovo-x1
    [Setup]         LenovoX1 Setup
    &{threads}    	Create Dictionary	 net-vm=1
    ...                                  gui-vm=2
    ...                                  gala-vm=2
    ...                                  zathura-vm=1
    ...                                  chromium-vm=4

    ${vms}	Get Dictionary Keys	 ${threads}

    Connect to netvm

    FOR	 ${vm}	IN	@{vms}
        ${threads_n}	Get From Dictionary	  ${threads}	 ${vm}
        Transfer Sysbench Test Script To VM   ${vm}
        ${output}       Execute Command       ./sysbench_test ${threads_n}  sudo=True  sudo_password=${PASSWORD}
        Run Keyword If    ${threads_n} > 1   Save sysbench results   ${vm}
        Save sysbench results   ${vm}   _1thread
    END

    Read VMs data CSV and plot  test_name=${TEST NAME}  vms_dict=${threads}

    Log    <img src="${DEVICE}_${TEST NAME}_cpu_1thread.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_read_1thread.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_write_1thread.png" alt="Mem Plot" width="1200">    HTML

    Log    <img src="${DEVICE}_${TEST NAME}_cpu.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_read.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_write.png" alt="Mem Plot" width="1200">    HTML

*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Connect

LenovoX1 Setup
    [Documentation]    Reboot LenovoX1     # currently it's needed, bc dns doesn't work after net-vm restarting, to be deleted after fix
    Reboot LenovoX1
    ${port_22_is_available}     Check if ssh is ready on device   timeout=180
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    Connect
    ${output}          Execute Command    ssh-keygen -R ${NETVM_IP}

Transfer FileIO Test Script To DUT
    Put File           performance-tests/fileio_test    /home/ghaf
    Execute Command    chmod 777 fileio_test

Transfer Sysbench Test Script To NetVM
    Connect to netvm
    Put File           performance-tests/sysbench_test    /home/ghaf
    Execute Command    chmod 777 sysbench_test

Transfer Sysbench Test Script To VM
    [Arguments]        ${vm}
    IF  "${vm}" != "net-vm"
        Connect to VM      ${vm}
    END
    Put File           performance-tests/sysbench_test    /home/ghaf
    Execute Command    chmod 777 sysbench_test

Save cpu results
    [Arguments]        ${test}=cpu  ${host}=ghaf_host

    ${output}          Execute Command       cat sysbench_results/${test}_report
    Log                ${output}
    &{data}            Parse Cpu Results     ${output}
    Write CPU to csv   ${host}_${TEST NAME}_${test}  ${data}

Save memory results
    [Arguments]        ${test}=memory_read  ${host}=ghaf_host

    ${output}          Execute Command       cat sysbench_results/${test}_report
    Log                ${output}
    &{data}            Parse Memory Results  ${output}
    Write Mem to csv   ${host}_${TEST NAME}_${test}  ${data}

Save sysbench results
    [Arguments]       ${host}    ${1thread}=${EMPTY}
    Save cpu results      test=cpu${1thread}           host=${host}
    Save memory results   test=memory_read${1thread}   host=${host}
    Save memory results   test=memory_write${1thread}  host=${host}
