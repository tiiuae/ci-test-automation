# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing performance of memory ballooning
Force Tags          performance     ballooning
Resource            ../../resources/ssh_keywords.resource
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}  ${PERF_DATA_DIR}  ${CONFIG_PATH}   ${PLOT_DIR}
Suite Setup         Connect to netvm
Test Teardown       Ballooning Test Teardown
Suite Teardown      Close All Connections


*** Variables ***
${test_status_file}      /tmp/ballooning_test_status


*** Test Cases ***

Test ballooning in chrome-vm
    [Tags]                  ballooning_chrome_vm    lenovo-x1   SP-T255
    Test ballooning in VM   vm=chrome-vm   expected_mem_at_inflate=11000    max_mem_wr=9000

Test ballooning in business-vm
    [Tags]                  ballooning_business_vm   lenovo-x1  SP-T256
    Test ballooning in VM   vm=business-vm   expected_mem_at_inflate=11000    max_mem_wr=9000


*** Keywords ***

Test ballooning in VM
    [Documentation]    Check if dynamic allocation of memory works when consuming a lot of memory.
    [Arguments]        ${vm}    ${expected_mem_at_inflate}  ${max_mem_wr}

    ${test_dir}=                      Set Variable  /tmp
    ${inflate_passed}=                Set Variable  False
    ${deflate_passed}=                Set Variable  False
    ${timeout1}=                      Set Variable  140
    ${timeout2}=                      Set Variable  20
    ${timeout3}=                      Evaluate      int(${timeout1} + ${timeout2} + 20)
    ${expected_mem_at_inflate}        Evaluate      int(${expected_mem_at_inflate})
    ${consume_iterations}             Evaluate      int(${max_mem_wr} / 2)

    Connect to VM                     ${vm}
    Put File                          performance-tests/consume_memory           ${test_dir}
    Put File                          performance-tests/log_memory               ${test_dir}
    Execute Command                   chmod 777 ${test_dir}/consume_memory      sudo=True  sudo_password=${PASSWORD}
    Execute Command                   chmod 777 ${test_dir}/log_memory          sudo=True  sudo_password=${PASSWORD}

    Execute Command                   echo "stage0" > ${test_status_file}
    Execute Command                   chmod 666 ${test_status_file}   sudo=True  sudo_password=${PASSWORD}
    ${init_total_mem}=                Execute Command  free --mega | awk -F: 'NR==2 {print $2}' | awk '{print $1}'
    Log                               Total memory at start ${init_total_mem}   console=True
    ${expected_deflate_mem}           Evaluate      int(${init_total_mem} + 500)

    Log To Console                    Starting memory logging script
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout3} ${test_dir}/log_memory ${test_dir} ${vm}_${BUILD_ID}  sudo=True  sudo_password=${PASSWORD}  timeout=1

    Log To Console                    Starting memory consuming script
    Run Keyword And Ignore Error      Execute Command  -b timeout ${timeout1} ${test_dir}/consume_memory ${consume_iterations} ${test_status_file}  sudo=True  sudo_password=${PASSWORD}  timeout=1

    ${start_time}=                    Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout1}
        ${total_int}                  Read memory status
        IF  $total_int > $expected_mem_at_inflate
            Log To Console            Expected total memory increase detected
            ${inflate_passed}=        Set Variable   True
            Sleep   2
            Execute Command           echo "stage1" > ${test_status_file}
            BREAK
        END
        ${inflate_process_status}=    Execute Command   cat ${test_status_file}
        IF  $inflate_process_status == 'stage1'
            BREAK
        END
        ${diff}=                      Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout1}
            Sleep    1
        ELSE
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

    Execute Command                   echo "stage2" > ${test_status_file}
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
    Execute Command     rm -r /dev/shm/test         sudo=True  sudo_password=${PASSWORD}
    Execute Command     rm ${test_status_file}      sudo=True  sudo_password=${PASSWORD}