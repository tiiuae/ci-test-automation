# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/output_parser.py
Library             Collections
Library             OperatingSystem
Library             DateTime
Library             String


*** Keywords ***

Run Command
    [Documentation]   By default, executes a command, checks that return code is 0 and returns output.
    ...    The return code can be validated in three modes using `rc_match`:
    ...    - `equal`      : return code must equal `compare_rc` (default)
    ...    - `not_equal`  : return code must NOT equal `compare_rc`
    ...    - `skip`       : do not validate the return code
    ...    The `return` argument controls which values are returned.
    ...    Possible values are: `out` (stdout), `err` (stderr) and `rc` (return code)
    ...    If only `out` is requested, stdout is returned directly. If `err` or `rc` is requested,
    ...    a list is returned in the order: out, err, rc (only including requested values).
    [Arguments]  ${cmd}  ${return}=out  ${sudo}=False  ${rc_match}=equal  ${compare_rc}=0  ${timeout}=60

    ${output}  ${err}  ${rc}    Execute Command  ${cmd}  return_stderr=True  return_rc=True  sudo=${sudo}  sudo_password=${PASSWORD}  timeout=${timeout}
    Log   Output: ${output} \nRc: ${rc} \nErr: ${err}

    # Error is not relevant if the return code is 0
    IF   ${rc} == 0
        ${err}   Set Variable   ${EMPTY}
    END

    IF    '${rc_match}' == 'equal'
        Should Be Equal As Integers        ${rc}  ${compare_rc}   Error with command: ${cmd} \nReturn code: ${rc}, expected: ${compare_rc} \nError: ${err} \n
    ELSE IF    '${rc_match}' == 'not_equal'
        Should Not Be Equal As Integers    ${rc}  ${compare_rc}   Error with command: ${cmd} \nReturn code: ${rc}, expected not to be equal with: ${compare_rc} \nError: ${err} \n
    ELSE IF    '${rc_match}' != 'skip'
        Fatal Error   Wrong rc_match type: ${rc_match}
    END

    IF  'err' in '${return}' or 'rc' in '${return}'
        ${results}    Create List
        IF  'out' in '${return}'  Append To List  ${results}  ${output}
        IF  'err' in '${return}'  Append To List  ${results}  ${err}
        IF  'rc' in '${return}'   Append To List  ${results}  ${rc}
        RETURN    @{results}
    ELSE IF   'out' in '${return}'
        RETURN   ${output}
    ELSE
        RETURN
    END

Check variable availability
    [Arguments]    ${variable_name}
    ${value}=    Get Variable Value    ${${variable_name}}
    IF  $value!='${EMPTY}' and $value!=None
        RETURN  ${True}
    ELSE
        RETURN  ${False}
    END

Get Ghaf Version
    [Documentation]    Get version of Ghaf system
    ${output}   Run Command   ghaf-version
    Log To Console    ghaf-version: ${output}
    RETURN    ${output}

Log Error
    [Documentation]   Send a log about an error to Grafana
    [Arguments]    ${context}    ${message}
    Run Command    logger --priority=user.info "ROBOT_LOG (${context}): ${message} | device=${DEVICE_TYPE}, job=${JOB}"

Get VM list
    [Arguments]    ${with_host}=False
    Switch to vm    ${HOST}
    ${output}       Run Command    ls /var/lib/microvms/
    @{vm_list}      Split String       ${output}
    Should Not Be Empty     ${vm_list}   VM list is empty
    IF    ${with_host}    Append To List   ${vm_list}   ${HOST}
    RETURN    @{vm_list}

Is process running
    [Arguments]    ${process_name}
    ${running}   Run Keyword And Return Status   Run Command    pgrep -f "${process_name}" -a
    RETURN   ${running}

Check that process is running
    [Arguments]      ${process_name}
    ${is_running}    Is process running   ${process_name}
    Should Be True   ${is_running}    Process ${process_name} is not running
    Log              Process ${process_name} is running    console=True

Check that process is not running
    [Arguments]          ${process_name}   ${error_message}=still running
    ${is_running}        Is process running   ${process_name}
    Should Not Be True   ${is_running}        Process ${process_name} is ${error_message}
    Log                  Process ${process_name} is not running    console=True

Kill process by name
    [Arguments]   ${process_name}   ${sudo}=True   ${require_exists}=${True}   ${signal}=TERM   ${fallback_signal}=KILL
    IF    ${require_exists}   Check that process is running   ${process_name}
    Log   Killing process ${process_name} with signal ${signal} (fallback: ${fallback_signal})   console=True
    # A = ignore pkill process (ancestor), e = display what is killed, f = use full process name to kill
    Run Command    pkill -${signal} -Aef "${process_name}"  sudo=${sudo}  return=rc  rc_match=skip  timeout=15
    ${stopped}   Run Keyword And Return Status   Wait Until Keyword Succeeds   5x   1s   Check that process is not running   ${process_name}
    IF  not ${stopped}
        Log   Process ${process_name} still running after signal ${signal}, retrying with ${fallback_signal}   console=True
        Run Command    pkill -${fallback_signal} -Aef "${process_name}"  sudo=${sudo}  return=rc  rc_match=skip  timeout=15
        ${stopped}   Run Keyword And Return Status   Wait Until Keyword Succeeds   5x   1s   Check that process is not running   ${process_name}
        Should Be True   ${stopped}   Process ${process_name} is still running after ${signal} and ${fallback_signal}
    END

Save Time
    [Arguments]    ${label}    ${time}=None
    IF  "${time}" == "None"
        ${time}    Evaluate    time.time()
    END
    Set Suite Variable    ${TIME_${label}}    ${time}

Wait
    [Arguments]       ${sec}  ${silently}=${True}  ${log_interval}=5
    ${time}           Get Time
    Log               ${time}: waiting for ${sec} sec    console=True
    IF  ${silently}
        Sleep         ${sec}
    ELSE
        ${steps}        Evaluate    int(${sec}) // ${log_interval}
        ${remainder}    Evaluate    float(${sec}) % float(${log_interval})
        FOR    ${i}    IN RANGE    ${steps}
            Sleep           ${log_interval}
            ${elapsed_s}    Evaluate    (${i} + 1) * ${log_interval}
            Log             ${elapsed_s}    console=True
        END
        IF  ${remainder} > 0
            Sleep    ${remainder}
        END
    END

Search nix store
    [Documentation]      Search a file containing string argument in the target nix store.
    ...                  Return only the file path which is linked to the current generation.
    [Arguments]          ${string}
    # nix-store --query does not work on storeDisk images
    ${status}  ${path}   Run Keyword And Ignore Error   Run Command  nix-store --query --requisites /run/current-system | grep ${string}
    IF   $status == 'PASS'
        Should Not Be Empty  ${path}      File not found from the target /nix/store
        RETURN               ${path}
    ELSE
        ${path}         Run Command       ls /nix/store | grep ${string}
        Should Not Be Empty  ${path}      File not found from the target /nix/store
        RETURN               /nix/store/${path}
    END

Set device state
    [Documentation]   Change device (cam, mic, net, bluetooth) state to ${expected_state} (blocked, unblocked)
    [Arguments]       ${expected_state}     ${device}
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    Should Be True   '${expected_state}' in ['blocked', 'unblocked']   Wrong state
    ${device_state}      Get device state   ${device}
    ${status}         Run Keyword And Return Status   Should Be Equal   ${device_state}   ${expected_state}
    IF    ${status}
        Log To Console   ${device} is already ${expected_state}
        RETURN
    END
    IF   '${expected_state}' == 'blocked'
        ${state_to_set}   Set Variable   block
    ELSE
        ${state_to_set}   Set Variable   unblock
    END
    Run Command   ghaf-killswitch ${state_to_set} ${device}
    ${device_state}   Get device state    ${device}
    Should Be Equal   ${device_state}   ${expected_state}
    Log To Console    ${device} is ${device_state}

Set all devices state
    [Documentation]   Change all killswitch devices state to ${expected_state} (blocked, unblocked)
    [Arguments]       ${expected_state}
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    Should Be True    '${expected_state}' in ['blocked', 'unblocked']   Wrong state
    IF   '${expected_state}' == 'blocked'
        ${state_to_set}   Set Variable   block
    ELSE
        ${state_to_set}   Set Variable   unblock
    END
    Run Command       ghaf-killswitch ${state_to_set} --all
    Log               Set all devices to ${expected_state}    console=True

Verify all devices state
    [Arguments]       ${expected_state}
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}         Run Command   ghaf-killswitch status
    FOR    ${device}    IN    cam    mic    bluetooth    net
        ${device_state}    Get kill switch status   ${output}   ${device}
        Run Keyword And Continue On Failure
        ...    Should Be Equal    ${device_state}   ${expected_state}   ${device} is ${device_state}, expected ${expected_state}.
    END

Get device state
    [Arguments]     ${device}
    [Setup]         Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}       Run Command   ghaf-killswitch status
    ${state}        Get kill switch status   ${output}   ${device}
    RETURN          ${state}

Restart VM
    [Documentation]         Start or restart a VM service and verify it is running.
    ...                     Reinstall Robot sudoers after the VM is back by default.
    ...                     Pass `${restore_sudoers}=False` only if you will re-enable sudoers yourself afterward.
    [Arguments]             ${vm}    ${start_only}=False    ${restore_sudoers}=True
    [Setup]                 Switch to vm   ${HOST}
    Log                     Going to start ${vm}    console=True
    ${start_commnad}        Set Variable If   ${start_only}   start   restart
    Run Command             systemctl ${start_commnad} microvm@${vm}.service  sudo=True  timeout=120
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=active  expected_substate=running
    Log                     ${vm} is ${substate}    console=True
    Check if ssh is ready on vm   ${vm}
    [Teardown]   Run Keyword If   ${restore_sudoers}   Ensure Robot sudoers is installed in all VMs    skip_boot_check=True

Check VM Log on Grafana
    [Documentation]  Check that specific log entry (log line contains) from a VM is available in Grafana
    ...              If expected=nofail, test will not fail in any case but just return the status
    ...              If expected is True or False, test will compare expected and actual result and Fail if not equal
    [Arguments]      ${id}   ${vm}  ${since}=10m  ${expected}=nofail  ${log_entry}=${EMPTY}
    Set Log Level  NONE
    IF  $log_entry == '${EMPTY}'
        ${out}    Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="${since}" --limit=10 '{machine="${id}", host="${vm}"}' | grep -v ${GRAFANA_LOGS}
    ELSE
        ${out}    Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="${since}" --limit=0 '{machine="${id}", host="${vm}"}' | grep ${log_entry}
    END
    Set Log Level  INFO
    Log            ${out}
    ${lines}       Count lines    ${out}
    ${status}      Run Keyword And Return Status   Should Be True   ${lines} > 0   ${vm} query does not contain logs
    IF  $expected != 'nofail' and $expected != $status
        FAIL    Logs check status is ${status}, but expected ${expected}
    END
    RETURN         ${status}

Get logs by key words
    [Arguments]      ${word}   ${period}=1d   ${hide_found_data}=${True}
    [Documentation]    Search and get logs from Grafana
    ...                *Args*'\n:
    ...                - word - key word to find in log line
    ...                - period - sets a period of time for searching to limit lines, 1 day by default
    ...                - hide_found_data - replace found pattern with a placeholder to hid it robot logs in case of sensitive data
    Set Log Level    NONE
    ${logs}          Run   logcli query --addr="${GRAFANA_LOGS}" --password="${PASSWORD}" --username="${LOGIN}" --since="${period}" --limit="100" '{machine="${device_id}"} |= `${word}`'
    IF    ${hide_found_data}
        ${logs}          Replace String    string=${logs}        search_for=${word}        replace_with=<***HIDDEN_SENSITIVE_DATA***>
    END
    ${lines}         Split To Lines    ${logs}
    Remove From List    ${lines}    0    # contains full query including potentially sensitive searched word
    Set Log Level    INFO
    ${length}        Get Length   ${lines}
    ${status}        Run Keyword And Return Status  Should Be True  ${length} > 0   Logs do not contain searched word
    Log              ${logs}
    RETURN           ${status}    ${logs}

Get current timestamp
    ${current_time}   DateTime.Get Current Date  UTC  exclude_millis=yes
    RETURN            ${current_time}

Set timestamp
    [Arguments]          ${timestamp_variable_name}
    ${current_time}      Get current timestamp
    Set Global Variable  ${${timestamp_variable_name}}    ${current_time}
    Log                  Setting timestamp ${timestamp_variable_name}: ${${timestamp_variable_name}}    console=True

Get Actual Device ID
    ${hostname}    Run Command   hostname
    ${dir}         Set Variable If   '${HOST}' in '${hostname}'   persist   etc
    ${status}   ${device_id}   Run Keyword And Ignore Error   Run Command   cat /${dir}/common/device-id

    # Temporary workaround to enable running tests for https://github.com/tiiuae/ghaf/pull/1421
    # Once that PR is merged, device ID will be in /etc/ghaf-identity/device-id
    IF  '${status}' != 'PASS'
        ${device_id}   Run Command   cat /etc/ghaf-identity/device-id
    END

    Log       Actual Device ID: ${device_id}    console=True
    RETURN    ${device_id}

Get Timestamp of Last Boot
    Switch to vm        ${HOST}
    ${last_boot}        Run Command  journalctl --list-boots | tail -n1 | awk '{print $4,$5,$6}'
    RETURN              ${last_boot}

Get Time Since Last Boot
    Switch to vm        ${HOST}
    ${output}           Run Command    cat /proc/uptime | cut -d. -f1
    RETURN              ${output}

Get Backing Disk For Mountpoint
    [Documentation]    Resolve the physical disk backing the given mountpoint.
    [Arguments]        ${mountpoint}
    Run Command        lsblk    # For debugging
    ${device}          Run Command    findmnt -no SOURCE ${mountpoint}
    ${disk_info}       Run Command    lsblk --json -s -o NAME,TYPE ${device}
    ${disk}            Get Backing Disk From Lsblk    ${disk_info}
    RETURN             ${disk}
