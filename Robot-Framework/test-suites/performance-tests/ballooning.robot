# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing performance of memory ballooning
Force Tags          ballooning  performance

Resource            ../../config/variables.robot
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Resource            ../../resources/device_control.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/performance_keywords.resource

Suite Setup         Connect
Suite Teardown      Close All Connections
Test Teardown       Ballooning Test Teardown
Test Timeout        10 minutes


*** Variables ***
${test_dir}               /tmp/ballooning
${script_status_file}     /tmp/ballooning/ballooning_script_status
${rebooted}               False


*** Test Cases ***

Test ballooning in chrome-vm
    [Tags]                  SP-T255  ballooning_chrome_vm  lenovo-x1  darter-pro
    Test ballooning in VM   vm=chrome-vm   mem_quota=6144   max_inflate_ratio=3

Test ballooning in business-vm
    [Tags]                  SP-T256  ballooning_business_vm  lenovo-x1  darter-pro
    Test ballooning in VM   vm=business-vm   mem_quota=6144   max_inflate_ratio=3


*** Keywords ***

Test ballooning in VM
    [Documentation]    Check if dynamic allocation of memory works when consuming a lot of memory.
    ...                Check that memory cannot inflate over the limit (mem_quota x max_inflate_ratio).
    ...                Check that memory deflates after boot and after the consumed memory has been released.
    ...                Initial memory quotas for VMs are defined as vm.ramMb in MiB units in ghaf repository.
    ...                Give mem_quota argument in the same units: mebibytes (MiB)
    [Arguments]        ${vm}   ${mem_quota}   ${max_inflate_ratio}

    ${inflate_passed}=                Set Variable  False
    ${deflate_passed}=                Set Variable  False
    ${mem_limit_exceeded}=            Set Variable  False
    ${timeout_flag}=                  Set Variable  False

    ${expected_inflate_ratio}=        Set Variable  2
    ${expected_mem_at_inflate}        Evaluate      int(${mem_quota} * ${expected_inflate_ratio})
    ${max_mem_at_inflate}             Evaluate      int(${mem_quota} * ${max_inflate_ratio})
    ${max_init_memory}=               Evaluate      int(1.2 * ${mem_quota})

    ${timeout_inflate}=               Evaluate      int(${expected_mem_at_inflate} * 0.02)
    ${timeout_deflate}=               Evaluate      int(${expected_mem_at_inflate} * 0.005)
    ${timeout_logging}=               Evaluate      int(${timeout_inflate} + ${timeout_deflate} + 20)

    Connect to VM                     ${vm}     timeout=120

    Log                               Minimum expected total memory at inflate: ${expected_mem_at_inflate} MiB  console=True
    Log                               Maximum allowed total memory at inflate: ${max_mem_at_inflate} MiB  console=True
    Log                               Target total memory at deflate: ${max_init_memory} MiB  console=True

    Execute Command                   mkdir ${test_dir}
    Put File                          performance-tests/consume_memory          ${test_dir}
    Put File                          performance-tests/log_memory              ${test_dir}
    Execute Command                   chmod 777 ${test_dir}/consume_memory      sudo=True  sudo_password=${PASSWORD}
    Execute Command                   chmod 777 ${test_dir}/log_memory          sudo=True  sudo_password=${PASSWORD}
    Execute Command                   echo "started" > ${test_dir}/status_for_logging
    Execute Command                   mkdir ${test_dir}/script_status
    Execute Command                   rm -r ${test_dir}/script_status/*      sudo=True  sudo_password=${PASSWORD}

    Initial Memory Check              ${max_init_memory}  iterations=7

    Log To Console                    Starting memory logging script
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout_logging} ${test_dir}/log_memory ${test_dir} ${vm}_${BUILD_ID} ${test_dir}/status_for_logging  sudo=True  sudo_password=${PASSWORD}  timeout=1

    Log To Console                    Starting memory consuming scripts
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout_inflate} ${test_dir}/consume_memory /dev/shm ${test_dir}  sudo=True  sudo_password=${PASSWORD}  timeout=1
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout_inflate} ${test_dir}/consume_memory /dev ${test_dir}  sudo=True  sudo_password=${PASSWORD}  timeout=1
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout_inflate} ${test_dir}/consume_memory /run ${test_dir}  sudo=True  sudo_password=${PASSWORD}  timeout=1

    # Monitor memory during inflate
    ${start_time}=                    Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout_inflate}
        ${total_int}   ${used_mem}        Read memory status
        IF  $inflate_passed != 'True'
            IF  $total_int > $expected_mem_at_inflate
                Log To Console            2x memory ballooning reached
                ${inflate_passed}=        Set Variable   True
            END
        END
        IF  $total_int > $max_mem_at_inflate
            ${mem_limit_exceeded}=        Set Variable   True
        END

        ${scripts_finished}=          Execute Command   ls ${test_dir}/script_status | wc -l
        ${scripts_finished_int}=      Evaluate  int(${scripts_finished})
        IF  ${scripts_finished_int} > 2
            Log To Console            All memory consuming scripts finished
            BREAK
        END

        ${diff}=                      Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout_inflate}
            Sleep    4
        ELSE
            Log To Console            Timeout for inflate
            ${timeout_flag}=          Set Variable   True
            BREAK
        END
    END

    Log                               Total memory peak during inflate: ${total_int} MiB   console=True
    Log                               Used memory peak during inflate: ${used_mem} MiB   console=True

    Log To Console                    Releasing memory
    Clean Test Files

    # Monitor memory during deflate
    ${start_time}=                    Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout_deflate}
        ${total_int}   ${used_mem}    Read memory status
        IF  $total_int < $max_init_memory
            Log To Console            Expected total memory decrease detected
            ${deflate_passed}=        Set Variable   True
            BREAK
        END
        ${diff}=                      Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout_deflate}
            Sleep    2
        ELSE
            BREAK
        END
    END

    Execute Command                   echo "finish" > ${test_dir}/status_for_logging

    Sleep                             1
    Get memory logs                   ${test_dir}/ballooning_${vm}_${BUILD_ID}.csv
    Plot ballooning                   ${vm}_${BUILD_ID}

    IF  $inflate_passed != 'True'
        FAIL    Total memory did not inflate to expected level
    END
    IF  $mem_limit_exceeded == 'True'
        FAIL    VM memory limit exceeded.
    END
    IF  $deflate_passed != 'True'
        FAIL    Total memory did not deflate to expected level
    END
    IF  $timeout_flag == 'True'
        FAIL    Memory consuming scripts failed to finish. Need to investigate if something is wrong or timeout value just too small.
    END

Read memory status
    ${total_mem}=                 Execute Command  free --mebi | awk -F: 'NR==2 {print $2}' | awk '{print $1}'
    ${used_mem}=                  Execute Command  free --mebi | awk -F: 'NR==2 {print $2}' | awk '{print $2}'
    Log                           Used memory: ${used_mem} / Total memory: ${total_mem}  console=True
    ${total_int}                  Evaluate    int(${total_mem})
    RETURN                        ${total_int}   ${used_mem}

Get memory logs
    [Arguments]             ${path}
    ${data_dir}             Get Data Dir
    SSHLibrary.Get File     ${path}  ${data_dir}

Plot ballooning
    [Arguments]             ${id}
    Generate Ballooning Graph    ${PLOT_DIR}   ${id}    ${TEST_NAME}
    Log   <img src="${REL_PLOT_DIR}mem_ballooning_${id}.png" alt="Power plot" width="1200">    HTML

Procedure After Timeout
    Reboot Laptop
    Check If Device Is Up
    Sleep  30
    Connect                  iterations=10
    ${rebooted}=             Set Variable  True

Clean Test Files
    Execute Command   rm /dev/shm/test/*      sudo=True  sudo_password=${PASSWORD}
    Execute Command   rm /dev/test/*          sudo=True  sudo_password=${PASSWORD}
    Execute Command   rm /run/test/*          sudo=True  sudo_password=${PASSWORD}
    Execute Command   rm -r /dev/shm/test     sudo=True  sudo_password=${PASSWORD}
    Execute Command   rm -r /dev/test         sudo=True  sudo_password=${PASSWORD}
    Execute Command   rm -r /run/test         sudo=True  sudo_password=${PASSWORD}

Ballooning Test Teardown
    [Documentation]    If test gets stuck, reboot device and connect to netvm (the next test can be executed).
    ...                After reboot, the artifacts should be not existing, so no need to clean.
    Run Keyword If Timeout Occurred     Procedure After Timeout
    Run Keyword If   '${TEST STATUS}' == 'FAIL' and 'SSHException' in '${TEST MESSAGE}'   Procedure After Timeout
    IF  $rebooted != 'True'
        Clean Test Files
        Execute Command   rm -r ${test_dir}   sudo=True  sudo_password=${PASSWORD}
    END
