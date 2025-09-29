# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/helper_functions.py
Library             ../lib/output_parser.py
Library             OperatingSystem
Library             Process
Library             SSHLibrary
Library             String
Resource            ../config/variables.robot
Resource            ../resources/common_keywords.resource


*** Keywords ***

Ping Host
    [Arguments]        ${hostname}  ${timeout}=10
    [Documentation]    Ping the given hostname once and return boolean result
    ${ping_output}=    Run Process   ping ${hostname} -c 1 -W ${timeout}   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Check If Ping Fails
    [Documentation]  Check that ping is not getting response from host
    ${result}  Run Process  ping  ${DEVICE_IP_ADDRESS}  -c1  timeout=1s
    Should Not Be Equal   ${result.rc}  ${0}

Check Network Availability
    [Arguments]            ${host}  ${expected_result}=True  ${range}=5
    Log                    Checking network ${host} availability, expected: ${expected_result}  console=True
    Set Global Variable    ${IS_AVAILABLE}   False
    FOR   ${i}   IN RANGE  ${range}
        Write    ping ${host} -c 1
        TRY
            Read Until           1 received
            Set Global Variable  ${IS_AVAILABLE}  True
            Log   ${host} is available  console=True
            IF    ${expected_result} == True
                BREAK
            END
        EXCEPT
            IF    ${expected_result} == False
                Log    ${host} is unavailable  console=True
                BREAK
            ELSE
                CONTINUE
            END
        END
    END
    IF    ${IS_AVAILABLE} != ${expected_result}
        FAIL    Expected availability of ${host}: ${expected_result}, in fact: ${IS_AVAILABLE}
    END

Check If Device Is Up
    [Arguments]    ${range}=20
    Set Global Variable    ${IS_AVAILABLE}       False
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}
            Log To Console    Ping ${DEVICE_IP_ADDRESS} successful
            BREAK
        END
        Sleep  1
    END

    IF    ${ping}
        ${port_22_is_available}     Check if ssh is ready on device
        IF  ${port_22_is_available}
            Set Global Variable    ${IS_AVAILABLE}       True
        ELSE
            Set Global Variable    ${IS_AVAILABLE}       False
        END
    END

    ${diff}=    Evaluate    int(time.time()) - int(${start_time})

    IF  ${IS_AVAILABLE}    Log To Console    Device woke up after ${diff} sec.

    IF  ${IS_AVAILABLE} == False
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END

Login with timeout
    [Arguments]       ${username}=${LOGIN}    ${password}=${PASSWORD}   ${timeout}=30   ${jumphost}=None
    [Timeout]         ${timeout}
    IF  $jumphost != 'None'
        ${login_output}   Login   username=${username}    password=${password}    jumphost_index_or_alias=${jumphost}
    ELSE
        ${login_output}   Login   username=${username}    password=${password}
    END
    RETURN            ${login_output}

Connect
    [Documentation]   Set up the SSH connection to the device
    [Arguments]       ${IP}=${DEVICE_IP_ADDRESS}    ${PORT}=22    ${target_output}=None   ${iterations}=3
    IF  '${target_output}' != 'None'
        Log To Console    Expecting ${target_output} target output
    ELSE
        ${target_output}  Set Variable  ghaf@net-vm
    END
    # Iterations are necessary at boot for those targets which should expose net-vm to ethernet interface.
    # Ghaf-host is accessible on these targets for a short period of time at boot.
    Log    Trying to connect to ${target_output}  console=True
    FOR    ${i}    IN RANGE    ${iterations}
        ${pass_status}  ${connection}    Run Keyword And Ignore Error  Open Connection    ${IP}       port=${PORT}    prompt=\$    timeout=30
        ${login_status}  ${login_output}  Run Keyword And Ignore Error  Login with timeout    username=${LOGIN}    password=${PASSWORD}
        ${pass_status}  ${output}        Run Keyword And Ignore Error  Should Contain     ${login_output}   ${target_output}
        IF    $pass_status=='PASS'
            Log To Console    Connected successfully to ${target_output}
            Set Global Variable  ${NET-VM_GHAF_SSH}    ${connection}
            RETURN  ${connection}
        ELSE
            # If connection was opened to a wrong VM collect logs to find out why
            IF   $login_status=='PASS'
                ${vm_logs}          Execute Command    journalctl
                Log                 ${vm_logs}
                IF  'ghaf@ghaf-host' in $login_output
                    ${net-vm_status}    Execute Command    systemctl status ${NETVM_SERVICE}
                    Log                 ${net-vm_status}
                END
                Log To Console      Failed to connect to ${target_output}, connected to ${login_output} instead.
            ELSE
                Log To Console    Failed to connect.
            END
            Close All Connections
        END
        Sleep  5
    END
    IF   $login_status=='PASS'
        FAIL   Failed to connect to ${target_output}, connected to ${login_output} instead
    END
    FAIL   Failed to connect

# Only used in performance tests
Connect to ghaf host
    [Documentation]      Open SSH connection to Ghaf Host
    ${connected}   Check ssh connection status   ghaf-host
    IF  not ${connected}
        Connect
        Switch to vm         ghaf-host
    END

# Only used in performance tests
Connect to netvm
    [Documentation]      Open ssh connection to net-vm
    ${connected}   Check ssh connection status   net-vm
    IF   not ${connected}   Connect


Connect to VM
    [Documentation]      Connect to any VM or ghaf-host over internal virtual network
    [Arguments]          ${vm_name}    ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${timeout}=60
    Switch to vm   ${NET_VM}
    Log                  Connecting to ${vm_name} as ${user}...   console=True
    Check if ssh is ready on vm        ${vm_name}   ${timeout}
    ${failed_connection}  Set Variable  True
    ${start_time}  Get Time	epoch
    ${jumphost}    Set Variable  ${NET-VM_GHAF_SSH}
    # Opening connection
    FOR    ${i}    IN RANGE    10
        TRY
            ${connection}=       Open Connection    ${vm_name}    port=22    prompt=\$    timeout=30
        EXCEPT    ChannelException: ChannelException(2, 'Connect failed')    type=LITERAL
            ${diff}=    Evaluate    int(time.time()) - int(${start_time})
            IF   ${diff} < ${timeout}
                Sleep    1
                CONTINUE
            ELSE
                BREAK
            END
        END
        ${failed_connection}    Set Variable  False
        BREAK
    END
    IF  ${failed_connection}    FAIL  Couldn't connect ${vm_name}
    # Logging in to vm
    ${logged_in}  Set Variable  False
    FOR    ${i}    IN RANGE     5
        ${status}  ${login_output}   Run Keyword And Ignore Error  Login with timeout  username=${user}  password=${pw}  jumphost=${jumphost}
        ${logged_in}            Run Keyword And Return Status  Should Contain  ${login_output}  ${vm_name}
        Exit For Loop If        ${logged_in}
        Sleep                   2
    END
    IF  not ${logged_in}  FAIL  Could not login to ${vm_name} as ${user}.
    Log To Console  Connected and logged in.
    # If connected and logged in successfully
    RETURN  ${connection}

Is process started
    [Arguments]    ${pid}
    ${rc}=      Execute Command    ps -p ${pid}   return_rc=True
    ${status}=  Run Keyword And Return Status   Should Be Equal As Integers	 ${rc[1]}	0
    RETURN      ${status}

Find pid by name
    [Arguments]   ${proc_name}  ${exact_match}=false
    Log To Console    Looking for pids of the process ${proc_name}
    IF  $exact_match=='true'
        ${output}=    Execute Command    sh -c 'ps aux | grep -E " ${proc_name}$" | grep -v grep'
    ELSE
        ${output}=    Execute Command    sh -c 'ps aux | grep "${proc_name}" | grep -v grep'
    END
    Log           ${output}
    @{pids}=      Find Pid    ${output}  ${proc_name}
    Log To Console    Found PIDs for process '${proc_name}':\n${pids}
    RETURN        @{pids}

Kill process
    [Arguments]    @{pids}    ${sig}=9    ${sudo}=True
    FOR   ${pid}  IN  @{pids}
        IF  '${pid}' == '${EMPTY}'
            BREAK
        END
        IF  $sudo == "True"
            Execute Command    kill -${sig} ${pid}  sudo=True  sudo_password=${password}  timeout=15
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

Verify service status
    [Documentation]   Check if service is running with given loop ${range}
    [Arguments]       ${range}=45  ${service}=${EMPTY}   ${expected_status}=active   ${expected_state}=running  ${expected_rc}=0
    ${vmservice}      Run Keyword And Return Status  Should Contain  ${service}  microvm@
    ${finished}       Set Variable  False

    ${welcome_check}  Set Variable If  "Lenovo" in "${DEVICE}" or "Darter" in "${DEVICE}" or "Dell" in "${DEVICE}"    False    True

    FOR    ${i}    IN RANGE    ${range}
        ${output}  ${stderr}  ${rc}=   Execute Command  systemctl status ${service}  return_stderr=True  return_rc=True
        Log           stdout: ${output}\nstderr: ${stderr}
        Should Not Be Equal As Integers	    ${rc}	4   Stderr: "${stderr}", Return code
        ${result}     Get Service Status    ${output}
        ${status}     ${state}    Get Service Status    ${output}
        ${status}     Run Keyword And Return Status    Should Be True	'${status}' == '${expected_status}'  Expected ${expected_status} but in fact ${status}
        ${state}      Run Keyword And Return Status    Should Be True	'${state}' == '${expected_state}'    Expected ${expected_state} but in fact ${state}

        # 'Welcome to NixOS' is not got if 'non-vm service' or if service is expected to be inactive/dead.
        IF  ${vmservice} and '${expected_state}' == 'running' and ${status} and ${state} and ${welcome_check}
            ${finished}    Run Keyword And Return Status    Should Contain    ${output}    Welcome to NixOS
            IF  ${finished}
                BREAK
            END
        ELSE IF  ${status} and ${state}
            ${finished}     Set Variable  True
            BREAK
        END
        Sleep    1
    END

    IF  ${finished}
        Log To Console  ${\n}systemctl status ${service} ${result}
    ELSE
        Log To Console  Verify service status failed. Last lines of systemctl status -log: ${output[-300:]}
        Fail  systemctl status ${service} ${result}, expected: ${expected_status} and ${expected_state}
    END
    RETURN    ${status}  ${state}

Verify service shutdown status
    [Documentation]   Check if service was stopped properly
    [Arguments]       ${service}=${EMPTY}   ${expected_code}=exited   ${expected_status}=0/SUCCESS
    ${output}=          Execute Command    systemctl status ${service}
    ${code}  ${status}  Verify shutdown status    ${output}
    Log To Console    Service shutdown result: code=${code}, status=${status}
    Should Be True	  '${code}' == '${expected_code}'      Expected ${expected_code} but in fact ${code}
    Should Be True	  '${status}' == '${expected_status}'  Expected ${expected_status} but in fact ${status}

Wait until NetVM service started
    [Arguments]       ${timeout}=30
    ${is_started} =   Set Variable    False
    FOR    ${i}    IN RANGE    ${timeout}
        ${output}=     Execute Command    systemctl status ${netvm_service}
        Log            ${output}
        ${status} =    Run Keyword And Return Status    Should Contain    ${output}    Welcome to NixOS
        IF    ${status}
            ${is_started} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    NetVM is not ready after ${timeout}

Save log
    Connect
    ${output}     Execute Command   journalctl > jrnl.txt${\n}
    ${output}     Execute Command   cat jrnl.txt${\n}
    Log  ${output}
    Close All Connections

Check if ssh is ready on vm
    [Arguments]    ${vm}  ${timeout}=30
    ${already_connected}            Check ssh connection status     ${vm}
    IF  ${already_connected}
        RETURN
    END
    ${start_time}                   Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout}
        ${status}  ${output}    Run Keyword And Ignore Error   Execute Command    timeout 6 nc -zvw3 ${vm} 22    return_rc=True   timeout=10
        ${status}    Run Keyword And Return Status
        ...          Should Be Equal As Integers    ${output}[1]   0
        IF  ${status}
            BREAK
        END
        ${diff}=    Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout}
            Sleep    1
        ELSE
            BREAK
        END
    END
    IF   ${status} == False    FAIL    Port 22 of ${vm} is not ready after ${timeout}

Get Virtual Network Interface IP
    [Documentation]     Parse ifconfig output and look for ethint0 IP
    ${if_name}=    Set Variable   ethint0
    FOR    ${i}    IN RANGE    20
        ${output}     Execute Command      ifconfig
        Log           ${output}
        ${ip}         Get ip from ifconfig    ${output}   ${if_name}
        IF  $ip != '${EMPTY}'
            Log       ${ip}
            RETURN    ${ip}
        END
        Sleep    1
    END
    FAIL    IP address not found.

Check if ssh is ready on device
    [Arguments]    ${timeout}=30
    ${is_ready}    Set Variable    False
    ${start_time}  Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout}
        ${rc}  	${output}	 Run And Return Rc And Output   nc -zvw3 ${DEVICE_IP_ADDRESS} 22
        ${status}    Run Keyword And Return Status
        ...          Should Be Equal As Integers	${rc}	0
        IF  ${status}
            Log To Console   ${output}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        ${diff}=    Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} < ${timeout}
            Sleep    1
        ELSE
            BREAK
        END
    END
    IF   ${is_ready} == False
        Log To Console  Port 22 (ssh) of ${DEVICE} is not ready after ${timeout}
    END

    RETURN  ${is_ready}

Check ssh connection status
    [Documentation]    Check if there is already an active ssh connection to vm_name
    [Arguments]        ${vm_name}
    ${status}   ${hostname}      Run Keyword And Ignore Error  Execute Command  hostname
    IF  $vm_name in $hostname
        RETURN  ${True}
    ELSE
        RETURN  ${False}
    END

Switch to vm
    [Arguments]         ${hostname}   ${user}=ghaf

    IF  $user=='ghaf'
        ${pw}   Set Variable    ${PASSWORD}
    ELSE
        ${pw}   Set Variable    ${USER_PASSWORD}
    END

    ${c_hostname}       Convert To Uppercase    ${hostname}
    ${c_user}           Convert To Uppercase    ${user}
    ${ssh_connection}   Set Variable    ${c_hostname}_${c_user}_SSH

    ${variable_exists}    Check variable availability     ${ssh_connection}

    IF  ${variable_exists}

        ${connection_index}     Set Variable    ${${ssh_connection}}
        ${status}   Try to switch to active vm connection   ${connection_index}   ${hostname}   ${user}

        IF   ${status}
            Log    Switched to ${hostname} as ${user}   console=True
            RETURN
        END
    END
    IF  '${hostname}' == '${NET_VM}'
        ${connection_index}      Connect
    ELSE
        ${connection_index}      Connect to VM          ${hostname}     ${user}     ${pw}
    END
    Set Variable By Name     ${ssh_connection}    ${connection_index}

Try to switch to active vm connection
    [Arguments]        ${ssh_index}    ${hostname}   ${user}

    ${connection_status}  ${previous_connection}   Run Keyword And Ignore Error    Switch Connection   ${ssh_index}

    ${status}   ${output_user}    Run Keyword And Ignore Error   Execute Command    whoami
    Log    ${output_user}
    ${user_status}    Run Keyword And Return Status    Should Be Equal    ${output_user}    ${user}

    ${status}   ${output_host}    Run Keyword And Ignore Error   Execute Command    hostname
    Log    ${output_host}
    ${host_status}    Run Keyword And Return Status    Should Be Equal    ${output_host}    ${hostname}

    IF   $connection_status=='FAIL' or not ${user_status} or not ${host_status}
        RETURN   False
    ELSE
        RETURN   True
    END
