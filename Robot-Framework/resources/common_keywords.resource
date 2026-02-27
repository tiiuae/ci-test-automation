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
        ERROR   Wrong rc_match type: ${rc_match}
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


Get VM list
    [Arguments]    ${with_host}=False
    Switch to vm    ${HOST}
    ${output}       Run Command    ls /var/lib/microvms/
    @{vm_list}      Split String       ${output}
    Should Not Be Empty     ${vm_list}   VM list is empty
    IF    ${with_host}    Append To List   ${vm_list}   ${HOST}
    RETURN    @{vm_list}

Check if process is running
    [Arguments]    ${process_name}
    ${status}  ${output}   Run Keyword And Ignore Error   Run Command    pgrep -f "${process_name}" -a
    RETURN   '${status}' == 'PASS'

Kill process by name
    [Arguments]   ${process_name}   ${sudo}=True   ${require_exists}=${True}
    Log   Killing process ${process_name}   console=True
    # 9 = kill instead of terminating, A = ignore pkill process (ancestor), e = display what is killed, f = use full process name to kill
    ${output}   Run Command    pkill -9 -Aef "${process_name}"  sudo=${sudo}  return=rc  rc_match=skip  timeout=15
    IF  ${require_exists}
        Should Be Equal As Integers   ${output}[0]   0
    END

Save Time
    [Arguments]    ${label}    ${time}=None
    IF  "${time}" == "None"
        ${time}    Evaluate    time.time()
    END
    Set Suite Variable    ${TIME_${label}}    ${time}

Wait
    [Arguments]     ${sec}
    ${time}         Get Time
    Log             ${time}: waiting for ${sec} sec  console=True
    Sleep           ${sec}

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

Get device state
    [Arguments]     ${device}
    [Setup]         Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}       Run Command   ghaf-killswitch status
    ${state}        Get kill switch status   ${output}   ${device}
    RETURN          ${state}

Restart VM
    [Documentation]         Try to restart VM service and verify it started
    [Arguments]             ${vm}
    [Setup]                 Switch to vm   ${HOST}
    Log                     Going to start ${vm}    console=True
    Run Command             systemctl restart microvm@${vm}.service  sudo=True  timeout=120
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=active  expected_substate=running
    Log                     ${vm} is ${substate}    console=True
    Check if ssh is ready on vm   ${vm}

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
    ${device_id}     Run Command   cat /persist/common/device-id
    Log To Console   Actual Device ID: ${device_id}
    RETURN           ${device_id}

Get Timestamp of Last Boot
    Switch to vm        ${HOST}
    ${last_boot}        Run Command  journalctl --list-boots | tail -n1 | awk '{print $4,$5}'
    RETURN              ${last_boot}

Get Time Since Last Boot
    ${last_boot}        Get Timestamp of Last Boot
    ${current_time}     Get current timestamp
    ${time_since_boot}  DateTime.Subtract Date From Date   ${current_time}  ${LAST_BOOT}  exclude_millis=True
    RETURN              ${time_since_boot}
