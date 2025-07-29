# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing performance of memory ballooning
Force Tags          performance     ballooning

Resource            ../../config/variables.robot
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Resource            ../../resources/device_control.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to netvm
Suite Teardown      Close All Connections
Test Teardown       Ballooning Test Teardown
Test Timeout        10 minutes


*** Variables ***
${robot_status_file}      /tmp/ballooning_robot_status
${script_status_file}     /tmp/ballooning_script_status
${test_dir}               /tmp
${rebooted}               False


*** Test Cases ***

Test ballooning in chrome-vm
    [Tags]                  ballooning_chrome_vm    lenovo-x1   dell-7330   SP-T255
    Test ballooning in VM   vm=chrome-vm   max_init_memory=6500

Test ballooning in business-vm
    [Tags]                  ballooning_business_vm   lenovo-x1   dell-7330   SP-T256
    Test ballooning in VM   vm=business-vm   max_init_memory=6500


*** Keywords ***

Test ballooning in VM
    [Documentation]    Check if dynamic allocation of memory works when consuming a lot of memory.
    [Arguments]        ${vm}   ${max_init_memory}

    # Dell is slow. Apply slowness factor for timeouts if running on Dell.
    ${slowness_factor}=           Set Variable  1
    IF  "Dell" in "${DEVICE}"
        ${slowness_factor}=       Set Variable  2
    END

    ${inflate_passed}=                Set Variable  False
    ${deflate_passed}=                Set Variable  False
    ${init_mem_check_ok}=             Set Variable  False
    ${mem_check_iterations}=          Set Variable  7
    ${timeout1}=                      Evaluate      int(${slowness_factor} * 140)
    ${timeout2}=                      Evaluate      int(${slowness_factor} * 60)
    ${timeout3}=                      Evaluate      int(${timeout1} + ${timeout2} + 20)
    ${expected_inflate_ratio}=        Set Variable  1.7

    Connect to VM                     ${vm}     timeout=120

    FOR    ${i}    IN RANGE    ${mem_check_iterations}
        ${init_total_mem}=                Execute Command  free --mega | awk -F: 'NR==2 {print $2}' | awk '{print $1}'
        Log                               Total memory at start ${init_total_mem}  console=True
        IF  ${init_total_mem} > ${max_init_memory}
            Log To Console                Initial total memory too high. Waiting for the mem-manager to adjust it.
            Sleep  10
        ELSE
            ${init_mem_check_ok}=             Set Variable  True
            BREAK
        END
    END
    IF  $init_mem_check_ok != 'True'
        FAIL    Unexpectedly high initial total memory.\nghaf-mem-manager service of ${vm} has probably failed.
    END

    ${expected_mem_at_inflate}        Evaluate      int(${init_total_mem} * ${expected_inflate_ratio})
    Log                               Expected total memory at inflate ${expected_mem_at_inflate}  console=True
    ${consume_iterations}             Evaluate      int(${expected_mem_at_inflate} / 2)
    ${expected_deflate_mem}           Evaluate      int(${init_total_mem} + 500)
    Log                               Expected total memory at deflate ${expected_deflate_mem}  console=True

    Put File                          performance-tests/consume_memory           ${test_dir}
    Put File                          performance-tests/log_memory               ${test_dir}
    Execute Command                   chmod 777 ${test_dir}/consume_memory      sudo=True  sudo_password=${PASSWORD}
    Execute Command                   chmod 777 ${test_dir}/log_memory          sudo=True  sudo_password=${PASSWORD}

    Execute Command                   echo "stage0" > ${robot_status_file}
    Execute Command                   chmod 666 ${robot_status_file}   sudo=True  sudo_password=${PASSWORD}

    Log To Console                    Starting memory logging script
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout3} ${test_dir}/log_memory ${test_dir} ${vm}_${BUILD_ID}  sudo=True  sudo_password=${PASSWORD}  timeout=1

    Log To Console                    Starting memory consuming script
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout1} ${test_dir}/consume_memory ${consume_iterations} ${robot_status_file} ${script_status_file}  sudo=True  sudo_password=${PASSWORD}  timeout=1

    ${start_time}=                    Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout1}
        ${total_int}                  Read memory status
        IF  $total_int > $expected_mem_at_inflate
            Log To Console            Expected total memory increase detected
            ${inflate_passed}=        Set Variable   True
            Sleep   2
            Execute Command           echo "stage1" > ${robot_status_file}
            BREAK
        END
        ${inflate_process_status}=    Execute Command   cat ${script_status_file}
        IF  $inflate_process_status == 'stage1'
            Log To Console            Inflate script finished but expected total memory increase not detected
            BREAK
        END
        ${diff}=                      Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout1}
            Sleep    1
        ELSE
            Log To Console            Timeout for inflate exceeded. Expected total memory increase not detected.
            BREAK
        END
    END

    Log To Console                    Releasing memory
    Execute Command                   rm /dev/shm/test/*    sudo=True  sudo_password=${PASSWORD}
    Execute Command                   rm -r /dev/shm/test   sudo=True  sudo_password=${PASSWORD}

    ${start_time}=                    Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout2}
        ${total_int}                  Read memory status
        IF  $total_int < $expected_deflate_mem
            Log To Console            Expected total memory decrease detected
            ${deflate_passed}=        Set Variable   True
            Sleep   2
            BREAK
        END
        ${diff}=                      Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout2}
            Sleep    1
        ELSE
            BREAK
        END
    END

    Execute Command                   echo "stage2" > ${robot_status_file}
    Sleep                             2
    Get memory logs                   ${test_dir}/ballooning_${vm}_${BUILD_ID}.csv
    Plot ballooning                   ${vm}_${BUILD_ID}

    IF  $inflate_passed != 'True'
        FAIL    Total memory did not inflate to expected level
    END
    IF  $deflate_passed != 'True'
        FAIL    Total memory did not deflate to expected level
    END

Read memory status
    ${total_mem}=                 Execute Command  free --mega | awk -F: 'NR==2 {print $2}' | awk '{print $1}'
    ${available_mem}=             Execute Command  free --mega | awk -F: 'NR==2 {print $2}' | awk '{print $6}'
    Log                           Total memory: ${total_mem} / Available memory: ${available_mem}  console=True
    ${total_int}                  Evaluate    int(${total_mem})
    RETURN                        ${total_int}

Get memory logs
    [Arguments]             ${path}
    ${data_dir}             Get Data Dir
    SSHLibrary.Get File     ${path}  ${data_dir}

Plot ballooning
    [Arguments]             ${id}
    Generate Ballooning Graph    ${PLOT_DIR}   ${id}    ${TEST_NAME}
    Log   <img src="${REL_PLOT_DIR}mem_ballooning_${id}.png" alt="Power plot" width="1200">    HTML

Ballooning Test Teardown
    [Documentation]    If test gets stuck, reboot device and connect to netvm (the next test can be executed).
    ...                After reboot, the artifacts should be not existing, so no need to clean.
    Run Keyword If Timeout Occurred     Procedure After Timeout
    IF  $rebooted != 'True'
        Clean Test Artifacts
    END

Procedure After Timeout
    Reboot Laptop
    Connect to netvm
    ${rebooted}=        Set Variable  True

Clean Test Artifacts
    Execute Command     rm -r /dev/shm/test         sudo=True  sudo_password=${PASSWORD}
    Execute Command     rm ${test_dir}/ballooning*   sudo=True   sudo_password=${PASSWORD}
