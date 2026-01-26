# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
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
${NETVM_SYNTAX}     ghaf-[0-9]{10}


*** Keywords ***

Ping Host
    [Arguments]        ${hostname}  ${timeout}=${PING_SPACING}  ${allow_fail}=${False}
    [Documentation]    Ping the given hostname once and return boolean result
    ${ping_output}=    Run Process   ping ${hostname} -c 1 -W ${timeout}   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    IF  ${allow_fail} and not ${ping_success}
        FAIL
    END
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
    [Arguments]       ${expected_output}   ${username}=${LOGIN}   ${password}=${PASSWORD}   ${timeout}=10   ${jumphost}=None
    [Timeout]         ${timeout}
    ${login_output}   Login   username=${username}    password=${password}    jumphost_index_or_alias=${jumphost}
    IF   '${expected_output}' == '${NET_VM}'
        ${status}  ${output}  Run Keyword And Ignore Error   Should Match Regexp    ${login_output}   ${NETVM_SYNTAX}
        IF   '${status}' == 'PASS'
            ${netvm_name}        Get Regexp Matches    ${login_output}    ${NETVM_SYNTAX}
            Set Global Variable  ${NETVM_NAME}    ${netvm_name}[0]
        END
    ELSE
        ${status}  ${output}  Run Keyword And Ignore Error   Should Contain   ${login_output}   ${expected_output}
    END
    IF   '${status}' != 'PASS'
        ${matches}    Get Regexp Matches   ${login_output}    @([^:]+):~   1
        Log   Connected to ${matches}[0] instead   console=True

        # If connection was opened to host collect logs to find out why
        IF   '${HOST}' in $login_output
            Run Keyword And Ignore Error   Run Command    journalctl   timeout=5
            Run Keyword And Ignore Error   Run Command    systemctl status ${NETVM_SERVICE}   timeout=5
        END
        FAIL
    END

Open connection and login
    [Arguments]    ${connection_point}   ${username}   ${password}   ${target_output}   ${jumphost}=None   ${timeout}=60
    Log    Connecting to ${connection_point} as ${username}, target output ${target_output}
    Log To Console    Connecting to ${connection_point} as ${username}...   no_newline=True
    WHILE    True    limit=${timeout} seconds
        TRY
            ${connection}     Open Connection   ${connection_point}   port=22   prompt=\$   timeout=10
        EXCEPT     Keyword timeout 10 seconds exceeded.
            Log    Opening connection timeout 10 seconds reached, trying again    console=True
        EXCEPT
            Log    Failed to open connection, trying again    console=True
        ELSE
            TRY
                Login with timeout   username=${username}   password=${password}   timeout=10   jumphost=${jumphost}   expected_output=${target_output}
            EXCEPT     Keyword timeout 10 seconds exceeded.
                Log    Login timeout 10 seconds reached, trying again    console=True
            EXCEPT
                No Operation   # Do nothing, logging already done in Login with timeout
            ELSE
                Log To Console   Connected to ${connection_point}
                RETURN           ${connection}
            END
            Close Connection
        END
        Sleep    2
    END
    FAIL   Failed to login to ${connection_point} as ${username}

Connect
    [Documentation]   Set up SSH connection to ${target}
    [Arguments]       ${target}   ${timeout}=60
    [Timeout]         ${timeout}
    IF   '${target}' == '${NET_VM}' or '${target}' == '${NETVM_NAME}'   FAIL  Use 'Switch to vm  ${NET_VM}' instead of calling this keyword directly
    Open connection and login   connection_point=${DEVICE_IP_ADDRESS}   username=${LOGIN}   password=${PASSWORD}   target_output=${target}   timeout=${timeout}

Connect to VM
    [Documentation]   Connect to any VM or ghaf-host over internal virtual network
    [Arguments]       ${vm_name}    ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${timeout}=60
    [Timeout]         ${timeout}
    [Tags]            robot:private   # Use 'Switch to vm' instead of calling this keyword directly
    Switch to vm      ${NET_VM}
    Check if ssh is ready on vm        ${vm_name}   ${timeout}
    ${connection}     Open connection and login   connection_point=${vm_name}   username=${user}   password=${pw}   target_output=${vm_name}   jumphost=${NET-VM_GHAF_SSH}   timeout=${timeout}
    RETURN   ${connection}

Save log
    Switch to vm  ${HOST}
    Run Command   journalctl > jrnl.txt${\n}
    Run Command   cat jrnl.txt${\n}
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
        ${status}  ${out}   Run Keyword And Ignore Error   Run Command    timeout 4 nc -zvw3 ${vm} 22  timeout=5
        Sleep        ${PING_SPACING}
        IF   '${status}' == 'PASS'
            BREAK
        END
        ${diff}=    Evaluate    int(time.time()) - int(${start_time})
        IF   ${diff} > ${timeout}
            BREAK
        END
    END
    IF   '${status}' == 'FAIL'    FAIL    Port 22 of ${vm} is not ready after ${timeout}

Check if ssh is ready on device
    [Arguments]    ${timeout}=50
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
    [Arguments]         ${hostname}   ${user}=ghaf   ${timeout}=60

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
        ${connection_index}   Open connection and login   connection_point=${DEVICE_IP_ADDRESS}   username=${LOGIN}   password=${PASSWORD}   target_output=${NET_VM}   timeout=${timeout}
    ELSE
        ${connection_index}   Connect to VM    ${hostname}   ${user}   ${pw}   ${timeout}
    END
    Set Variable By Name     ${ssh_connection}    ${connection_index}

Try to switch to active vm connection
    [Arguments]        ${ssh_index}    ${hostname}   ${user}
    [Tags]             robot:private
    ${connection_status}  ${previous_connection}   Run Keyword And Ignore Error    Switch Connection   ${ssh_index}

    ${status}   ${output_user}    Run Keyword And Ignore Error   Run Command    whoami
    ${user_status}    Run Keyword And Return Status    Should Be Equal    ${output_user}    ${user}

    ${status}   ${output_host}    Run Keyword And Ignore Error   Run Command    hostname
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

Get VM IP
    ${output}     Run Command    ifconfig
    ${ip}         Get ip from ifconfig    ${output}   eth
    RETURN        ${ip}

Transfer Shell Script To DUT
    [Arguments]        ${source_path}   ${file_name}   ${target_path}
    Put File           ${source_path}/${file_name}    ${target_path}
    Run Command        chmod 777 ${target_path}/${file_name}

Transfer Shell Script To VM
    [Arguments]        ${vm}    ${script_name}
    IF  "${vm}" != "net-vm"
        ${vm_fail}    ${result} =    Run Keyword And Ignore Error    Switch to vm    ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Append To List	 ${FAILED_VMS}	  ${vm}
        Run Keyword If    '${vm_fail}' == 'FAIL'   Return From Keyword  ${vm_fail}
        Log               Successfully connected to ${vm}  console=True
    END
    Transfer Shell Script To DUT    performance-tests   ${script_name}   /tmp

Elevate to superuser
    SSHLibrary.Read
    Write                 sudo su
    Sleep                 0.5
    ${out}                SSHLibrary.Read
    IF  'password for ${LOGIN}' in $out
        ${out}            Write        ${PASSWORD}
        Sleep             0.5
        ${out}            SSHLibrary.Read
    END
    IF  'root@' in $out
        RETURN
    END
    FAIL              Elevating to superuser failed
