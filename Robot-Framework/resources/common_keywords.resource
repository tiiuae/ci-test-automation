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

    ${welcome_check}  Set Variable If  ${IS_LAPTOP}    False    True

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
    ${output}       Execute Command    ls /var/lib/microvms/
    @{vm_list}      Split String       ${output}
    Should Not Be Empty     ${vm_list}   VM list is empty
    IF    ${with_host}    Append To List   ${vm_list}   ${HOST}
    RETURN    @{vm_list}

Check if process is running
    [Arguments]    ${process_name}
    ${output}  ${rc}    Execute Command    pgrep -f "${process_name}" -a  return_rc=True
    Log   ${output}
    ${status}   Run Keyword And Return Status   Should Be Equal As Integers  ${rc}  0
    RETURN   ${status}

Kill process by name
    [Arguments]   ${process_name}   ${sudo}=True   ${require_exists}=${True}
    Log   Killing process ${process_name}   console=True
    # 9 = kill instead of terminating, A = ignore pkill process (ancestor), e = display what is killed, f = use full process name to kill
    ${output}  ${rc}   Execute Command    pkill -9 -Aef "${process_name}"  sudo=${sudo}  sudo_password=${PASSWORD}  return_rc=True  timeout=15
    Log   ${output}
    IF  ${require_exists}
        Should Be Equal As Integers   ${rc}   0
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
    ${file_path}  ${rc}   Execute Command  nix-store --query --requisites /run/current-system | grep ${string}   return_rc=True
    IF   ${rc} == 0
        Should Not Be Empty  ${file_path}      File not found from the target /nix/store
        RETURN               ${file_path}
    ELSE
        ${file_path}         Execute Command   ls /nix/store | grep ${string}
        Should Not Be Empty  ${file_path}      File not found from the target /nix/store
        RETURN               /nix/store/${file_path}
    END

Set device state
    [Documentation]   Change device (cam, mic, net) state to ${expected_state} (blocked, unblocked)
    [Arguments]       ${expected_state}     ${device}
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    Should Be True   '${expected_state}' in ['blocked', 'unblocked']   Wrong state
    ${device_state}      Get device state   ${device}
    ${status}         Run Keyword And Return Status   Should Be Equal   ${device_state}   ${expected_state}
    IF    ${status}
        Log To Console   Device ${device} state is already ${expected_state}
    ELSE
        IF   '${expected_state}' == 'blocked'
            ${state_to_set}   Set Variable   block
        ELSE
            ${state_to_set}   Set Variable   unblock
        END
        ${output}        Execute Command   ghaf-killswitch ${state_to_set} ${device}
        Log  ${output}
        ${device_state}   Get device state    ${device}
        Should Be Equal   ${device_state}   ${expected_state}

        # Workaround for a known issue: SSRCSP-7727 (blocking microphone breaks audio)
        IF   '${device}' == 'mic' and '${expected_state}' == 'unblocked'
            Log To Console   Restarting audio-vm to make sure that audio works in later tests
            Restart VM   ${AUDIO_VM}
        END
    END

Get device state
    [Arguments]     ${device}
    [Setup]         Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}       Execute Command   ghaf-killswitch status
    ${state}        Get kill switch status   ${output}   ${device}
    RETURN          ${state}

Restart VM
    [Documentation]         Try to restart VM service and verify it started
    [Arguments]             ${vm}
    [Setup]                 Switch to vm   ${HOST}
    Log                     Going to start ${vm}    console=True
    Execute Command         systemctl restart microvm@${vm}.service  sudo=True  sudo_password=${PASSWORD}  timeout=120
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=active  expected_substate=running
    Log                     ${vm} is ${substate}    console=True
    Check if ssh is ready on vm   ${vm}