# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/output_parser.py
Library             Collections


*** Keywords ***

Check variable availability
    [Arguments]    ${variable_name}
    ${value}=    Get Variable Value    ${${variable_name}}
    IF  $value!='${EMPTY}' and $value!=None
        RETURN  ${True}
    ELSE
        RETURN  ${False}
    END

Verify service status
    [Documentation]   Check if service is running with given loop ${range}
    [Arguments]       ${range}=45  ${service}=${EMPTY}   ${expected_state}=active   ${expected_substate}=running  ${expected_rc}=0
    ${vmservice}      Run Keyword And Return Status  Should Contain  ${service}  microvm@
    ${finished}       Set Variable  False

    ${welcome_check}  Set Variable If  "Lenovo" in "${DEVICE}" or "Darter" in "${DEVICE}" or "Dell" in "${DEVICE}"    False    True

    FOR    ${i}    IN RANGE    ${range}
        ${output}  ${stderr}  ${rc}=   Execute Command  systemctl show ${service}  return_stderr=True  return_rc=True
        Log           stdout: ${output}\nstderr: ${stderr}
        Should Not Be Equal As Integers	    ${rc}	4   Stderr: "${stderr}", Return code
        ${state}             Get Service State     ${output}
        ${substate}          Get Service Substate  ${output}
        ${state_status}      Run Keyword And Return Status    Should Be True	'${state}' == '${expected_state}'  Expected ${expected_state} but in fact ${state}
        ${substate_status}   Run Keyword And Return Status    Should Be True	'${substate}' == '${expected_substate}'    Expected ${expected_substate} but in fact ${substate}

        # 'Welcome to NixOS' is not got if 'non-vm service' or if service is expected to be inactive/dead.
        IF  ${vmservice} and '${expected_substate}' == 'running' and ${state_status} and ${substate_status} and ${welcome_check}
            ${logs}        Execute Command   journalctl -b -u ${service}
            Log            ${logs}
            ${finished}    Run Keyword And Return Status    Should Contain    ${logs}    Welcome to NixOS
            IF  ${finished}
                BREAK
            END
        ELSE IF  ${state_status} and ${substate_status}
            ${finished}     Set Variable  True
            BREAK
        END
        Sleep    1
    END

    IF  ${finished}
        Log To Console  ${\n}systemctl status ${service}: ${state} (${substate})
    ELSE
        ${output}       Execute Command  journalctl -b -u ${service}
        Log             ${output}
        IF   ${welcome_check}   FAIL    systemctl status ${service}: ${state} (${substate}), expected: ${expected_state} (${expected_substate}), welcome check passed: ${finished}
        FAIL            systemctl status ${service}: ${state} (${substate}), expected: ${expected_state} (${expected_substate})
    END
    RETURN    ${state}  ${substate}

Verify Systemctl status
    [Arguments]    ${range}=60    ${user}=False
    [Documentation]    Check is systemctl running with given loop ${range}

    IF    ${user}
        ${cmd}               Set Variable   systemctl is-system-running --user
        ${failed_units_cmd}  Set Variable   systemctl list-units --state=failed --user
    ELSE
        ${cmd}               Set Variable   systemctl is-system-running
        ${failed_units_cmd}  Set Variable   systemctl list-units --state=failed
    END

    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${status}=    Execute Command    ${cmd}

        ${data_failed_units}   Execute Command    ${failed_units_cmd}
        Log  ${data_failed_units}
        ${failed_units}  Get failed units  ${data_failed_units}
        Log   ${failed_units}
        Set Test Variable   ${failed_units}

        IF  '${status}' not in ['running', 'starting']
            Log     Systemctl status is ${status}  console=True
            FAIL    Systemctl is not running! Status is ${status}. Failed processes are: ${failed_units}
        ELSE IF    '${status}' == 'running'
            ${diff}=    Evaluate    int(time.time()) - int(${start_time})
            Log     Systemctl status is ${status} after ${diff} sec  console=True
            RETURN
        END
        Sleep    1
    END
    ${diff}=    Evaluate    int(time.time()) - int(${start_time})
    FAIL    Systemctl is not running after ${diff} sec! Status is ${status}. Failed processes?: ${failed_units}

Check systemctl status for known issues
    [Arguments]    ${known_issues_list}   ${failing_services}   ${user}=False
    [Documentation]    Check if failing services contain issues that are not listed as known

    Should Not Be Empty    ${failing_services}     Failing services list is empty.

    IF    ${user}
        ${unit_logs_cmd}     Set Variable   journalctl --user -u
    ELSE
        ${unit_logs_cmd}     Set Variable   journalctl -u
    END

    ${old_issues}=    Create List
    ${new_issues}=    Create List
    FOR    ${failing_service}    IN    @{failing_services}
        ${known}=    Set Variable    False
        ${unit_logs}   Execute command    ${unit_logs_cmd} ${failing_service}
        Log            ${unit_logs}
        FOR    ${entry}    IN    @{known_issues_list}
            ${list_device}  ${service}  ${issue}   Parse Known Issue   ${entry}

            ${device_match}=     Run Keyword And Return Status    Should Contain    ${DEVICE}    ${list_device}
            ${service_match}=    Run Keyword And Return Status    Should Contain    ${failing_service}    ${service}

            IF   ('${list_device}'=='ANY' or ${device_match}) and ('${service}'=='ANY' or ${service_match})
                ${known}=     Set Variable    True
            END
        END
        IF    ${known}   
            Append To List    ${old_issues}    ${failing_service}
        ELSE
            Append To List    ${new_issues}    ${failing_service}
        END
    END
    IF   ${new_issues} != []
        Fail    Unexpected failed services: ${new_issues}, known failed services: ${old_issues}
    ELSE
        Skip    Known failed services: ${old_issues}
    END

Get VM list
    [Arguments]    ${with_host}=False
    Switch to vm    ${HOST}
    ${output}       Execute Command    microvm -l
    @{vm_list}      Extract VM names   ${output}
    Should Not Be Empty     ${vm_list}   VM list is empty
    IF    ${with_host}
        @{vm_list}    Create List   @{vm_list}   ${HOST}
    END
    RETURN    @{vm_list}

Is process started
    [Arguments]    ${pid}
    ${rc}=      Execute Command    ps -p ${pid}   return_rc=True
    ${status}=  Run Keyword And Return Status   Should Be Equal As Integers	 ${rc[1]}	0
    RETURN      ${status}

Find pid by name
    [Arguments]   ${process_name}  ${exact_match}=false
    Log To Console    Looking for pids of the process ${process_name}
    IF  $exact_match=='true'
        ${output}=    Execute Command    sh -c 'ps aux | grep -E " ${process_name}$" | grep -v grep'
    ELSE
        ${output}=    Execute Command    sh -c 'ps aux | grep "${process_name}" | grep -v grep'
    END
    Log           ${output}
    @{pids}=      Find Pid    ${output}  ${process_name}
    Log To Console    Found PIDs for process '${process_name}':\n${pids}
    RETURN        @{pids}

Kill process
    [Arguments]    @{pids}    ${sig}=9    ${sudo}=True
    FOR   ${pid}  IN  @{pids}
        IF  '${pid}' == '${EMPTY}'
            BREAK
        END
        IF  $sudo == "True"
            Execute Command    kill -${sig} ${pid}  sudo=True  sudo_password=${PASSWORD}  timeout=15
        ELSE
            Execute Command    kill -${sig} ${pid}  timeout=15
        END
        FOR    ${i}    IN RANGE   5
            ${ps_exists}=    Is Process Started    ${pid}
            IF  ${ps_exists}
                Sleep    0.5
            ELSE
                BREAK
            END
        END
        IF  ${ps_exists}  FAIL  Process ${pid} haven't stopped
        # Check if any of the original pids are still running
        ${any_running} =    Set Variable    False
        FOR    ${check_pid}  IN  @{pids}
            ${ps_exists} =    Is Process Started    ${check_pid}
            IF  ${ps_exists}
                ${any_running} =    Set Variable    True
                BREAK
            END
        END
        IF  not ${any_running}
            BREAK
        END
    END
    Log To Console    Killed processes: @{pids}

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
    ${file_path}         Execute Command   nix-store --query --requisites /run/current-system | grep ${string}
    Should Not Be Empty  ${file_path}      File not found from the target /nix/store
    RETURN               ${file_path}