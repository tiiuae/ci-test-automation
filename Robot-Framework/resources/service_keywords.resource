# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../resources/common_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/service_keywords.resource

*** Variables ***

*** Keywords ***
Verify service status
    [Documentation]   Check if service is running with given loop ${range}
    [Arguments]       ${range}=45  ${service}=${EMPTY}   ${expected_state}=active   ${expected_substate}=running  ${expected_rc}=0
    ${vmservice}      Run Keyword And Return Status  Should Contain  ${service}  microvm@
    ${finished}       Set Variable  False

    ${welcome_check}  Set Variable If  ${IS_LAPTOP}    False    True

    FOR    ${i}    IN RANGE    ${range}
        ${output}            Run Command          systemctl show ${service} --no-pager  rc_match=not_equal  compare_rc=4
        ${state}             Get Service State     ${output}
        ${substate}          Get Service Substate  ${output}
        ${state_status}      Run Keyword And Return Status    Should Be True	'${state}' == '${expected_state}'  Expected ${expected_state} but in fact ${state}
        ${substate_status}   Run Keyword And Return Status    Should Be True	'${substate}' == '${expected_substate}'    Expected ${expected_substate} but in fact ${substate}

        # 'Welcome to NixOS' is not got if 'non-vm service' or if service is expected to be inactive/dead.
        IF  ${vmservice} and '${expected_substate}' == 'running' and ${state_status} and ${substate_status} and ${welcome_check}
            ${logs}        Run Command   journalctl -b -u ${service} --no-pager -n 200
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
        Run Command   journalctl -b -u ${service}
        IF   ${welcome_check}   FAIL    systemctl status ${service}: ${state} (${substate}), expected: ${expected_state} (${expected_substate}), welcome check passed: ${finished}
        FAIL            systemctl status ${service}: ${state} (${substate}), expected: ${expected_state} (${expected_substate})
    END
    RETURN    ${state}  ${substate}

Verify Systemctl status
    [Arguments]    ${range}=60    ${add_params}=${EMPTY}   ${timeout}=3 minutes
    [Documentation]    Check is systemctl running with given loop ${range}
    [Timeout]          ${timeout}
    ${status}    ${diff}    ${failed_units}=    Wait Systemctl Starting With Time Measurement   add_params=${add_params}

    IF   '${status}' != 'running'
        ${services_jctl_summary}=   Get JournalCtl Info For Not Running Services
        Log                         ${services_jctl_summary}     html=${True}

        Log       Current systemctl status is ${status}. Waiting for status `running` for ${diff} sec! Failed processes?: ${failed_units}
    END
    RETURN    ${status}     ${failed_units}

Wait Systemctl Starting With Time Measurement
    [Arguments]    ${limit}=60    ${add_params}=${EMPTY}
    ${start_time}=    Get Time	epoch
    ${status}     ${failed_units}=    Wait While Systemctl Status Is Starting   limit=${limit}    add_params=${add_params}
    ${diff}=          Evaluate    int(time.time()) - int(${start_time})

    Log     Systemctl status is ${status} after ${diff} sec  console=True
    RETURN    ${status}     ${diff}     ${failed_units}

Wait While Systemctl Status Is Starting
    [Arguments]   ${limit}=60      ${add_params}=${EMPTY}

    ${status}=    Get systemctl status   add_params=${add_params}
    WHILE    '${status}' == 'starting'    limit=${limit}
        ${status}=    Get systemctl status   ${add_params}
        Sleep    1
    END
    ${failed_units}=        Get failed units from systemctl    ${add_params}
    RETURN    ${status}     ${failed_units}

Get systemctl status
    [Arguments]    ${add_params}=${EMPTY}
    ${status}=    Run Command    systemctl is-system-running ${add_params}      rc_match=skip
    RETURN    ${status}

Get failed units from systemctl
    [Arguments]    ${add_params}=${EMPTY}
    ${data_failed_units}   Run Command       systemctl list-units --state=failed ${add_params}
    ${failed_units}        Get failed units  ${data_failed_units}
    Log                    ${failed_units}
    RETURN    ${failed_units}

Get SystemCtl All Services
    [Arguments]    ${user_param}=${EMPTY}
    [Documentation]    Returns information about all systemd services as a dictionary {service_name -> service_info}, using `systemctl list-units`.

    ${all_services}=          Run Command    systemctl list-units --plain --no-legend --no-pager ${user_param}
    ${all_services_dict}=     Create Dictionary
    Log                       ${all_services}
    ${all_services_lines}=    Split to lines     ${all_services}

    FOR     ${line}     IN      @{all_services_lines}
        ${service_name}     ${load_status}  ${active_status}  ${sub_status}  ${description}=    Split String   ${line}   max_split=4
        ${service_dict}=    Create Dictionary
        ...                                       load=${load_status}     active=${active_status}
        ...                                       sub=${sub_status}       description=${description}
        ${all_services_dict}[${service_name}]=    Set Variable            ${service_dict}
    END

    RETURN    ${all_services_dict}

Get JournalCtl Info For Not Running Services
    [Arguments]    ${user_param}=${EMPTY}
    [Documentation]    Collects and summarizes journalctl output for systemd services that are not running or still starting,
    ...    skipping services without log entries. Returns a formatted multiline string suitable for reporting.
    ${summary_info_list}=             Create List
    ${services_with_jctl_output}=     Create Dictionary

    ${not_running_services}=          Get Not Running Services    ${user_param}

    FOR     ${service_name}   ${service_info}    IN    &{not_running_services}
        ${service_journalctl}=    Run Command    journalctl --lines 50 --no-pager -u ${service_name}

        IF  $service_journalctl != '-- No entries --'
            Set To Dictionary    ${services_with_jctl_output}    ${service_name}=${service_info}
            Append to list       ${summary_info_list}            ${service_name}
            Append To List       ${summary_info_list}            <b>${service_name} ${service_info}</b>\n${service_journalctl}\n
            Log                  ${service_journalctl}
        END
    END
    ${summary_info}     Catenate    SEPARATOR=\n    @{summary_info_list}

    Log     Taking a closer look into services that have journalctl output
    FOR     ${service_name}   ${service_info}    IN    &{services_with_jctl_output}
        ${service_journalctl}=    Run Command    journalctl --lines 300 --no-pager -u ${service_name}
        Log                       ${service_journalctl}
    END

    RETURN    ${summary_info}

Get Not Running Services
    [Arguments]    ${user_param}=${EMPTY}
    [Documentation]     Returns systemd services that are not active or are still in the "starting" state as a dictionary {service_name -> service_info}.

    ${services}=                Get SystemCtl All Services  user_param=${user_param}
    ${not_running_services}=    Create Dictionary

    FOR    ${service_name}   ${service_info}    IN    &{services}
        ${is_not_active}=    Evaluate    $service_info['active'] != 'active'
        ${is_starting}=      Evaluate    $service_info['sub'] == 'starting'

        IF    $is_not_active or $is_starting
            Set To Dictionary    ${not_running_services}    ${service_name}=${service_info}
        END
    END
    RETURN     ${not_running_services}

Check systemctl status for known issues
    [Documentation]    Check if failing services contain issues that are not listed as known.
    ...                ${name} can be either the device name or the vm name.
    ...
    ...                Variable \${found_known_issues_message} should be defined outside the keyword on the test scope,
    ...                it's not defined inside this keyword because Robot Framework works differently with test messages
    ...                if Template is in use.
    ...                To add message \${found_known_issues_message} to the log and report add to test's teardown
    ...                `Set Test Message    append=\${True}  separator=\\n    message=\${found_known_issues_message}`
    [Arguments]    ${name}  ${known_issues_list}  ${failing_services}  ${user}=False
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
        Run Command    ${unit_logs_cmd} ${failing_service}
        FOR    ${entry}    IN    @{known_issues_list}
            ${list_name}  ${service}  ${issue}   Parse Known Issue   ${entry}

            ${name_match}=       Run Keyword And Return Status    Should Contain    ${name}    ${list_name}
            ${service_match}=    Run Keyword And Return Status    Should Contain    ${failing_service}    ${service}

            IF    ('${list_name}' == 'ANY' or ${name_match}) and ('${service}' == 'ANY' or ${service_match})
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
        Fail    Unexpected failed services in/on ${name}: ${new_issues}, known failed services: ${old_issues}
    ELSE
        Log     level=WARN        message=Test `${TEST NAME}` for VM `${name}` failed with known issue: failed services ${old_issues}
        Set Test Variable    ${found_known_issues_message}      ${found_known_issues_message}VM `${name}` has services failed with known issue: ${old_issues}\n
    END