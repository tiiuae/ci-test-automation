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
    @{VM_LIST}      Extract VM names   ${output}
    Should Not Be Empty     ${VM_LIST}   VM list is empty
    IF    ${with_host}
        @{VM_LIST}    Create List   @{VM_LIST}   ${HOST}
    END
    RETURN    @{VM_LIST}
