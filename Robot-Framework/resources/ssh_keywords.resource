# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             SSHLibrary
Resource            ../config/variables.robot
Library             BuiltIn
Library             String
Library             Process
Library             ../lib/output_parser.py


*** Keywords ***

Ping Host
    [Arguments]        ${hostname}
    [Documentation]    Ping the given hostname once and return boolen result
    ${ping_output}=    Run Process   ping ${hostname} -c 1   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Check Network Availability
    [Arguments]            ${host}  ${expected_result}=True  ${range}=5
    Set Global Variable    ${is_available}   False
    FOR   ${i}   IN RANGE  ${range}
        Write    ping ${host} -c 1
        TRY
            Read Until           1 received
            Set Global Variable  ${is_available}  True
            BREAK
        EXCEPT
            CONTINUE
        END
    END
    IF    ${is_available} != ${expected_result}
        FAIL    Expected availability of ${host}: ${expected_result}, in fact: ${is_available}
    END

Connect
    [Documentation]   Set up the SSH connection to the device
    [Arguments]       ${IP}=${DEVICE_IP_ADDRESS}    ${PORT}=22    ${target_output}=ghaf@ghaf-host
    ${connection}=    Open Connection    ${IP}    port=${PORT}
    ${output}=        Login     username=${LOGIN}    password=${PASSWORD}
    Should Contain    ${output}    ${target_output}
    [Return]          ${connection}

Verify Systemctl status
    [Arguments]    ${range}=60
    [Documentation]    Check is systemctl running with given loop ${range}
    Connect
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${output}=    Execute Command    systemctl status
        ${status}=    Get Systemctl Status    ${output}
        IF  '${status}' not in ['running', 'starting']
            Log To Console   Systemctl status is ${status}
            FAIL    Systemctl is not running! Status is ${status}
        ELSE IF    '${status}' == 'running'
            ${diff}=    Evaluate    int(time.time()) - int(${start_time})
            Log To Console   Systemctl status is ${status} after ${diff} sec
            RETURN
        END
        Sleep    1
    END
    ${diff}=    Evaluate    int(time.time()) - int(${start_time})
    FAIL    Systemctl is not running after ${diff} sec! Status is ${status}
    [Teardown]       Close Connection

Start Chromium
    ${command}=     Set Variable    chromium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland
    Connect
    ${command_output}=    Execute Command    nohup ${command} > output.log 2>&1 &

Is process started
    [Arguments]    ${proc_name}
    ${output}=    Execute Command    ps aux
    ${pid}=       Find Pid    ${output}  ${proc_name}
    Log To Console    Process: ${proc_name}\n PID: ${pid}
    [Return]      ${pid}

Kill process
    [Arguments]    ${pid}    ${sig}=15
    Execute Command    kill -${sig} ${pid}
    FOR    ${i}    IN RANGE   5
        ${pid}=    Is Process Started    ${pid}
        IF    ${pid} == None
            ${ps_exists}=  Set Variable  False
            Sleep    0.5
            BREAK
        ELSE
            ${ps_exists}=  Set Variable  True
        END
    END
    IF  ${ps_exists}  FAIL  Process chromium haven't stopped

Verify service status
    [Documentation]   Check if service is running with given loop ${range}
    [Arguments]       ${range}=1   ${service}=${EMPTY}   ${expected_status}=active   ${expected_state}=running
    FOR    ${i}    IN RANGE    ${range}
        ${output}=    Execute Command    systemctl status ${service}
        ${result}=    Get Service Status    ${output}
        ${status}   ${state}    Get Service Status    ${output}
    END
    Log To Console   Service status: ${result}
    Should Be True	'${status}' == '${expected_status}'  Expected ${expected_status} but in fact ${status}
    Should Be True	'${state}' == '${expected_state}'    Expected ${expected_state} but in fact ${state}
    [Return]    ${status}  ${state}

Verify service shutdown status
    [Documentation]   Check if service was stopped properly
    [Arguments]       ${service}=${EMPTY}   ${expected_code}=exited   ${expected_status}=0/SUCCESS
    ${output}=          Execute Command    systemctl status ${service}
    ${code}  ${status}  Verify shutdown status    ${output}
    Log To Console    Service shutdown result: code=${code}, status=${status}
    Should Be True	  '${code}' == '${expected_code}'      Expected ${expected_code} but in fact ${code}
    Should Be True	  '${status}' == '${expected_status}'  Expected ${expected_status} but in fact ${status}

Wait until NetVM service started
    [Arguments]       ${timeout}=15
    ${is_started} =   Set Variable    False
    FOR    ${i}    IN RANGE    ${timeout}
        ${output}=     Execute Command    systemctl status ${netvm_service}
        ${status} =    Run Keyword And Return Status    Should Contain    ${output}    Welcome to NixOS
        IF    ${status}
            ${is_started} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    NetVM is not ready after ${timeout}

Create file
    [Documentation]    Create file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}
    Execute Command    touch ${file_name}  sudo=True  sudo_password=${password}
    SSHLibrary.File Should Exist  ${file_name}

Verify Ghaf Version Format
    [Documentation]    Check that ghaf-version contains version number in the format:"dd.dd",
    ...                date of commit in format yyyymmdd and 7 symbols of hash commit
    ${major}  ${minor}  ${date}    ${commit}  ${name}    Get Version    ghaf
    Should Match Regexp	  ${major}    ^\\d{2}$
    Should Match Regexp	  ${minor}    ^\\d{2}$
    Verify Date Format    ${date}
    Should Match Regexp	  ${commit}   ^[0-9a-f]{7}$
    IF  ${name} != None
        FAIL    Unexpected string in Ghaf version: ${name}
    END

Verify Nixos Version Format
    [Documentation]    Check that nixos-version contains version number in the format:"dd.dd",
    ...                date of commit in format yyyymmdd, 7 symbols of hash commit and version name in brackets
    ${major}  ${minor}  ${date}  ${commit}  ${name}    Get Version    nixos
    Should Match Regexp	  ${major}   ^\\d{2}$
    Should Match Regexp	  ${minor}   ^\\d{2}$
    Verify Date Format    ${date}
    Should Match Regexp	  ${commit}   ^[0-9a-f]{7}$
    IF  '${name}' == 'None'
        FAIL    Expected NixOS version name, but there is None
    END

Get Version
    [Documentation]    Get version of NixOS or Ghaf system, Examples:
    ...     "ghaf-version"    output: 23.05.20230628.92414ab            parse result: 23.05, 20230628, 92414ab
    ...     "nixos-version"   output: 23.05.20230625.35130d4 (Stoat)    parse result: 23.05, 20230625, 35130d4, Stoat
    [Arguments]  ${whose}
    ${output}   ${rc}    Execute Command   ${whose}-version   return_rc=True
    Should Be Equal As Integers     ${rc}   0   Couldn't get ghaf version, command return code
    ${major}  ${minor}  ${date}  ${commit}  ${name}     Parse Version   ${output}
    [Return]    ${major}  ${minor}  ${date}  ${commit}  ${name}