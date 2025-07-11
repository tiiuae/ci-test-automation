# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             SSHLibrary
Resource            ../config/variables.robot
Library             BuiltIn
Library             String
Library             Process
Library             String
Library             ../lib/output_parser.py
Library             ../lib/helper_functions.py


*** Keywords ***

Ping Host
    [Arguments]        ${hostname}  ${timeout}=10
    [Documentation]    Ping the given hostname once and return boolean result
    ${ping_output}=    Run Process   ping ${hostname} -c 1 -W ${timeout}   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Check Network Availability
    [Arguments]            ${host}  ${expected_result}=True  ${range}=5
    Log To Console         Checking network ${host} availability, expected: ${expected_result}
    Set Global Variable    ${IS_AVAILABLE}   False
    FOR   ${i}   IN RANGE  ${range}
        Write    ping ${host} -c 1
        TRY
            Read Until           1 received
            Set Global Variable  ${IS_AVAILABLE}  True
            Log To Console  ${host} is available
            IF    ${expected_result} == True
                BREAK
            END
        EXCEPT
            IF    ${expected_result} == False
                Log To Console  ${host} is unavailable
                BREAK
            ELSE
                CONTINUE
            END
        END
    END
    IF    ${IS_AVAILABLE} != ${expected_result}
        FAIL    Expected availability of ${host}: ${expected_result}, in fact: ${IS_AVAILABLE}
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
    ELSE IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
        ${target_output}  Set Variable  ghaf@net-vm
    ELSE
        ${target_output}  Set Variable  ghaf@ghaf-host
    END
    # Iterations are necessary at boot for those targets which should expose net-vm to ethernet interface.
    # Ghaf-host is accessible on these targets for a short period of time at boot.
    Log    Trying to connect to ${target_output}  console=True
    FOR    ${i}    IN RANGE    ${iterations}
        ${pass_status}  ${connection}    Run Keyword And Ignore Error  Open Connection    ${IP}       port=${PORT}    prompt=\$    timeout=30
        ${pass_status}  ${login_output}  Run Keyword And Ignore Error  Login with timeout    username=${LOGIN}    password=${PASSWORD}
        ${pass_status}  ${output}        Run Keyword And Ignore Error  Should Contain     ${login_output}   ${target_output}
        IF    $pass_status=='PASS'
            Log To Console    Connected successfully to ${target_output}
            IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
                Set Global Variable  ${NETVM_SSH}    ${connection}
            END
            RETURN  ${connection}
        ELSE
            Close All Connections
            Log To Console    Failed to connect.
        END
        Sleep  5
    END
    FAIL   Failed to connect

Connect to ghaf host
    [Documentation]      Open SSH connection to Ghaf Host
    IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
        ${connection}        Connect
        Set Global Variable  ${NETVM_SSH}    ${connection}
        ${connection}        Connect to VM       ghaf-host
    ELSE
        Log To Console       Connecting to Ghaf Host
        ${connection}        Connect
    END
    Set Global Variable  ${GHAF_HOST_SSH}    ${connection}
    RETURN               ${GHAF_HOST_SSH}

Connect to netvm
    [Documentation]      Open ssh connection to net-vm
    ${connected}   Check ssh connection status   net-vm
    IF  not ${connected}
        IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
            ${connection}   Connect
        ELSE
            Connect to ghaf host
            Log To Console       Connecting to NetVM
            ${connection}        Connect to VM        ${NET_VM}
        END
        Set Global Variable  ${NETVM_SSH}    ${connection}
        RETURN               ${NETVM_SSH}
    END

Connect to VM
    [Documentation]      Connect to any VM or ghaf-host over internal virtual network
    [Arguments]          ${vm_name}    ${user}=${LOGIN}   ${pw}=${PASSWORD}   ${timeout}=60
    Log                  Connecting to ${vm_name} as ${user}...   console=True
    Check if ssh is ready on vm        ${vm_name}   ${timeout}
    ${failed_connection}  Set Variable  True
    ${start_time}  Get Time	epoch
    IF  "Lenovo" in "${DEVICE}" or "NX" in "${DEVICE}" or "Dell" in "${DEVICE}"
        ${jumphost}   Set Variable  ${NETVM_SSH}
    ELSE
        ${jumphost}   Set Variable  ${GHAF_HOST_SSH}
    END
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

Verify Systemctl status
    [Arguments]    ${range}=60    ${user}=False
    [Documentation]    Check is systemctl running with given loop ${range}

    IF    ${user}
        ${cmd}               Set Variable   systemctl status --user
        ${failed_units_cmd}  Set Variable   systemctl list-units --state=failed --user
    ELSE
        ${cmd}               Set Variable   systemctl status
        ${failed_units_cmd}  Set Variable   systemctl list-units --state=failed
    END

    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${output}=    Execute Command    ${cmd}
        ${status}=    Get Systemctl Status    ${output}
        Log  ${output}

        ${data_failed_units}   Execute Command    ${failed_units_cmd}
        Log  ${data_failed_units}
        ${failed_units}  Get failed units  ${data_failed_units}
        Log   ${failed_units}
        Set Test Variable   ${failed_units}

        IF  '${status}' not in ['running', 'starting']
            Log To Console   Systemctl status is ${status}
            FAIL    Systemctl is not running! Status is ${status}. Failed processes are: ${failed_units}
        ELSE IF    '${status}' == 'running'
            ${diff}=    Evaluate    int(time.time()) - int(${start_time})
            Log To Console   Systemctl status is ${status} after ${diff} sec
            RETURN
        END
        Sleep    1
    END
    ${diff}=    Evaluate    int(time.time()) - int(${start_time})
    FAIL    Systemctl is not running after ${diff} sec! Status is ${status}. Failed processes?: ${failed_units}

Check systemctl status for known issues
    [Arguments]    ${known_issues_list}   ${failing_services}
    [Documentation]    Check if failing services contain issues that are not listed as known
    ${old_issues}=    Create List
    ${new_issues}=    Create List
    FOR    ${failing_service}    IN    @{failing_services}
        ${known}=    Set Variable    False
        FOR    ${entry}    IN    @{known_issues_list}
            ${list_device}  ${service}  ${issue}   Parse Known Issue   ${entry}

            ${device_match}=     Run Keyword And Return Status    Should Contain    ${DEVICE}    ${list_device}
            ${service_match}=    Run Keyword And Return Status    Should Contain    ${failing_service}    ${service}

            IF   '${device_match}' == 'True' and ('${service}' == 'ANY' or '${service_match}') == 'True'
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

Check VM systemctl status for known issues
    [Arguments]    ${vm}   ${known_issues_list}   ${failing_services}
    [Documentation]    Check if failing services in VMs contain issues that are not listed as known
    ${old_issues}=    Create List
    ${new_issues}=    Create List
    FOR    ${failing_service}    IN    @{failing_services}
        ${known}=    Set Variable    False
        FOR    ${entry}    IN    @{known_issues_list}
            ${list_vm}  ${service}  ${issue}   Parse Known Issue   ${entry}

            ${vm_match}=         Run Keyword And Return Status    Should Contain    ${vm}    ${list_vm}
            ${service_match}=    Run Keyword And Return Status    Should Contain    ${failing_service}    ${service}

            IF   ('${vm_match}' == 'True' or '${list_vm}' == 'ANY') and ('${service}' == 'ANY' or '${service_match}') == 'True'
                ${known}=     Set Variable    True
            END
        END
        IF    ${known}   
            Append To List    ${old_issues}    ${failing_service}
        ELSE
            Append To List    ${new_issues}    ${failing_service}
        END
    END
    RETURN    ${new_issues}   ${old_issues}

Start application
    [Arguments]      ${app_name}
    Log To Console   ${\n}Starting ${app_name}
    ${output}        Execute Command    cat /etc/xdg/weston/weston.ini
    ${path}          Get App Path  ${output}  ${app_name}
    Execute Command  nohup sh -c '${path}' > output.log 2>&1 &

Check application name
    [Documentation]  Check written format of application
    [Arguments]  ${app_name}
    ${app_name}  Strip String  ${app_name}  characters="'
    ${output}    Execute Command    ls /run/current-system/sw/share/applications/
    ${app}       Get Regexp Matches  ${output}  (?im)${app_name}
    RETURN  '${app}[0]'

Start XDG application
    [Arguments]      ${app_name}  ${gui_vm_app}=false
    Log To Console   ${\n}Starting ${app_name}
    ${app_name}      Check application name  ${app_name}
    ${output}        Execute Command    cat /run/current-system/sw/share/applications/${app_name}.desktop
    ${path}          Get App Path From Desktop  ${output}
    IF  $gui_vm_app
        Execute Command  nohup sh -c 'WAYLAND_DISPLAY=wayland-1 ${path}' > output.log 2>&1 &
    ELSE
        Execute Command  nohup sh -c '${path}' > output.log 2>&1 &
    END

Start Firefox
    [Documentation]  It's needed to set display variable manually because there is no real monitor connected to DUT
    Log To Console  ${\n}Starting Firefox
    ${command_output}   Execute Command    export WAYLAND_DISPLAY=wayland-1   #; nohup firefox > output.log 2>&1 &
    ${firefox}          Execute Command    awk -F= '/^Exec/ {print $2; exit}' /run/current-system/sw/share/applications/Firefox.desktop
    ${command_output}   Execute Command    nohup ${firefox} > output.log 2>&1 &

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
    [Arguments]    @{pids}    ${sig}=9
    FOR   ${pid}  IN  @{pids}
        IF  '${pid}' == '${EMPTY}'
            BREAK
        END
        Execute Command    kill -${sig} ${pid}  sudo=True  sudo_password=${password}  timeout=15
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

    ${welcome_check}  Set Variable If  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"    False    True

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
    Check file exists  ${file_name}

Create text file
    [Documentation]    Create text file with given text and name, requires existing ssh connection
    [Arguments]        ${text}    ${file_name}
    Log To Console     Creating file ${file_name}
    ${out}    ${rc}    Execute Command    echo '${text}' > ${file_name}    return_rc=True
    Should Be True     ${rc} == 0

Remove file
    [Documentation]    Remove file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}  ${user}=ghaf
    Log To Console     Removing file ${file_name}
    IF  $user=='ghaf'
        Execute Command    rm ${file_name}  sudo=True  sudo_password=${PASSWORD}
        Check file doesn't exist  ${file_name}
    ELSE
        Execute Command    rm ${file_name}
        Check file doesn't exist  ${file_name}  user=${USER_LOGIN}
    END

Copy file
    [Documentation]    Copy file, requires existing ssh connection
    [Arguments]        ${file_1}    ${file_2}
    Log To Console     Copying file ${file_1} to ${file_2}
    ${output}  ${rc}   Execute Command    cp ${file_1} ${file_2}   return_rc=True  sudo=True  sudo_password=${password}

Check file exists
    [Documentation]    Check file exists, requires existing ssh connection
    [Arguments]        ${file_name}  ${user}=ghaf
    Log To Console     Check if file ${file_name} exists
    IF  $user=='ghaf'
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True  sudo=True  sudo_password=${password}
    ELSE
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True
    END
    Should Be Equal As Integers   ${rc}   0

Check file doesn't exist
    [Documentation]    Check file doesn't exist, requires existing ssh connection
    [Arguments]        ${file_name}  ${user}=ghaf
    Log To Console     Check if file ${file_name} exists
    IF  $user=='ghaf'
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True  sudo=True  sudo_password=${password}
    ELSE
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True
    END
    Should Be Equal As Integers   ${rc}   2
    Log To Console     File ${file_name} doesn't exist

Verify Ghaf Version Format
    [Documentation]    Check that ghaf-version contains version number in the format:"dd.dd"
    ${version}   Get Ghaf Version
    Should Match Regexp	  ${version}  \\d{2}.\\d{2}.?\\d{0,2}\$

Verify Nixos Version Format
    [Documentation]    Check that nixos-version contains version number in the format:"dd.dd",
    ...                date of commit in format yyyymmdd, 7 symbols of hash commit and version name in brackets
    ${major}  ${minor}  ${date}  ${commit}  ${name}    Get Nixos Version
    Should Match Regexp	  ${major}   ^\\d{2}$
    Should Match Regexp	  ${minor}   ^\\d{2}$
    Verify Date Format    ${date}
    Should Match Regexp	  ${commit}   ^[0-9a-f]{7}$
    IF  '${name}' == 'None'
        FAIL    Expected NixOS version name, but there is None
    END

Get Ghaf Version
    [Documentation]    Get version of Ghaf system, Example:
    ...     "ghaf-version"    output: 23.05   parse result: 23.05
    ${output}   ${rc}    Execute Command   ghaf-version   return_rc=True
    Should Be Equal As Integers     ${rc}   0   Couldn't get ghaf version, command return code
    Log To Console    ghaf-version: ${output}
    RETURN    ${output}

Get Nixos Version
    [Documentation]    Get version of NixOS, Example:
    ...     "nixos-version"   output: 23.05.20230625.35130d4 (Stoat)    parse result: 23.05, 20230625, 35130d4, Stoat
    ${output}   ${rc}    Execute Command   nixos-version   return_rc=True
    Should Be Equal As Integers     ${rc}   0   Couldn't get ghaf version, command return code
    Log To Console    nixos-version: ${output}
    ${major}  ${minor}  ${date}  ${commit}  ${name}     Parse Nixos Version   ${output}
    RETURN    ${major}  ${minor}  ${date}  ${commit}  ${name}

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

Install sysbench tool
    ${command_output}=    Execute Command    nix-env --query --installed
    ${not_installed} =	Run Keyword And Return Status	Should Not Contain    ${command_output}    sysbench
    IF  ${not_installed}
        Execute Command    nix-env -i sysbench
        ${command_output}=    Execute Command    nix-env --query --installed
        Log To Console    ${\n}Installed packages:${\n}${command_output}
        Should Contain    ${command_output}    sysbench    sysbench tool was not installed
        Log To Console    sysbench tool was successfully installed
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
        Log To Console    iperf tool was successfully installed
    ELSE
        Log To Console    ${\n}iperf tool was already installed
    END

Get Wifi Interface name
    ${if_name}=    Execute Command    nmcli device status | grep wifi | head -n 1 | awk '{print $1}'
    RETURN         ${if_name}

Get wifi IP
    [Documentation]     Parse ifconfig output and looks for wifi IP
    ${if_name}=    Get Wifi Interface name
    ${is_ready} =  Set Variable    False
    FOR    ${i}    IN RANGE    20
        ${output}     Execute Command      ifconfig
        Log           ${output}
        ${ip}         Get ip from ifconfig    ${output}   ${if_name}
        ${status}     Run Keyword And Return Status    Should Not Be Equal As Strings    ${ip}    None
        IF  ${status}
            Log To Console     Ip is ${ip}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    NetVM hasn't gotten an IP

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

Check QSPI Version is up to date
    ${output}      Execute Command    ota-check-firmware
    ${fw_version}  ${sw_version}      Get qspi versions   ${output}
    Should Be True	'${fw_version}' == '${sw_version}'	  Update QSPI version! Test results can be wrong!

Stop VM
    [Documentation]     Stopt VM service and check the status.
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]         ${vm_name}
    Log To Console          Going to stop ${vm_name}
    Execute Command         systemctl stop microvm@${vm_name}.service  sudo=True  sudo_password=${PASSWORD}
    Sleep    3
    ${status}  ${state}=    Verify service status  service=microvm@${vm_name}.service  expected_status=inactive  expected_state=dead
    Verify service shutdown status   service=microvm@${vm_name}.service
    Set Global Variable     ${VM_STATE}   ${state}
    Log To Console          ${vm_name} is ${state}

Start VM
    [Documentation]     Try to start VM service service
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]         ${vm_name}
    Log To Console          Going to start ${vm_name}
    Execute Command         systemctl start microvm@${vm_name}.service  sudo=True  sudo_password=${PASSWORD}
    ${status}  ${state}=    Verify service status  service=microvm@${vm_name}.service  expected_status=active  expected_state=running
    Set Global Variable     ${VM_STATE}   ${state}
    Log To Console          ${vm_name} is ${state}
    Wait until NetVM service started

Restart VM
    [Documentation]     Stop VM service via systemctl, wait ${delay} and start VM service
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]         ${vm_name}  ${delay}=3
    Stop VM  ${vm_name}
    Sleep  ${delay}
    Start VM  ${vm_name}
    Check if ssh is ready on vm   ${vm_name}

Check External SSD Size
    [Documentation]  Check the size of ssd used in setup
    Log To Console   Memory to be checked: SSD
    ${lsblk}  Execute Command  lsblk
    ${size}  Get Regexp Matches  ${lsblk}  (?im)(sda .*\\d*:\\d{1}.*\\d{1}\\s)(\\d{1,3})  2
    RETURN  ${size}[0]

Check Internal eMMC Size
    [Documentation]  Check the size of eMMC used in setup
    Log To Console   Memory to be checked: eMMC
    ${lsblk}  Execute Command  lsblk
    ${size}   Get Regexp Matches  ${lsblk}  (?im)(nvme0n1 .*\\d*:\\d{1}.*\\d{1}\\s)(\\d{1,3})  2
    RETURN    ${size}[0]

Check Persist Storage Size
    [Documentation]  Check the size of persistent storage
    ${storage}  Execute Command  df -h
    Log  ${storage}
    ${size}  Get Regexp Matches  ${storage}  (?im)(\\d{1,3}G)\(\\s*.*\\s)(\\d{1,3})(G)(\\s*.*\\s)/persist  3
    RETURN  ${size}[0]

Check ssh connection status
    [Documentation]    Check if there is already an active ssh connection to vm_name
    [Arguments]        ${vm_name}
    ${status}   ${hostname}      Run Keyword And Ignore Error  Execute Command  hostname
    IF  $vm_name in $hostname
        RETURN  ${True}
    ELSE
        RETURN  ${False}
    END

Connect to VM if not already connected
    [Documentation]    Connect only if there is not already an active connection
    [Arguments]        ${vm_name}
    ${connected}   Check ssh connection status   ${vm_name}
    IF  not ${connected}
        Connect to netvm
        Connect to VM   ${vm_name}
    END

Create test user
    Log To Console      Creating test user
    Execute Command     systemctl start setup-test-user.service  sudo=True  sudo_password=${password}

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

    ${connection_index}      Connect to VM          ${hostname}     ${user}     ${pw}
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
