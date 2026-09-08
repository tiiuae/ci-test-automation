# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing performance of memory ballooning
Test Tags           ballooning

Resource            ../../config/variables.robot
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Resource            ../../resources/device_control.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/performance_keywords.resource

Suite Teardown      Close All Connections
Test Teardown       Ballooning Test Teardown
Test Timeout        10 minutes


*** Variables ***
${test_dir}               /tmp/ballooning
${script_status_file}     /tmp/ballooning/ballooning_script_status
${host_status_file}       /tmp/ballooning/host_ballooning_status
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
    [Documentation]    Check that the host-side balloon manager changes the VM visible-memory target.
    ...                Check that memory cannot grow over the limit (mem_quota x max_inflate_ratio).
    ...                Check that the visible-memory target is reduced after the consumed memory has been released.
    ...                Initial memory quotas for VMs are defined in MiB units in ghaf repository.
    ...                Give mem_quota argument in the same units: mebibytes (MiB)
    [Arguments]        ${vm}   ${mem_quota}   ${max_inflate_ratio}

    Set Test Variable                 ${ballooning_vm}                  ${vm}
    Set Test Variable                 ${ballooning_id}                  ${vm}_${BUILD_ID}

    ${expected_inflate_ratio}=        Set Variable  2
    ${expected_mem_at_inflate}        Evaluate      int(${mem_quota} * ${expected_inflate_ratio})
    ${max_mem_at_inflate}             Evaluate      int(${mem_quota} * ${max_inflate_ratio})
    ${max_deflated_memory}=           Evaluate      int(1.2 * ${mem_quota})

    ${timeout_inflate}=               Evaluate      int(${expected_mem_at_inflate} * 0.02)
    ${timeout_deflate}=               Evaluate      int(${expected_mem_at_inflate} * 0.005)
    ${timeout_logging}=               Evaluate      int(${timeout_inflate} + ${timeout_deflate} + 20)

    Switch to vm                      ${HOST}
    ${journal_start}=                 Run Command   date +%s
    Run Command                       systemctl is-active ghaf-mem-manager-${vm}.service
    ${host_avail_before}=             Read Host Available Memory
    Run Command                       mkdir ${test_dir}                         rc_match=skip
    Put File                          performance-tests/log_host_ballooning     ${test_dir}
    Run Command                       chmod 777 ${test_dir}/log_host_ballooning
    Run Command                       echo "started" > ${host_status_file}

    ${host_log_cmd}=                  Catenate
    ...                               nohup timeout ${timeout_logging} ${test_dir}/log_host_ballooning ${test_dir}
    ...                               ${vm}_${BUILD_ID} ${host_status_file} ${vm} ${journal_start}
    ...                               > ${test_dir}/host_logger.log 2>&1 &
    Run Command                       ${host_log_cmd}    timeout=3

    Switch to vm                      ${vm}     timeout=120

    Log                               Minimum expected visible memory target: ${expected_mem_at_inflate} MiB
    ...                               console=True
    Log                               Maximum allowed visible memory target: ${max_mem_at_inflate} MiB  console=True
    Log                               Target visible memory after cleanup: ${max_deflated_memory} MiB  console=True

    Run Command                       mkdir ${test_dir}                         rc_match=skip
    Put File                          performance-tests/consume_memory          ${test_dir}
    Put File                          performance-tests/log_memory              ${test_dir}
    Run Command                       chmod 777 ${test_dir}/consume_memory
    Run Command                       chmod 777 ${test_dir}/log_memory
    Run Command                       echo "started" > ${test_dir}/status_for_logging
    Run Command                       mkdir ${test_dir}/script_status           rc_match=skip
    Run Command                       rm -r ${test_dir}/script_status/*         rc_match=skip

    Log To Console                    Starting memory logging script
    ${log_cmd}=                       Catenate
    ...                               nohup timeout ${timeout_logging} ${test_dir}/log_memory ${test_dir}
    ...                               ${vm}_${BUILD_ID} ${test_dir}/status_for_logging
    ...                               > ${test_dir}/vm_logger.log 2>&1 &
    Run Command                       ${log_cmd}    timeout=3

    Log To Console                    Starting memory consuming scripts
    Log To Console                    Launching memory consume at /dev/shm
    ${shm_cmd}=                       Catenate
    ...                               sudo -n nohup timeout ${timeout_inflate}
    ...                               ${test_dir}/consume_memory /dev/shm ${test_dir}
    ...                               > ${test_dir}/consume_shm.log 2>&1 &
    Run Command                       ${shm_cmd}    timeout=3
    Log To Console                    Launching memory consume at /dev
    ${dev_cmd}=                       Catenate
    ...                               sudo -n nohup timeout ${timeout_inflate}
    ...                               ${test_dir}/consume_memory /dev ${test_dir}
    ...                               > ${test_dir}/consume_dev.log 2>&1 &
    Run Command                       ${dev_cmd}    timeout=3
    Log To Console                    Launching memory consume at /run
    ${run_cmd}=                       Catenate
    ...                               sudo -n nohup timeout ${timeout_inflate}
    ...                               ${test_dir}/consume_memory /run ${test_dir}
    ...                               > ${test_dir}/consume_run.log 2>&1 &
    Run Command                       ${run_cmd}    timeout=3

    Switch to vm                      ${HOST}
    ${min_target}   ${max_target}=    Wait For Balloon Target  ${vm}  ${journal_start}  increase
    ...                               ${expected_mem_at_inflate}  ${timeout_inflate}
    ${host_memory_delta_limit}=       Evaluate    int(max(1024, ($max_target - $min_target) * 0.25))
    ${host_avail_pressure}=           Wait For Host Available Memory  decrease
    ...                               ${host_avail_before}  ${host_memory_delta_limit}  ${timeout_inflate}
    ${host_avail_drop}=               Evaluate    $host_avail_before - $host_avail_pressure

    Log                               Balloon target min during pressure: ${min_target} MiB   console=True
    Log                               Balloon target max during pressure: ${max_target} MiB   console=True
    Log                               Expected host MemAvailable change: ${host_memory_delta_limit} MiB
    ...                               console=True
    Log                               Host available memory drop: ${host_avail_drop} MiB   console=True

    Should Be True                    $max_target <= $max_mem_at_inflate
    ...                               VM visible-memory target exceeded configured maximum.

    Log To Console                    Releasing memory
    Switch to vm                      ${HOST}
    ${release_time}=                  Run Command   date +%s
    Switch to vm                      ${vm}
    Clean Test Files

    Switch to vm                      ${HOST}
    ${min_target}   ${max_target}=    Wait For Balloon Target  ${vm}  ${release_time}  decrease
    ...                               ${max_deflated_memory}  ${timeout_deflate}
    ${host_avail_after}=              Wait For Host Available Memory  close-to-reference
    ...                               ${host_avail_before}  ${host_memory_delta_limit}  ${timeout_deflate}
    ${host_avail_recovery}=           Evaluate    $host_avail_after - $host_avail_pressure
    Log                               Balloon target min after cleanup: ${min_target} MiB   console=True
    Log                               Balloon target max after cleanup: ${max_target} MiB   console=True
    Log                               Host available memory recovery: ${host_avail_recovery} MiB   console=True

    Switch to vm                      ${vm}
    Run Command                       echo "finished" > ${test_dir}/status_for_logging
    Switch to vm                      ${HOST}
    Run Command                       echo "finished" > ${host_status_file}
    Get host memory logs              ${test_dir}/ballooning_host_${vm}_${BUILD_ID}.csv

    Switch to vm                      ${vm}
    Sleep                             1
    Get memory logs                   ${test_dir}/ballooning_${vm}_${BUILD_ID}.csv
    Plot ballooning                   ${vm}_${BUILD_ID}
    Clean Ballooning Test Files

Read memory status
    ${total_mem}=                 Run Command  free --mebi | awk -F: 'NR==2 {print $2}' | awk '{print $1}'  timeout=5
    ${used_mem}=                  Run Command  free --mebi | awk -F: 'NR==2 {print $2}' | awk '{print $2}'  timeout=5
    ${avail_mem}=                 Run Command  free --mebi | awk -F: 'NR==2 {print $2}' | awk '{print $6}'  timeout=5
    Log                           Used memory: ${used_mem} / Available: ${avail_mem} / Total: ${total_mem}
    ...                           console=True
    ${total_int}                  Evaluate    int(${total_mem})
    ${avail_int}                  Evaluate    int(${avail_mem})
    RETURN                        ${total_int}   ${used_mem}   ${avail_int}

Read Host Available Memory
    ${host_avail}=            Run Command
    ...                       awk '/MemAvailable:/ { print int($2/1024) }' /proc/meminfo
    ...                       timeout=5
    Log                       Host available memory: ${host_avail} MiB   console=True
    ${host_avail_int}=        Evaluate    int(${host_avail})
    RETURN                    ${host_avail_int}

Wait For Host Available Memory
    [Arguments]             ${direction}  ${reference}  ${delta_limit}  ${timeout}
    ${start_time}=          Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout}
        ${host_avail}=      Read Host Available Memory
        ${delta}=           Evaluate    $reference - $host_avail
        IF  '${direction}' == 'decrease' and $delta >= $delta_limit
            Log To Console  Expected host MemAvailable decrease detected
            RETURN          ${host_avail}
        END
        ${delta}=           Evaluate    abs($host_avail - $reference)
        IF  '${direction}' == 'close-to-reference' and $delta <= $delta_limit
            Log To Console  Expected host MemAvailable recovery detected
            RETURN          ${host_avail}
        END
        ${diff}=            Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout}
            Sleep           2
        ELSE
            BREAK
        END
    END
    FAIL    Host MemAvailable did not show expected ${direction} of ${delta_limit} MiB within ${timeout} sec.

Get Balloon Target Range
    [Arguments]             ${vm}  ${since}
    ${cmd}=                 Catenate
    ...                     journalctl -b -u ghaf-mem-manager-${vm}.service --since "@${since}" --no-pager |
    ...                     awk '/Adjusting .*${vm}\\.sock/ { mib=int($NF/1024/1024);
    ...                     if (mib>max) max=mib; if (min==0 || mib<min) min=mib }
    ...                     END { print min+0, max+0 }'
    ${target_range}=        Run Command   ${cmd}   timeout=10
    @{parts}=               Split String  ${target_range}
    ${min_target}=          Evaluate      int($parts[0])
    ${max_target}=          Evaluate      int($parts[1])
    RETURN                  ${min_target}   ${max_target}

Wait For Balloon Target
    [Arguments]             ${vm}  ${since}  ${direction}  ${limit}  ${timeout}
    ${start_time}=          Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout}
        ${min_target}   ${max_target}=    Get Balloon Target Range  ${vm}  ${since}
        IF  '${direction}' == 'increase' and $max_target >= $limit
            Log To Console    Expected balloon target increase detected
            RETURN            ${min_target}   ${max_target}
        END
        IF  '${direction}' == 'decrease' and $min_target > 0 and $min_target <= $limit
            Log To Console    Expected balloon target decrease detected
            RETURN            ${min_target}   ${max_target}
        END
        ${diff}=              Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout}
            Sleep             2
        ELSE
            BREAK
        END
    END
    FAIL    Balloon target did not ${direction} to ${limit} MiB within ${timeout} sec.

Get memory logs
    [Arguments]             ${path}
    ${data_dir}             Get Data Dir
    SSHLibrary.Get File     ${path}  ${data_dir}

Get host memory logs
    [Arguments]             ${path}
    ${data_dir}             Get Data Dir
    SSHLibrary.Get File     ${path}  ${data_dir}

Collect Ballooning Logs And Plot
    ${vm}=                  Get Variable Value  ${ballooning_vm}  ${EMPTY}
    ${id}=                  Get Variable Value  ${ballooning_id}  ${EMPTY}
    IF  $vm == '' or $id == ''
        RETURN
    END

    TRY
        Switch to vm            ${HOST}
        Run Command             echo "finished" > ${host_status_file}
        Sleep                   1
        Get host memory logs    ${test_dir}/ballooning_host_${id}.csv
    EXCEPT    AS    ${err}
        Log    Could not collect host ballooning logs: ${err}    level=WARN
    END

    TRY
        Switch to vm            ${vm}
        Run Command             echo "finished" > ${test_dir}/status_for_logging
        Sleep                   1
        Get memory logs         ${test_dir}/ballooning_${id}.csv
    EXCEPT    AS    ${err}
        Log    Could not collect VM ballooning logs: ${err}    level=WARN
    END

    TRY
        Plot ballooning         ${id}
    EXCEPT    AS    ${err}
        Log    Could not generate ballooning plot: ${err}    level=WARN
    END

Plot ballooning
    [Arguments]             ${id}
    Generate Ballooning Graph    ${PLOT_DIR}   ${id}    ${TEST_NAME}
    Log   <img src="${REL_PLOT_DIR}mem_ballooning_${id}.png" alt="Power plot" width="1200">    HTML

Procedure After Timeout
    ${rebooted}     Set Variable  True
    Hard Reboot Device And Connect
    Login to laptop

Clean Test Files
    Run Command   sudo -n rm /dev/shm/test/*      rc_match=skip
    Run Command   sudo -n rm /dev/test/*          rc_match=skip
    Run Command   sudo -n rm /run/test/*          rc_match=skip
    Run Command   sudo -n rm -r /dev/shm/test     rc_match=skip
    Run Command   sudo -n rm -r /dev/test         rc_match=skip
    Run Command   sudo -n rm -r /run/test         rc_match=skip

Clean Ballooning Test Files
    ${vm}=                  Get Variable Value  ${ballooning_vm}  ${EMPTY}
    IF  $vm != ''
        TRY
            Switch to vm        ${vm}
            Clean Test Files
            Run Command         rm -r ${test_dir}   rc_match=skip
        EXCEPT    AS    ${err}
            Log    Could not clean VM ballooning test files: ${err}    level=WARN
        END
    END

    TRY
        Switch to vm            ${HOST}
        Run Command         rm -r ${test_dir}   rc_match=skip
    EXCEPT    AS    ${err}
        Log    Could not clean host ballooning test files: ${err}    level=WARN
    END

Ballooning Test Teardown
    [Documentation]    If test gets stuck, reboot device and connect to netvm (the next test can be executed).
    ...                After reboot, the artifacts should be not existing, so no need to clean.
    Run Keyword If Test Failed  Collect Ballooning Logs And Plot
    Run Keyword If Timeout Occurred     Procedure After Timeout
    Run Keyword If   $TEST_STATUS == 'FAIL' and 'SSHException' in $TEST_MESSAGE   Procedure After Timeout
    IF  $rebooted != 'True'
        Clean Ballooning Test Files
    END
