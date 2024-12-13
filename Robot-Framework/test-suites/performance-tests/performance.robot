# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Gathering performance data
Force Tags          performance
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/performance_keywords.resource
Library             ../../lib/output_parser.py
Library             ../../lib/parse_perfbench.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${JOB}
Library             Collections
Library             DateTime
Suite Setup         Common Setup
Suite Teardown      Close All Connections

*** Variables ***
@{failed_VM_tests}
@{improved_VM_tests}


*** Test Cases ***

nvpmodel check test
    [Documentation]     If power mode changed it would probably have an effect on performance test results.
    ...                 Ensure that the power mode level is as expected (3) on Orin AGX/NX targets. Do not apply to
    ...                 other targets.
    [Tags]              nvpmodel  SP-T175  orin-agx  orin-nx
    [Setup]             Skip If   not ("Orin" in "${DEVICE}")
    ...                 Skipped because this test does not apply to other than Orin AGX/NX targets.
    ${ExpectedNVPmode}  Set Variable  3
    ${output}           Execute Command     nvpmodel-check ${ExpectedNVPmode}
    IF  not ("Power mode check ok: ${ExpectedNVPmode}" in $output)
        FAIL  ${output}\n\nExpected: ${ExpectedNVPmode}
    END

CPU One thread test
    [Documentation]     Run a CPU benchmark using Sysbench with a duration of 10 seconds and a SINGLE thread.
    ...                 The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T61-1  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench cpu --time=10 --threads=1 --cpu-max-prime=20000 run
    Log                 ${output}
    &{cpu_data}         Parse Cpu Results   ${output}
    &{statistics}       Save Cpu Data       ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML
    IF  "${statistics}[flag]" == "-1"
        ${fail_msg}     Create fail message  ${statistics}
        FAIL            ${fail_msg}
    END
    IF  "${statistics}[flag]" == "1"
        ${pass_msg}     Create improved message  ${statistics}
        Pass Execution            ${pass_msg}
    END

CPU multimple threads test
    [Documentation]     Run a CPU benchmark using Sysbench with a duration of 10 seconds and MULTIPLE threads.
    ...                 The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              cpu  SP-T61-2  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench cpu --time=10 --threads=${threads_number} --cpu-max-prime=20000 run
    Log                 ${output}
    &{cpu_data}         Parse Cpu Results   ${output}
    &{statistics}       Save Cpu Data       ${TEST NAME}  ${cpu_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML
    IF  "${statistics}[flag]" == "-1"
        ${fail_msg}     Create fail message  ${statistics}
        FAIL            ${fail_msg}
    END
    IF  "${statistics}[flag]" == "1"
        ${pass_msg}     Create improved message  ${statistics}
        Pass Execution            ${pass_msg}
    END

Memory Read One thread test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T61-3  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=1 run
    Log                 ${output}
    &{mem_data}         Parse Memory Results   ${output}
    &{statistics}       Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    IF  "${statistics}[flag]" == "-1"
        ${fail_msg}     Create fail message  ${statistics}
        FAIL            ${fail_msg}
    END
    IF  "${statistics}[flag]" == "1"
        ${pass_msg}     Create improved message  ${statistics}
        Pass Execution            ${pass_msg}
    END

Memory Write One thread test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T61-4  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=1 run
    Log                 ${output}
    &{mem_data}         Parse Memory Results   ${output}
    &{statistics}       Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    IF  "${statistics}[flag]" == "-1"
        ${fail_msg}     Create fail message  ${statistics}
        FAIL            ${fail_msg}
    END
    IF  "${statistics}[flag]" == "1"
        ${pass_msg}     Create improved message  ${statistics}
        Pass Execution            ${pass_msg}
    END

Memory Read multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for READ operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T61-5  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=read --threads=${threads_number} run
    Log                 ${output}
    &{mem_data}         Parse Memory Results   ${output}
    ${statistics}       Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    IF  "${statistics}[flag]" == "-1"
        ${fail_msg}     Create fail message  ${statistics}
        FAIL            ${fail_msg}
    END
    IF  "${statistics}[flag]" == "1"
        ${pass_msg}     Create improved message  ${statistics}
        Pass Execution            ${pass_msg}
    END

Memory Write multimple threads test
    [Documentation]     Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                 The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                 and Latency for WRITE operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              memory  SP-T61-6  nuc  orin-agx  orin-nx  lenovo-x1
    ${output}           Execute Command    sysbench memory --time=60 --memory-oper=write --threads=${threads_number} run
    Log                 ${output}
    &{mem_data}         Parse Memory Results   ${output}
    &{statistics}       Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                 <img src="${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    IF  "${statistics}[flag]" == "-1"
        ${fail_msg}     Create fail message  ${statistics}
        FAIL            ${fail_msg}
    END
    IF  "${statistics}[flag]" == "1"
        ${pass_msg}     Create improved message  ${statistics}
        Pass Execution            ${pass_msg}
    END

FileIO test
    [Documentation]     Run a fileio benchmark using Sysbench for 30 seconds with MULTIPLE threads.
    ...                 The benchmark records File Operations, Throughput, Average Events per Thread,
    ...                 and Latency for read and write operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    [Tags]              fileio  SP-T61-7  nuc  orin-agx  orin-nx  lenovo-x1

    Transfer FileIO Test Script To DUT

    # In case of Lenovo-X1 run the test in /gp_storage which has more disk space
    # Results are saved to /tmp
    IF  "Lenovo" in "${DEVICE}"
        Execute Command       cp /tmp/fileio_test /gp_storage  sudo=True  sudo_password=${PASSWORD}
        Write                 sudo su
        ${out}                SSHLibrary.Read Until   password for ghaf:
        ${out}                Write        ${PASSWORD}
        Write                 cd /gp_storage
        Write                 /gp_storage/fileio_test ${threads_number} /gp_storage
        Set Client Configuration	  timeout=900
        ${out}                SSHLibrary.Read Until   Test finished.
        Set Client Configuration	  timeout=30
        Log                  ${out}
    ELSE
        Execute Command      /tmp/fileio_test ${threads_number}  sudo=True  sudo_password=${PASSWORD}
    END

    ${test_info}  Execute Command    cat /tmp/sysbench_results/test_info
    IF  "Insufficient disk space" in $test_info
        FAIL            Insufficient disk space for fileio test.
    END

    Log to console       Parsing the test results
    ${fileio_rd_output}  Execute Command    cat /tmp/sysbench_results/fileio_rd_report
    Log                  ${fileio_rd_output}
    &{fileio_rd_data}    Parse FileIO Read Results   ${fileio_rd_output}
    &{statistics_rd}     Save FileIO Data       ${TEST NAME}_read  ${fileio_rd_data}

    ${fileio_wr_output}  Execute Command    cat /tmp/sysbench_results/fileio_wr_report
    Log                  ${fileio_wr_output}
    &{fileio_wr_data}    Parse FileIO Write Results   ${fileio_wr_output}
    &{statistics_wr}     Save FileIO Data       ${TEST NAME}_write  ${fileio_wr_data}

    Log    <img src="${DEVICE}_${TEST NAME}_read.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_${TEST NAME}_write.png" alt="Mem Plot" width="1200">   HTML

    ${fail_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_rd}[flag]" == "-1"
        ${add_msg}     Create fail message  ${statistics_rd}
        ${fail_msg}=    Set Variable  READ:\n${add_msg}
    END
    IF  "${statistics_wr}[flag]" == "-1"
        ${add_msg}      Create fail message  ${statistics_wr}
        ${fail_msg}=    Set Variable  ${fail_msg}\nWRITE:\n${add_msg}
    END
    IF  "${statistics_rd}[flag]" == "-1" or "${statistics_wr}[flag]" == "-1"
        FAIL            ${fail_msg}
    END

    ${pass_msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_rd}[flag]" == "1"
        ${add_msg}     Create improved message  ${statistics_rd}
        ${pass_msg}=    Set Variable  READ:\n${add_msg}
    END
    IF  "${statistics_wr}[flag]" == "1"
        ${add_msg}      Create improved message  ${statistics_wr}
        ${pass_msg}=    Set Variable  ${pass_msg}\nWRITE:\n${add_msg}
    END
    IF  "${statistics_rd}[flag]" == "1" or "${statistics_wr}[flag]" == "1"
        Pass Execution    ${pass_msg}
    END

Sysbench test in NetVM
    [Documentation]      Run CPU and Memory benchmark using Sysbench in NetVM.
    [Tags]               SP-T61-8    nuc  orin-agx  orin-nx

    Transfer Sysbench Test Script To NetVM
    ${output}            Execute Command    ./sysbench_test 1  sudo=True  sudo_password=${PASSWORD}

    &{threads}    	            Create Dictionary	 net-vm=1
    Save sysbench results       net-vm   _1thread

    &{statistics_cpu}       Read CPU csv and plot  net-vm_${TEST NAME}_cpu_1thread
    &{statistics_mem_rd}    Read Mem csv and plot  net-vm_${TEST NAME}_memory_read_1thread
    &{statistics_mem_wr}    Read Mem csv and plot  net-vm_${TEST NAME}_memory_write_1thread

    Log    <img src="${DEVICE}_net-vm_${TEST NAME}_cpu_1thread.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${DEVICE}_net-vm_${TEST NAME}_memory_read_1thread.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_net-vm_${TEST NAME}_memory_write_1thread.png" alt="Mem Plot" width="1200">    HTML

    ${msg}=  Set Variable  ${EMPTY}
    IF  "${statistics_cpu}[flag]" == "-1"
        ${add_msg}      Create fail message  ${statistics_cpu}
        ${msg}=    Set Variable  CPU:\n${add_msg}
    END
    IF  "${statistics_cpu}[flag]" == "1"
        ${add_msg}      Create improved message  ${statistics_cpu}
        ${msg}=    Set Variable  CPU:\n${add_msg}
    END
    IF  "${statistics_mem_rd}[flag]" == "-1"
        ${add_msg}      Create fail message  ${statistics_mem_rd}
        ${fail_msg}=    Set Variable  ${msg}\nMEM READ:\n${add_msg}
    END
    IF  "${statistics_mem_rd}[flag]" == "1"
        ${add_msg}      Create improved message  ${statistics_mem_rd}
        ${msg}=    Set Variable  ${msg}\nMEM READ:\n${add_msg}
    END
    IF  "${statistics_mem_wr}[flag]" == "-1"
        ${add_msg}      Create fail message  ${statistics_mem_wr}
        ${fail_msg}=    Set Variable  ${msg}\nMEM WRITE:\n${add_msg}
    END
    IF  "${statistics_mem_wr}[flag]" == "1"
        ${add_msg}      Create improved message  ${statistics_mem_wr}
        ${msg}=    Set Variable  ${msg}\nMEM WRITE:\n${add_msg}
    END
    IF  "${statistics_cpu}[flag]" == "-1" or "${statistics_mem_rd}[flag]" == "-1" or "${statistics_mem_wr}[flag]" == "-1"
        FAIL  ${msg}
    END
    IF  "${statistics_cpu}[flag]" == "1" or "${statistics_mem_rd}[flag]" == "1" or "${statistics_mem_wr}[flag]" == "1"
        Pass Execution    ${msg}
    END

Sysbench test in VMs on LenovoX1
    [Documentation]      Run CPU and Memory benchmark using Sysbench in Virtual Machines
    ...                  for 1 thread and MULTIPLE threads if there are more than 1 thread in VM.
    [Tags]               SP-T61-9
    &{threads}    	Create Dictionary    net-vm=1
    ...                                  gui-vm=2
    ...                                  gala-vm=2
    ...                                  zathura-vm=1
    ...                                  chrome-vm=4
    ...                                  comms-vm=4
    ...                                  admin-vm=1
    ...                                  audio-vm=1
    ${vms}	Get Dictionary Keys	 ${threads}
    @{failed_vms} 	Create List
    Set Global Variable  @{failed_vms}

    Connect to netvm

    FOR	 ${vm}	IN	@{vms}
        ${threads_n}	Get From Dictionary	  ${threads}	 ${vm}
        ${vm_fail}      Transfer Sysbench Test Script To VM   ${vm}
        IF  '${vm_fail}' == 'FAIL'
            Log to Console  Skipping tests for ${vm} because couldn't connect to it
        ELSE
            ${output}       Execute Command      /tmp/sysbench_test ${threads_n}  sudo=True  sudo_password=${PASSWORD}
            Run Keyword If    ${threads_n} > 1   Save sysbench results   ${vm}
            Save sysbench results   ${vm}   _1thread
            Switch Connection    ${netvm_ssh}
        END
    END

    Read VMs data CSV and plot  test_name=${TEST NAME}  vms_dict=${threads}

    Log    <img src="${DEVICE}_${TEST NAME}_cpu_1thread.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_read_1thread.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_write_1thread.png" alt="Mem Plot" width="1200">    HTML

    Log    <img src="${DEVICE}_${TEST NAME}_cpu.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_read.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${DEVICE}_${TEST NAME}_memory_write.png" alt="Mem Plot" width="1200">    HTML

    ${length}       Get Length    ${failed_vms}

    ${isEmpty}    Run Keyword And Return Status    Should Be Empty    ${failed_VM_tests}
    ${fail_msg}=  Set Variable  ${EMPTY}
    IF  ${isEmpty} == False
      ${fail_msg}=  Set Variable  Deviation detected in the following tests: "${failed_VM_tests}"\n
    END
    IF  ${length} > 0
      ${fail_msg}=  Set Variable  ${fail_msg}These VMs were not tested due to connection fail: ${failed_vms}
    END
    IF  ${isEmpty} == False or ${length} > 0
        FAIL  ${fail_msg}
    END

    ${isEmpty}    Run Keyword And Return Status    Should Be Empty    ${improved_VM_tests}
    IF  ${isEmpty} == False
      ${pass_msg}=  Set Variable  Performance improvement detected in the following tests: "${improved_VM_tests}"\n
      Pass Execution    ${pass_msg}
    END

Perf-Bench test
    [Documentation]  Execute Perf bench command on device and parse results using python script
    ...              Publish results in Jenkins
    [Tags]           SP-T167  riscv
    ${default_file_format}  Set Variable  perf_results_YYYY-MM-DD_BUILDER-BuildID_SDorEMMC
    ${renamed_file}  Set Variable  perf_results_${BUILD_ID}

    Log to console  Starting perf bench test
    ${output}  Execute Command  perf-test-icicle-kit
    OperatingSystem.Create File  ${renamed_file}  ${output}
    Run Process  rm ${default_file_format}  shell=True

    Read And Plot PerfBench Results
    Log    <img src="${DEVICE}_${TEST NAME}_perf_results.csv.png" alt="PerfBench Results" width="1200">       HTML
    Log    <img src="${DEVICE}_${TEST NAME}_perf_find_bit_results.csv.png" alt="PerfBench Bit Results" width="1200">       HTML

*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    Connect

LenovoX1 Setup
    [Documentation]    Reboot LenovoX1
    Reboot LenovoX1
    ${port_22_is_available}     Check if ssh is ready on device   timeout=180
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    Connect
    ${output}          Execute Command    ssh-keygen -R ${NETVM_IP}

Transfer FileIO Test Script To DUT
    Put File           performance-tests/fileio_test    /tmp
    Execute Command    chmod 777 /tmp/fileio_test

Transfer Sysbench Test Script To NetVM
    Connect to netvm
    Put File           performance-tests/sysbench_test    /tmp
    Execute Command    chmod 777 /tmp/sysbench_test

Transfer Sysbench Test Script To VM
    [Arguments]        ${vm}
    IF  "${vm}" != "net-vm"
        ${vm_fail}    ${result} =    Run Keyword And Ignore Error    Connect to VM    ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Append To List	 ${failed_vms}	  ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Return From Keyword  ${vm_fail}
        Log to console    Successfully connected to ${vm}
    END
    Put File           performance-tests/sysbench_test    /tmp
    Execute Command    chmod 777 /tmp/sysbench_test

Save cpu results
    [Arguments]        ${test}=cpu  ${host}=ghaf_host

    ${output}          Execute Command       cat sysbench_results/${test}_report
    Log                ${output}
    &{data}            Parse Cpu Results     ${output}
    &{statistics}      Save Cpu Data         ${host}_${TEST NAME}_${test}  ${data}
    IF  "${statistics}[flag]" == "-1"
        Append To List     ${failed_VM_tests}        ${host}_${test}
        Log to console     Deviation detected in test: ${host}_${test}
    END
    IF  "${statistics}[flag]" == "1"
        Append To List     ${improved_VM_tests}      ${host}_${test}
        Log to console     Improvement detected in test: ${host}_${test}
    END

Save memory results
    [Arguments]        ${test}=memory_read  ${host}=ghaf_host

    ${output}          Execute Command       cat sysbench_results/${test}_report
    Log                ${output}
    &{data}            Parse Memory Results  ${output}
    &{statistics}      Save Memory Data      ${host}_${TEST NAME}_${test}  ${data}
    IF  "${statistics}[flag]" == "-1"
        Append To List     ${failed_VM_tests}        ${host}_${test}
        Log to console     Deviation detected in test: ${host}_${test}
    END
    IF  "${statistics}[flag]" == "1"
        Append To List     ${improved_VM_tests}      ${host}_${test}
        Log to console     Improvement detected in test: ${host}_${test}
    END

Save sysbench results
    [Arguments]       ${host}    ${1thread}=${EMPTY}
    Save cpu results      test=cpu${1thread}           host=${host}
    Save memory results   test=memory_read${1thread}   host=${host}
    Save memory results   test=memory_write${1thread}  host=${host}

Read And Plot PerfBench Results
    [Documentation]  Copy normalised perfbench results to combined csv file on agent
    ${src_results}  Set Variable  perf_results.csv
    ${src_find_bit_results}  Set Variable  perf_find_bit_results.csv

    ${perf_results_header}  ${perf_bit_results_header}   Parse and Copy Perfbench To Csv
    Log  ${perf_results_header}
    Log  ${perf_bit_results_header}
    Read Perfbench Csv And Plot  ${TEST NAME}  ${src_results}  ${perf_results_header}
    Read Perfbench Csv And Plot  ${TEST NAME}  ${src_find_bit_results}  ${perf_bit_results_header}
