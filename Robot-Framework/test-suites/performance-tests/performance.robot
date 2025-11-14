# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Gathering performance data
Force Tags          performance

Resource            ../../config/variables.robot
Library             ../../lib/output_parser.py
Library             ../../lib/parse_perfbench.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             Collections
Library             DateTime
Resource            ../../resources/performance_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to device
Suite Teardown      Close All Connections

*** Variables ***
@{FAILED_VM_TESTS}
@{IMPROVED_VM_TESTS}


*** Test Cases ***

nvpmodel check test
    [Documentation]     If power mode changed it would probably have an effect on performance test results.
    ...                 Ensure that the power mode level is as expected (3) on Orin AGX/NX targets. Do not apply to
    ...                 other targets.
    [Tags]              nvpmodel  SP-T175  orin-agx  orin-agx-64  orin-nx
    [Setup]             Skip If   not ("Orin" in "${DEVICE}")
    ...                 Skipped because this test does not apply to other than Orin AGX/NX targets.
    ${ExpectedNVPmode}  Set Variable  3
    ${output}           Execute Command     nvpmodel-check ${ExpectedNVPmode}
    IF  not ("Power mode check ok: ${ExpectedNVPmode}" in $output)
        FAIL  ${output}\n\nExpected: ${ExpectedNVPmode}
    END

CPU One thread test
    [Documentation]         Run a CPU benchmark using Sysbench with a duration of 10 seconds and a SINGLE thread.
    ...                     The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                     Create visual plots to represent these metrics comparing to previous tests.
    [Tags]                  cpu  SP-T61-1  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330
    ${output}               Execute Command    sysbench cpu --time=10 --threads=1 --cpu-max-prime=20000 run
    Log                     ${output}
    &{cpu_data}             Parse Cpu Results   ${output}
    &{statistics}           Save Cpu Data       ${TEST NAME}  ${cpu_data}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML
    Determine Test Status   ${statistics}

CPU multiple threads test
    [Documentation]         Run a CPU benchmark using Sysbench with a duration of 10 seconds and MULTIPLE threads.
    ...                     The benchmark records to csv CPU events per second, events per thread, and latency data.
    ...                     Create visual plots to represent these metrics comparing to previous tests.
    [Tags]                  cpu  SP-T61-2  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330
    ${output}               Execute Command    sysbench cpu --time=10 --threads=${threads_number} --cpu-max-prime=20000 run
    Log                     ${output}
    &{cpu_data}             Parse Cpu Results   ${output}
    &{statistics}           Save Cpu Data       ${TEST NAME}  ${cpu_data}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="CPU Plot" width="1200">    HTML
    Determine Test Status   ${statistics}

CPU resource isolation test
    [Documentation]         Measure the maximum impact of cpu resource exhaustion attack in single VM to other VMs.
    ...                     Run a multi-thread CPU benchmark using sysbench first in a single VM, then in two VMs
    ...                     simultaneously to simulate cpu exhaustion attack. Select the VMs with the highest vscpu
    ...                     quota (4) allocated to get the maximum effect.
    [Tags]                  cpu_isolation  SP-T298  lenovo-x1  darter-pro  dell-7330
    # Overshoot the sysbench cpu thread number in the attacking VM although qemu will/should limit it to 4.
    Single vs Parallel CPU test       reference-vm=${BUSINESS_VM}   ref_threads=4   attack-vm=${CHROME_VM}   attack_threads=20
    [Teardown]              Run Keywords    Close All Connections
    ...                     AND             Connect to ghaf host

Memory Read One thread test
    [Documentation]         Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                     The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                     and Latency for READ operations.
    ...                     Create visual plots to represent these metrics comparing to previous tests.
    [Tags]                  memory  SP-T61-3  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330
    ${output}               Execute Command    sysbench memory --time=60 --memory-oper=read --threads=1 run
    Log                     ${output}
    &{mem_data}             Parse Memory Results   ${output}
    &{statistics}           Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status   ${statistics}

Memory Write One thread test
    [Documentation]         Run a memory benchmark using Sysbench for 60 seconds with a SINGLE thread.
    ...                     The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                     and Latency for WRITE operations.
    ...                     Create visual plots to represent these metrics comparing to previous tests.
    [Tags]                  memory  SP-T61-4  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330
    ${output}               Execute Command    sysbench memory --time=60 --memory-oper=write --threads=1 run
    Log                     ${output}
    &{mem_data}             Parse Memory Results   ${output}
    &{statistics}           Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status   ${statistics}

Memory Read multiple threads test
    [Documentation]         Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                     The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                     and Latency for READ operations.
    ...                     Create visual plots to represent these metrics comparing to previous tests.
    [Tags]                  memory  SP-T61-5  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330
    ${output}               Execute Command    sysbench memory --time=60 --memory-oper=read --threads=${threads_number} run
    Log                     ${output}
    &{mem_data}             Parse Memory Results   ${output}
    ${statistics}           Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status   ${statistics}

Memory Write multiple threads test
    [Documentation]         Run a memory benchmark using Sysbench for 60 seconds with MULTIPLE threads.
    ...                     The benchmark records Operations Per Second, Data Transfer Speed, Average Events per Thread,
    ...                     and Latency for WRITE operations.
    ...                     Create visual plots to represent these metrics comparing to previous tests.
    [Tags]                  memory  SP-T61-6  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330
    ${output}               Execute Command    sysbench memory --time=60 --memory-oper=write --threads=${threads_number} run
    Log                     ${output}
    &{mem_data}             Parse Memory Results   ${output}
    &{statistics}           Save Memory Data       ${TEST NAME}  ${mem_data}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status   ${statistics}

FileIO test
    [Documentation]     Run a fileio benchmark using Sysbench for 30 seconds with MULTIPLE threads.
    ...                 The benchmark records File Operations, Throughput, Average Events per Thread,
    ...                 and Latency for read and write operations.
    ...                 Create visual plots to represent these metrics comparing to previous tests.
    ...                 KNOWN ISSUES:
    ...                 Tag removed 'nuc': SSRCSP-6126
    [Tags]              fileio  SP-T61-7  orin-agx  orin-nx  lenovo-x1  darter-pro  dell-7330

    Transfer FileIO Test Script To DUT

    # In case of Lenovo-X1 run the test in /persist which has more disk space
    # Results are saved to /tmp
    IF  "Lenovo" in "${DEVICE}" or "Darter" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Log To Console        Preparing for fileio test
        Execute Command       cp /tmp/fileio_test /persist  sudo=True  sudo_password=${PASSWORD}
        Elevate to superuser
        Write                 cd /persist
        Log To Console        Starting fileio test
        Write                 /persist/fileio_test ${threads_number} /persist
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

    Log To Console       Parsing the test results
    ${fileio_rd_output}  Execute Command    cat /tmp/sysbench_results/fileio_rd_report
    Log                  ${fileio_rd_output}
    &{fileio_rd_data}    Parse FileIO Read Results   ${fileio_rd_output}
    &{statistics_rd}     Save FileIO Data       ${TEST NAME}_read  ${fileio_rd_data}

    ${fileio_wr_output}  Execute Command    cat /tmp/sysbench_results/fileio_wr_report
    Log                  ${fileio_wr_output}
    &{fileio_wr_data}    Parse FileIO Write Results   ${fileio_wr_output}
    &{statistics_wr}     Save FileIO Data       ${TEST NAME}_write  ${fileio_wr_data}

    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_read.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_write.png" alt="Mem Plot" width="1200">   HTML

    ${stats_rd}             Output Dictionary First Value   ${statistics_rd}
    ${stats_wr}             Output Dictionary First Value   ${statistics_wr}
    &{stats_dict}    	    Create Dictionary    read=${stats_rd}  write=${stats_wr}
    Determine Test Status   ${stats_dict}

FileIO write isolation test
    [Documentation]     Run a sysbench fileio write benchmark first in a single VM then parallel in two VMs.
    ...                 Report the impact of another fileio benchmark in separate VM to the reference VM.
    [Tags]              fileio_write_isolation  SP-T303-1  lenovo-x1  darter-pro  dell-7330

    Set custom low limit   -100
    Set Global Variable    ${PERF_LOW_LIMIT}   -100

    ${reference-vm}=       Set Variable     ${COMMS_VM}
    ${attacker-vm}=        Set Variable     ${CHROME_VM}
    ${test_dir}=           Set Variable     /guestStorage/fileio

    Switch to vm           ${reference-vm}
    # Inflated memory (after boot) can affect the results
    Initial Memory Check   max_init_memory=5000  iterations=7
    Elevate to superuser
    Write                  mkdir ${test_dir}
    Write                  cd ${test_dir}
    Log To Console         Running fileio write test in single VM
    Write                  sysbench fileio --file-total-size=7G --threads=1 --file-test-mode=seqwr --time=30 run
    Sleep                  5
    ${out}                 SSHLibrary.Read Until   execution time
    Write                  sysbench fileio cleanup
    Log To Console         Parsing the test results
    &{single_data}         Parse FileIO Write Results   ${out}

    # Switch to vm           ${attacker-vm}
    # Elevate to superuser
    # Write                  mkdir ${test_dir}
    # Write                  cd ${test_dir}
    # Log To Console         Running fileio test parallel in two VMs
    # Write                  sysbench fileio --file-total-size=7G --threads=1 --file-test-mode=seqwr --time=30 run
    Sleep                  5
    Switch to vm           ${reference-vm}
    Write                  sysbench fileio --file-total-size=7G --threads=1 --file-test-mode=seqwr --time=30 run
    Sleep                  5
    ${out}                 SSHLibrary.Read Until   execution time
    Log To Console         Parsing the test results
    &{parallel_data}       Parse FileIO Write Results   ${out}

    ${single_result} 	   Get From Dictionary 	${single_data}    throughput
    ${parallel_result} 	   Get From Dictionary 	${parallel_data}  throughput
    ${difference}          Evaluate    int(${single_result}-${parallel_result})/int(${single_result})*100
    Log                    Fileio throughput single VM: ${single_data}     console=True
    Log                    Fileio throughput parallel: ${parallel_data}   console=True
    Log                    Impact of fileio test run in another VM: ${difference} %           console=True

    ${result_list}=        Create List     ${single_result}  ${parallel_result}  ${difference}
    &{statistics_dict}     Save Isolation Test Data     ${TEST NAME}  ${result_list}
    Log                    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status  ${statistics_dict}  inverted=1

    [Teardown]             Teardown of Fileio Isolation Test

FileIO read isolation test
    [Documentation]     Run a sysbench fileio read benchmark first in a single VM then parallel in two VMs.
    ...                 Report the impact of another fileio benchmark in separate VM to the reference VM.
    [Tags]              fileio_read_isolation  SP-T303-2  lenovo-x1  darter-pro  dell-7330

    Set custom low limit   -100
    Set Global Variable    ${PERF_LOW_LIMIT}   -100

    ${reference-vm}=       Set Variable     ${COMMS_VM}
    ${attacker-vm}=        Set Variable     ${CHROME_VM}
    ${test_dir}=           Set Variable     /guestStorage/fileio

    Switch to vm           ${reference-vm}
    Prepare files for fileio test in VM     7   ${test_dir}
    Log To Console         Running fileio read test in single VM
    Write                  sysbench fileio --file-total-size=7G --threads=1 --file-test-mode=seqrd --time=30 run
    Sleep                  5
    ${out}                 SSHLibrary.Read Until   execution time
    Log To Console         Parsing the test results
    &{single_data}         Parse FileIO Read Results   ${out}

    # Switch to vm           ${attacker-vm}
    # Prepare files for fileio test in VM     7   ${test_dir}
    # Log To Console         Running fileio read test parallel in two VMs
    # Write                  sysbench fileio --file-total-size=7G --threads=1 --file-test-mode=seqrd --time=30 run
    # Switch to vm           ${reference-vm}
    Sleep                  170
    Write                  sysbench fileio --file-total-size=7G --threads=1 --file-test-mode=seqrd --time=30 run
    Sleep                  5
    ${out}                 SSHLibrary.Read Until   execution time
    Log To Console         Parsing the test results
    &{parallel_data}       Parse FileIO Read Results   ${out}

    ${single_result} 	   Get From Dictionary 	${single_data}    throughput
    ${parallel_result} 	   Get From Dictionary 	${parallel_data}  throughput
    ${difference}          Evaluate    int(${single_result}-${parallel_result})/int(${single_result})*100
    Log                    Fileio throughput single VM: ${single_data}     console=True
    Log                    Fileio throughput parallel: ${parallel_data}   console=True
    Log                    Impact of fileio test run in another VM: ${difference} %           console=True

    ${result_list}=        Create List     ${single_result}  ${parallel_result}  ${difference}
    &{statistics_dict}     Save Isolation Test Data     ${TEST NAME}  ${result_list}
    Log                    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status  ${statistics_dict}  inverted=1

    [Teardown]             Teardown of Fileio Read Isolation Test   ${reference-vm}   ${attacker-vm}   ${test_dir}

Sysbench test in NetVM
    [Documentation]      Run CPU and Memory benchmark using Sysbench in NetVM.
    [Tags]               SP-T61-8  nuc  orin-agx  orin-agx-64  orin-nx

    Transfer Sysbench Test Script To NetVM
    ${output}               Execute Command    /tmp/sysbench_test 1   sudo=True  sudo_password=${PASSWORD}

    &{threads}    	        Create Dictionary	 net-vm=1
    Save sysbench results   net-vm   _1thread

    &{statistics_cpu}       Read CPU csv and plot  net-vm_${TEST NAME}_cpu_1thread
    &{statistics_mem_rd}    Read Mem csv and plot  net-vm_${TEST NAME}_memory_read_1thread
    &{statistics_mem_wr}    Read Mem csv and plot  net-vm_${TEST NAME}_memory_write_1thread

    Log    <img src="${REL_PLOT_DIR}${DEVICE}_net-vm_${TEST NAME}_cpu_1thread.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_net-vm_${TEST NAME}_memory_read_1thread.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_net-vm_${TEST NAME}_memory_write_1thread.png" alt="Mem Plot" width="1200">    HTML

    ${stats_dict}           Evaluate      dict(${statistics_cpu}, **${statistics_mem_rd}, **${statistics_mem_wr})
    Determine Test Status   ${stats_dict}

Sysbench test in VMs
    [Documentation]      Run CPU and Memory benchmark using Sysbench in Virtual Machines
    ...                  for 1 thread and MULTIPLE threads if there are more than 1 thread in VM.
    [Tags]               SP-T61-9   lenovo-x1  darter-pro  dell-7330
    &{threads}    	Create Dictionary    net-vm=1
    ...                                  gui-vm=2
    ...                                  zathura-vm=1
    ...                                  chrome-vm=4
    ...                                  comms-vm=4
    ...                                  admin-vm=1
    ...                                  audio-vm=2
    ...                                  business-vm=4
    ${vms}	Get Dictionary Keys	 ${threads}
    @{FAILED_VMS} 	Create List
    Set Global Variable  @{FAILED_VMS}

    Connect to netvm

    FOR	 ${vm}	IN	@{vms}
        ${threads_n}	Get From Dictionary	  ${threads}	 ${vm}
        ${vm_fail}      Transfer Sysbench Test Script To VM   ${vm}
        IF  '${vm_fail}' == 'FAIL'
            Log         Skipping tests for ${vm} because couldn't connect to it  console=True
        ELSE
            ${output}       Execute Command      /tmp/sysbench_test ${threads_n}  sudo=True  sudo_password=${PASSWORD}
            Run Keyword If    ${threads_n} > 1   Save sysbench results   ${vm}
            Save sysbench results   ${vm}   _1thread
            Switch Connection    ${NET-VM_GHAF_SSH}
        END
    END

    Read VMs data CSV and plot  test_name=${TEST NAME}  vms_dict=${threads}

    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_cpu_1thread.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_memory_read_1thread.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_memory_write_1thread.png" alt="Mem Plot" width="1200">    HTML

    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_cpu.png" alt="CPU Plot" width="1200">       HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_memory_read.png" alt="Mem Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_memory_write.png" alt="Mem Plot" width="1200">    HTML

    ${length}       Get Length    ${FAILED_VMS}

    ${isEmpty}    Run Keyword And Return Status    Should Be Empty    ${FAILED_VM_TESTS}
    ${fail_msg}=  Set Variable  ${EMPTY}
    IF  ${isEmpty} == False
      ${fail_msg}=  Set Variable  Deviation detected in the following tests: "${FAILED_VM_TESTS}"\n
    END
    IF  ${length} > 0
      ${fail_msg}=  Set Variable  ${fail_msg}These VMs were not tested due to connection fail: ${FAILED_VMS}
    END
    IF  ${isEmpty} == False or ${length} > 0
        FAIL  ${fail_msg}
    END

    ${isEmpty}    Run Keyword And Return Status    Should Be Empty    ${IMPROVED_VM_TESTS}
    IF  ${isEmpty} == False
      ${pass_msg}=  Set Variable  Performance improvement detected in the following tests: "${IMPROVED_VM_TESTS}"\n
      Pass Execution    ${pass_msg}
    END

Perf-Bench test
    [Documentation]  Execute Perf bench command on device and parse results using python script
    ...              Publish results in Jenkins
    [Tags]           SP-T167  riscv
    ${default_file_format}  Set Variable  perf_results_YYYY-MM-DD_BUILDER-BuildID_SDorEMMC
    ${renamed_file}  Set Variable  perf_results_${BUILD_ID}

    Log To Console  Starting perf bench test
    ${output}  Execute Command  perf-test-icicle-kit
    OperatingSystem.Create File  ${renamed_file}  ${output}
    Run Process  rm ${default_file_format}  shell=True

    Read And Plot PerfBench Results
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_perf_results.csv.png" alt="PerfBench Results" width="1200">       HTML
    Log    <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}_perf_find_bit_results.csv.png" alt="PerfBench Bit Results" width="1200">       HTML

*** Keywords ***

Transfer FileIO Test Script To DUT
    Put File           performance-tests/fileio_test    /tmp
    Execute Command    chmod 777 /tmp/fileio_test

Transfer Sysbench Test Script To NetVM
    Connect to netvm
    Put File           performance-tests/sysbench_test    /tmp
    Execute Command    chmod 777 /tmp/sysbench_test

Transfer Sysbench Test Script To VM
    [Arguments]        ${vm}    ${script_name}=sysbench_test
    IF  "${vm}" != "net-vm"
        ${vm_fail}    ${result} =    Run Keyword And Ignore Error    Connect to VM    ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Append To List	 ${FAILED_VMS}	  ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Return From Keyword  ${vm_fail}
        Log               Successfully connected to ${vm}  console=True
    END
    Put File           performance-tests/${script_name}    /tmp
    Execute Command    chmod 777 /tmp/${script_name}

Save cpu results
    [Arguments]        ${test}=cpu  ${host}=ghaf_host
    ${output}           Execute Command       cat /tmp/sysbench_results/${test}_report
    Log                 ${output}
    &{data}             Parse Cpu Results     ${output}
    &{statistics_dict}  Save Cpu Data         ${host}_${TEST NAME}_${test}  ${data}
    ${statistics}       Output Dictionary First Value   ${statistics_dict}
    IF  "${statistics}[flag]" == "-1"
        Append To List     ${FAILED_VM_TESTS}        ${host}_${test}
        Log                Deviation detected in test: ${host}_${test}  console=True
    END
    IF  "${statistics}[flag]" == "1"
        Append To List     ${IMPROVED_VM_TESTS}      ${host}_${test}
        Log                Improvement detected in test: ${host}_${test}  console=True
    END

Save memory results
    [Arguments]        ${test}=memory_read  ${host}=ghaf_host

    ${output}           Execute Command       cat /tmp/sysbench_results/${test}_report
    Log                 ${output}
    &{data}             Parse Memory Results  ${output}
    &{statistics_dict}  Save Memory Data      ${host}_${TEST NAME}_${test}  ${data}
    ${statistics}       Output Dictionary First Value   ${statistics_dict}
    IF  "${statistics}[flag]" == "-1"
        Append To List     ${FAILED_VM_TESTS}        ${host}_${test}
        Log                Deviation detected in test: ${host}_${test}  console=True
    END
    IF  "${statistics}[flag]" == "1"
        Append To List     ${IMPROVED_VM_TESTS}      ${host}_${test}
        Log                Improvement detected in test: ${host}_${test}  console=True
    END

Save sysbench results
    [Arguments]       ${host}    ${1thread}=${EMPTY}
    Log                   Saving and analyzing sysbench${1thread} results from ${host}  console=True
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

Single vs Parallel CPU test
    [Arguments]             ${reference-vm}   ${ref_threads}   ${attack-vm}   ${attack_threads}
    @{FAILED_VMS} 	        Create List
    Set Global Variable     @{FAILED_VMS}
    Transfer Sysbench Test Script To VM   ${reference-vm}   parallel_cpu_test
    Transfer Sysbench Test Script To VM   ${attack-vm}   parallel_cpu_test
    Should Be Empty         ${FAILED_VMS}

    Log To Console          Running single vm cpu test
    Switch to vm            ${reference-vm}
    ${output}               Execute Command         /tmp/parallel_cpu_test ${ref_threads} 30 /tmp/cpu_single_report
    &{single_vm_data}       Parse Cpu Results       ${output}
    Log                     ${single_vm_data}     console=True

    Log To Console          Running parallel cpu test
    ${command}              Set Variable    /tmp/parallel_cpu_test ${ref_threads} 30 /tmp/cpu_parallel_report
    Execute Command         nohup ${command} > /tmp/output.log 2>&1 &
    Switch to vm            ${attack-vm}
    Execute Command         /tmp/parallel_cpu_test ${attack_threads} 30 /tmp/cpu_parallel_report
    Switch to vm            ${reference-vm}
    ${output}               Execute Command         cat /tmp/cpu_parallel_report/cpu_report
    &{parallel_vm_data}     Parse Cpu Results       ${output}
    Log                     ${parallel_vm_data}     console=True

    ${single_vm_result}     Get From Dictionary     ${single_vm_data}   cpu_events_per_second
    ${parallel_vm_result}   Get From Dictionary     ${parallel_vm_data}   cpu_events_per_second
    ${difference}           Evaluate    int(${single_vm_result}-${parallel_vm_result})/int(${single_vm_result})*100
    Log                     ${difference} %           console=True

    ${result_list}=         Create List     ${single_vm_result}  ${parallel_vm_result}  ${difference}
    &{statistics_dict}      Save Isolation Test Data     ${TEST NAME}  ${result_list}
    Log                     <img src="${REL_PLOT_DIR}${DEVICE}_${TEST NAME}.png" alt="Mem Plot" width="1200">    HTML
    Determine Test Status   ${statistics_dict}  inverted=1

Elevate to superuser
    Write                 sudo su
    ${out}                SSHLibrary.Read Until   password for ghaf:
    ${out}                Write        ${PASSWORD}

Prepare files for fileio test in VM
    [Arguments]         ${total_size}   ${test_dir}
    Log To Console      Preparing files for fileio test
    Elevate to superuser
    Write                 mkdir ${test_dir}
    Write                 cd ${test_dir}
    Write                 sysbench fileio --file-total-size=${total_size}G --file-num=128 --threads=1 --file-test-mode=seqrd prepare
    ${iterations}         Evaluate              int(${total_size} * 20)
    FOR    ${i}    IN RANGE    ${iterations}
        Write            ls ${test_dir}
        Sleep            1
        ${file_list}     Read
        IF  "test_file.127" in $file_list
            Log To Console    Files ready for fileio read test
            RETURN
        END
    END
    FAIL    Failed to prepare files for fileio test

Teardown of Fileio Read Isolation Test
    [Arguments]                 ${reference-vm}  ${attacker-vm}  ${test_dir}
    Switch to vm                ${reference-vm}
    Execute Command             rm -r ${test_dir}   sudo=True  sudo_password=${PASSWORD}
    Switch to vm                ${attacker-vm}
    Execute Command             rm -r ${test_dir}   sudo=True  sudo_password=${PASSWORD}
    Teardown of Fileio Isolation Test

Teardown of Fileio Isolation Test
    Set default low limit
    Set Global Variable  ${PERF_LOW_LIMIT}   1
    Close All Connections
    Connect to ghaf host