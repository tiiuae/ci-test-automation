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
Resource            ../resources/serial_keywords.resource

*** Variables ***

${NETVM_NAME}       ${EMPTY}


*** Keywords ***

Ping Host
    [Arguments]        ${hostname}  ${timeout}=${PING_SPACING}
    [Documentation]    Ping the given hostname once and return boolean result
    ${ping_output}=    Run Process   ping ${hostname} -c 1 -W ${timeout}   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Check If Ping Fails
    [Documentation]  Check that ping is not getting response from host
    ${result}  Run Process  ping  ${DEVICE_IP_ADDRESS}  -c1  timeout=1s
    Should Not Be Equal   ${result.rc}  ${0}

Check Network Availability
    [Arguments]            ${host}  ${expected_result}=True  ${range}=5  ${limit_freq}=${True}  ${interface}=None
    Log                    Checking network ${host} availability, expected: ${expected_result}  console=True
    IF  $interface != 'None'
        ${cmd}    Set Variable    ping -I ${interface} ${host} -c 1
    ELSE
        ${cmd}    Set Variable    ping ${host} -c 1
    END
    Set Global Variable    ${IS_AVAILABLE}   False
    FOR   ${i}   IN RANGE  ${range}
        Write    ${cmd}
        TRY
            SSHLibrary.Read Until           1 received
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
                IF  ${limit_freq}
                    Sleep       ${PING_SPACING}
                END
                CONTINUE
            END
        END
    END
    # Ensure that ping is not executed too fast after this keyword
    IF  ${limit_freq}
        Sleep       ${PING_SPACING}
    END
    IF    ${IS_AVAILABLE} != ${expected_result}
        FAIL    Expected availability of ${host}: ${expected_result}, in fact: ${IS_AVAILABLE}
    END

Check If Device Is Up
    [Arguments]    ${range}=50
    Set Global Variable    ${IS_AVAILABLE}       False
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        Log         Ping ${DEVICE_IP_ADDRESS}...    console=True
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        Sleep       ${PING_SPACING}
        IF    ${ping}
            Log To Console    Ping ${DEVICE_IP_ADDRESS} successful
            BREAK
        END
    END

    IF    ${ping}
        ${port_22_is_available}     Check if ssh is ready on device
        IF  ${port_22_is_available}
            Set Global Variable    ${CONNECTION_TYPE}    ssh
            Set Global Variable    ${IS_AVAILABLE}       True
        ELSE
            Set Global Variable    ${IS_AVAILABLE}       False
        END
    END

    ${diff}=    Evaluate    int(time.time()) - int(${start_time})

    IF  ${IS_AVAILABLE}    Log To Console    Device woke up after ${diff} sec.

    IF  ${IS_AVAILABLE} == False
        Log To Console    Device is not available via SSH, waited for ${diff} sec!
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
    [Arguments]       ${IP}=${DEVICE_IP_ADDRESS}    ${PORT}=22    ${target}=net-vm   ${iterations}=3
    IF  '${target}' == 'net-vm'
        ${target_output}  Set Variable  ghaf@ghaf-\\d{10}
        Log To Console    Trying to connect to net-vm
    ELSE
        ${target_output}  Set Variable  ${target}
        Log    Expecting ${target_output} target output  console=True
        Log    Trying to connect to ${target_output}  console=True
    END
    # Iterations are necessary at boot for those targets which should expose net-vm to ethernet interface.
    # Ghaf-host is accessible on these targets for a short period of time at boot.
    FOR    ${i}    IN RANGE    ${iterations}
        ${pass_status}  ${connection}    Run Keyword And Ignore Error  Open Connection    ${IP}       port=${PORT}    prompt=\$    timeout=30
        ${login_status}  ${login_output}  Run Keyword And Ignore Error  Login with timeout    username=${LOGIN}    password=${PASSWORD}
        ${pass_status}    Run Keyword And Return Status    Should Match Regexp    ${login_output}    ${target_output}

        IF    ${pass_status}
            ${login_output}   Get Regexp Matches   ${login_output}    ${target_output}
            Log To Console    Connected successfully to ${login_output}[0]
            IF  '${target}' == 'net-vm'
                Set Global Variable  ${NET-VM_GHAF_SSH}    ${connection}
                ${netvm_name}        Get Regexp Matches    ${login_output}[0]    ghaf-\\d{10}
                Set Global Variable  ${NETVM_NAME}         ${netvm_name}[0]
            END
            RETURN  ${connection}
        ELSE
            # If connection was opened to a wrong VM collect logs to find out why
            IF   $login_status=='PASS'
                ${vm_logs}          Execute Command    journalctl
                Log                 ${vm_logs}
                IF  'ghaf@${HOST}' in $login_output
                    ${net-vm_status}    Execute Command    systemctl status ${NETVM_SERVICE}
                    Log                 ${net-vm_status}
                END
                ${login_output}     Clean Login Output   ${login_output}
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

Connect to VM
    [Documentation]      Connect to any VM or ghaf-host over internal virtual network
    [Arguments]          ${vm_name}    ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${timeout}=60
    Switch to vm         ${NET_VM}
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
    IF  not ${logged_in}  Log to console   FAILED to login to ${vm_name} as ${user}.
    IF  not ${logged_in}  FAIL  Could not login to ${vm_name} as ${user}.
    Log To Console  Connected and logged in.
    # If connected and logged in successfully
    RETURN  ${connection}

Save log
    Connect
    ${output}     Execute Command   journalctl > jrnl.txt${\n}
    ${output}     Execute Command   cat jrnl.txt${\n}
    Log  ${output}
    Close All Connections

Check if ssh is ready on vm
    [Arguments]    ${vm}  ${timeout}=40
    IF  $vm=='${NETVM_NAME}'
        Log To Console   WARNING: Use of net-vm hostname in ssh keywords is not recommended.
        Log To Console   Skipping the keyword 'Check if ssh is ready on vm'
        RETURN
    END
    ${start_time}                   Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout}
        ${status}  ${output}    Run Keyword And Ignore Error   Execute Command    timeout 4 nc -zvw3 ${vm} 22    return_rc=True   timeout=5
        ${status}    Run Keyword And Return Status
        ...          Should Be Equal As Integers    ${output}[1]   0
        Sleep        ${PING_SPACING}
        IF  ${status}
            BREAK
        END
        ${diff}=    Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} > ${timeout}
            BREAK
        END
    END
    IF   ${status} == False    FAIL    Port 22 of ${vm} is not ready after ${timeout}

Check if ssh is ready on device
    [Arguments]    ${timeout}=40
    ${is_ready}    Set Variable    False
    ${start_time}  Get Time	epoch
    FOR    ${i}    IN RANGE    ${timeout}
        ${rc}  	${output}	 Run And Return Rc And Output   nc -zvw3 ${DEVICE_IP_ADDRESS} 22
        ${status}    Run Keyword And Return Status
        ...          Should Be Equal As Integers	${rc}	0
        Sleep        ${PING_SPACING}
        IF  ${status}
            Log To Console   ${output}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        ${diff}=    Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} > ${timeout}
            BREAK
        END
    END
    IF   ${is_ready} == False
        Log To Console  Port 22 (ssh) of ${DEVICE} is not ready after ${timeout}
    END

    RETURN  ${is_ready}

Switch to vm
    [Arguments]         ${hostname}   ${user}=ghaf

    Set Log Level           NONE
    IF  $user=='ghaf'
        ${pw}   Set Variable    ${PASSWORD}
    ELSE
        ${pw}   Set Variable    ${USER_PASSWORD}
    END
    Set Log Level           INFO

    ${c_hostname}       Convert To Uppercase    ${hostname}
    ${c_user}           Convert To Uppercase    ${user}
    ${ssh_connection}   Set Variable    ${c_hostname}_${c_user}_SSH

    ${variable_exists}    Check variable availability     ${ssh_connection}

    IF  ${variable_exists}

        ${connection_index}     Set Variable    ${${ssh_connection}}
        ${status}   Try to switch to active vm connection   ${connection_index}   ${hostname}   ${user}

        IF   ${status}   RETURN
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
    IF  $hostname=='${NET_VM}' or $hostname=='${NETVM_NAME}'
        ${host_status}    Run Keyword And Return Status    Should Be Equal    ${output_host}    ${NETVM_NAME}
    ELSE
        ${host_status}    Run Keyword And Return Status    Should Be Equal    ${output_host}    ${hostname}
    END

    IF   $connection_status=='FAIL' or not ${user_status} or not ${host_status}
        RETURN   False
    ELSE
        IF  '${previous_connection}' != '${ssh_index}'   Log    Switched to ${hostname} as ${user}   console=True
        RETURN   True
    END

Check that device is suspended
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console  Device is suspended
    ELSE
        Log To Console  Device is available
        FAIL    Device failed to suspend.
    END

Get VM IP
    ${output}     Execute Command    ifconfig
    ${ip}         Get ip from ifconfig    ${output}   eth
    RETURN        ${ip}

Transfer Shell Script To DUT
    [Arguments]        ${source_path}   ${file_name}   ${target_path}
    Put File           ${source_path}/${file_name}    ${target_path}
    Execute Command    chmod 777 ${target_path}/${file_name}

Transfer Shell Script To VM
    [Arguments]        ${vm}    ${script_name}
    IF  "${vm}" != "net-vm"
        ${vm_fail}    ${result} =    Run Keyword And Ignore Error    Switch to vm    ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Append To List	 ${FAILED_VMS}	  ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Return From Keyword  ${vm_fail}
        Log               Successfully connected to ${vm}  console=True
    END
    Transfer Shell Script To DUT    performance-tests   ${script_name}   /tmp