# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             OperatingSystem
Library             Collections
Library             ../lib/MemRecordingProcessing.py    ${LOGGED_PARAMS_DIR}mem_recordings/    ${PLOT_DIR}
Resource            ../config/variables.robot
Resource            ../resources/common_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Variables ***

${MEMREC_SCRIPT_DIR}    /tmp/mem-recordings
${SCRIPT_NAME}          mem_recording_loop.sh
${SCRIPT_PATH}          ${MEMREC_SCRIPT_DIR}/${SCRIPT_NAME}
${MEMREC_DIR}           ${EMPTY}

*** Keywords ***

Start memory recording in vm internals
    [Arguments]       ${vm}    ${id}    ${memrec_sudo}    ${interval_s}=10    ${timeout_s}=60
    Switch to vm      ${vm}
    ${csv}            Set Variable    ${MEMREC_DIR}/memrec__${id}__${vm}.csv

    Run Command    mkdir -p ${MEMREC_DIR}           sudo=${memrec_sudo}
    Run Command    mkdir -p ${MEMREC_SCRIPT_DIR}
    Put File       ../test-files/${SCRIPT_NAME}     ${MEMREC_SCRIPT_DIR}
    Run Command    chmod 755 ${SCRIPT_PATH}         sudo=${memrec_sudo}

    # Log the local time for debugging potential timesync problems
    ${vm_date}     Run Command    date '+%Y-%m-%d %H:%M:%S %z %Z'
    Log            Current date in ${vm}: ${vm_date}    console=True

    Run Command    sh -c 'nohup ${SCRIPT_PATH} ${csv} ${interval_s} ${timeout_s} > /dev/null 2>&1 &'    sudo=${memrec_sudo}
    Log    Started mem recording in ${vm}: ${csv}    console=True

Start memory recording in vm
    [Arguments]       ${vm}    ${memrec_sudo}=False    ${id}=${TEST NAME}    ${interval_s}=10    ${timeout_s}=60    ${memrec_dir}=${MEMREC_SCRIPT_DIR}
    ${id_safe}        Replace String    ${id}    ${SPACE}    _
    Set Suite Variable    ${MEMREC_ID}    ${id_safe}
    Set Suite Variable    ${MEMREC_DIR}    ${memrec_dir}
    @{single_vm}      Create List    ${vm}
    Set Suite Variable    @{MEMREC_VMS}    @{single_vm}
    Start memory recording in vm internals    ${vm}    ${id_safe}    ${memrec_sudo}    ${interval_s}    ${timeout_s}

Start memory recording in all VMs
    [Arguments]    ${memrec_sudo}=False    ${id}=${TEST NAME}    ${interval_s}=10    ${timeout_s}=60    ${with_host}=True    ${memrec_dir}=${MEMREC_SCRIPT_DIR}
    Set Suite Variable    ${MEMREC_ID}    ${EMPTY}
    Set Suite Variable    @{MEMREC_VMS}   @{EMPTY}
    Set Suite Variable   ${MEMREC_DIR}   ${memrec_dir}
    @{vms}    Get VM list    with_host=${with_host}
    ${id_safe}    Replace String    ${id}    ${SPACE}    _
    Set Suite Variable    ${MEMREC_ID}    ${id_safe}

    FOR    ${vm}    IN    @{vms}
        ${ok}    Run Keyword And Return Status    Start memory recording in vm internals    ${vm}    ${id_safe}    ${memrec_sudo}    ${interval_s}    ${timeout_s}
        IF    ${ok}
            Append To List    ${MEMREC_VMS}    ${vm}
        ELSE
            Log    Failed to start mem recording in ${vm}; skipping for stop/collect    console=True
        END
    END
    IF    ${MEMREC_VMS} == []
        Log    No VMs started mem recording    console=True
    END

Stop memory recording and collect
    [Arguments]    ${memrec_sudo}
    ${id}    Get Variable Value    ${MEMREC_ID}    ${EMPTY}
    @{memrec_vms}    Get Variable Value    @{MEMREC_VMS}    @{EMPTY}
    ${has_id}    Run Keyword And Return Status    Should Not Be Empty    ${id}
    IF    not ${has_id}
        Log To Console    No mem recording id set. Cannot collect results.
        RETURN
    END
    IF  $MEMREC_DIR == '${EMPTY}'
        Log To Console    No mem recording output directory set. Cannot collect results.
        RETURN
    END
    IF    ${memrec_vms} == []
        Log To Console    No mem recording VM list set. Cannot collect results.
        RETURN
    END

    ${out_dir}    Set Variable    ${LOGGED_PARAMS_DIR}mem_recordings
    OperatingSystem.Create Directory    ${out_dir}
    ${local_files}    Create List

    FOR    ${vm}    IN    @{memrec_vms}
        Switch to vm    ${vm}
        ${csv}        Set Variable    ${MEMREC_DIR}/memrec__${id}__${vm}.csv
        ${tmp_csv}    Set Variable    /tmp/memrec__${id}__${vm}.csv

        Kill process by name    ${SCRIPT_PATH}    ${memrec_sudo}    ${False}

        # Copy per-VM recording to local for merging.
        ${local_path}  Set Variable    ${out_dir}/memrec__${id}__${vm}.csv
        Run Command    cp ${csv} ${tmp_csv}    sudo=${memrec_sudo}
        Run Command    chmod 644 ${tmp_csv}    sudo=${memrec_sudo}
        Run Keyword And Ignore Error    SSHLibrary.Get File    ${tmp_csv}    ${local_path}
        Run Command    rm -f ${tmp_csv}    sudo=${memrec_sudo}
        Run Command    rm -f ${csv}    sudo=${memrec_sudo}
        Run Command    rm -f ${SCRIPT_PATH}
        ${exists}    Run Keyword And Return Status    OperatingSystem.File Should Exist    ${local_path}
        IF    ${exists}
            Append To List    ${local_files}    ${local_path}
        ELSE
            Log    Mem recording missing for ${vm} (${csv})    console=True
        END
    END

    IF    ${local_files} == []
        Log    No mem recordings collected; skipping merge/plot    console=True
        RETURN
    END

    ${base}    Set Variable    ${BUILD_ID}__mem_recording__${DEVICE}__${id}
    ${csv_out}    Merge Mem Recordings And Plot    ${local_files}    ${base}
    Log    <img src="${REL_PLOT_DIR}${base}__mem_avail.png" alt="MemAvailable Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${base}__swap_free.png" alt="SwapFree Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${base}__mem_avail_pct.png" alt="Mem Available (%) Plot" width="1200">    HTML
    Log    <img src="${REL_PLOT_DIR}${base}__swap_free_pct.png" alt="Swap Free (%) Plot" width="1200">    HTML
    Log    Merged mem recording saved: ${csv_out}    console=True
