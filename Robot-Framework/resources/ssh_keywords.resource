# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             SSHLibrary
Resource            ../config/variables.robot
Library             BuiltIn
Library             String
Library             Process
Library             ../lib/output_parser.py


*** Variables ***
${netvm_ip}        192.168.101.1


*** Keywords ***

Ping Host
    [Arguments]        ${hostname}
    [Documentation]    Ping the given hostname once and return boolen result
    ${ping_output}=    Run Process   ping ${hostname} -c 1   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Check Network Availability
    [Arguments]            ${host}  ${expected_result}=True  ${range}=5
    Log To Console         Checking network ${host} availability, expected: ${expected_result}
    Set Global Variable    ${is_available}   False
    FOR   ${i}   IN RANGE  ${range}
        Write    ping ${host} -c 1
        TRY
            Read Until           1 received
            Set Global Variable  ${is_available}  True
            Log To Console  ${host} is available
            BREAK
        EXCEPT
            IF    ${expected_result} == False
                Log To Console  ${host} is unavailable
                BREAK
            ELSE
                CONTINUE
            END
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
    Log To Console  ${\n}Starting Chromium
    ${command}=     Set Variable    chromium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland
    ${command_output}=    Execute Command    nohup ${command} > output.log 2>&1 &

Start Firefox
    [Documentation]  It's needed to set display variable manually because there is no real monitor connected to DUT
    Log To Console  ${\n}Starting Firefox
    ${command_output}=    Execute Command    export WAYLAND_DISPLAY=wayland-1; nohup firefox > output.log 2>&1 &

Is process started
    [Arguments]    ${pid}
    ${rc}=      Execute Command    ps -p ${pid}   return_rc=True
    ${status}=  Run Keyword And Return Status   Should Be Equal As Integers	 ${rc[1]}	0
    IF  ${status}
        Log To Console    Process ${pid} exists
    ELSE
        Log To Console    Process ${pid} doesn't exist
    END
    [Return]    ${status}

Find pid by name
    [Arguments]   ${proc_name}
    Log To Console    Looking for pids of the proccess ${proc_name}
    ${output}=    Execute Command    sh -c 'ps aux | grep "${proc_name}" | grep -v grep'
    Log           ${output}
    @{pids}=      Find Pid    ${output}  ${proc_name}
    Log To Console    Found PIDs: ${pids}
    [Return]      @{pids}

Kill process
    [Arguments]    @{pids}    ${sig}=15
    FOR   ${pid}  IN  @{pids}
        Log To Console    Send kill -${sig} to ${pid}
        Execute Command    kill -${sig} ${pid}
        FOR    ${i}    IN RANGE   5
            ${ps_exists}=    Is Process Started    ${pid}
            IF  ${ps_exists}
                Sleep    0.5
            ELSE
                BREAK
            END
        END
        IF  ${ps_exists}  FAIL  Process ${pid} haven't stopped
    END

Verify service status
    [Documentation]   Check if service is running with given loop ${range}
    [Arguments]       ${range}=1   ${service}=${EMPTY}   ${expected_status}=active   ${expected_state}=running  ${expected_rc}=0
    FOR    ${i}    IN RANGE    ${range}
        ${output}  ${stderr}  ${rc}=   Execute Command  systemctl status ${service}  return_stderr=True  return_rc=True
        Log           stdout: ${output}\nstderr: ${stderr}
        Should Not Be Equal As Integers	    ${rc}	4   Stderr: "${stderr}", Return code
        ${result}=    Get Service Status    ${output}
        ${status}   ${state}    Get Service Status    ${output}
    END
    Log To Console   ${\n}systemctl status ${service} ${result}
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
    Log To Console     Creating file ${file_name}
    Execute Command    touch ${file_name}  sudo=True  sudo_password=${password}
    SSHLibrary.File Should Exist  ${file_name}

Check file doesn't exist
    [Documentation]    Check file doesn't exist
    [Arguments]        ${file_name}
    Log To Console     Check if file ${file_name} exists
    SSHLibrary.File Should Not Exist  ${file_name}
    Log To Console     File ${file_name} doesn't exist

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
    Log To Console    ${whose}-version: ${output}
    ${major}  ${minor}  ${date}  ${commit}  ${name}     Parse Version   ${output}
    [Return]    ${major}  ${minor}  ${date}  ${commit}  ${name}

Save log
    Connect
    ${output}     Execute Command   journalctl > jrnl.txt${\n}
    ${output}     Execute Command   cat jrnl.txt${\n}
    Log  ${output}
    Close All Connections

Check if ssh is ready on netvm
    [Arguments]    ${timeout}=15
    ${is_ready} =  Set Variable    False
    FOR    ${i}    IN RANGE    ${timeout}
        ${output}  ${rc}    Execute Command    nc -zvw3 192.168.101.1 22    return_rc=True
        ${status}    Run Keyword And Return Status
        ...          Should Be Equal As Integers    ${rc}    0
        IF  ${status}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    Port 22 of NetVM is not ready after ${timeout}

Install sysbench tool
    ${command_output}=    Execute Command    nix-env --query --installed
    ${not_installed} =	Run Keyword And Return Status	Should Not Contain    ${command_output}    sysbench
    IF  ${not_installed}
        Execute Command    nix-env -i sysbench
        ${command_output}=    Execute Command    nix-env --query --installed
        Log To Console    ${\n}Installed packages:${\n}${command_output}
        Should Contain    ${command_output}    sysbench    sysbench tool was not installed
        Log To Console    sysbench tool was succesfully installed
    ELSE
        Log To Console    ${\n}sysbench tool was already installed
    END

Install iperf tool
    ${command_output}=    Execute Command    nix-env --query --installed
    ${not_installed} =	  Run Keyword And Return Status	Should Not Contain    ${command_output}    iperf
    IF  ${not_installed}
        Execute Command   nix-env -i iperf
        ${command_output}=    Execute Command    nix-env --query --installed
        Log To Console    ${\n}Installed packages:${\n}${command_output}
        Should Contain    ${command_output}    iperf    iperf tool was not installed
        Log To Console    iperf tool was succesfully installed
    ELSE
        Log To Console    ${\n}iperf tool was already installed
    END

Get Wifi Interface name
    ${if_name}=    Execute Command    iw dev | awk '$1=="Interface"{print $2}'
    [Return]       ${if_name}

Get wifi IP
    [Documentation]     Parse ifconfig output and looks for wifi IP
    ${if_name}=    Get Wifi Interface name
    ${is_ready} =  Set Variable    False
    FOR    ${i}    IN RANGE    20
        ${output}     Execute Command      ifconfig
        Log           ${output}
        ${ip}         Get wifi ip from ifconfig    ${output}   ${if_name}
        ${status}     Run Keyword And Return Status    Should Not Be Equal As Strings    ${ip}    None
        IF  ${status}
            Log To Console     Ip is ${ip}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    NetVM hasn't gotten an IP

Check if ssh is ready on device
    [Arguments]    ${timeout}=30
    ${is_ready} =  Set Variable    False
    FOR    ${i}    IN RANGE    ${timeout}
        ${rc}  	${output}	 Run And Return Rc And Output   nc -zvw3 ${DEVICE_IP_ADDRESS} 22
        ${status}    Run Keyword And Return Status
        ...          Should Be Equal As Integers	${rc}	0
        IF  ${status}
            Log to console   ${output}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${is_ready} == False
        Log to console  Port 22 (ssh) of ${DEVICE} is not ready after ${timeout}
    END

    [Return]  ${is_ready}
