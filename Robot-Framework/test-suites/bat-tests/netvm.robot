# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Network VM
Force Tags          netvm
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Teardown      Close All Connections


*** Variables ***
${netvm_ip}        192.168.101.1
${SSID}            test_network
${wifi_pswd}       test1234
${netwotk_ip}      192.168.1.1
${local_port}      9191
${netvm_state}     ${EMPTY}
${ghaf_host}       ${EMPTY}
${netvm}           ${EMPTY}


*** Test Cases ***

Verify NetVM is started
    [Documentation]         Verify that NetVM is active and running
    [Tags]                  bat   SP-T49  nuc  orin-agx  orin-nx
    [Setup]                 Connect to ghaf host
    Verify service status   service=${netvm_service}
    Check Network Availability      ${netvm_ip}    expected_result=True    range=5
    [Teardown]              Close All Connections

Wifi passthrought into NetVM
    [Documentation]     Verify that wifi works inside netvm
    [Tags]              bat   SP-T50  nuc  orin-agx
    ...                 test:retry(1)
    [Setup]             Run Keywords
    ...                 Connect to ghaf host  AND  Connect to netvm via tunnel  AND
    ...                 Verify service status      service=wpa_supplicant.service
    Configure wifi      ${netvm}  ${SSID}  ${wifi_pswd}
    Get wifi IP
    Check Network Availability    ${netwotk_ip}  expected_result=True
    Log To Console      Switch connection to Ghaf Host
    Switch Connection	${ghaf_host}
    Check Network Availability    ${netwotk_ip}  expected_result=False
    [Teardown]          Remove Wifi configuration

NetVM stops and starts successfully
    [Documentation]     Verify that NetVM stops properly and starts after that
    [Tags]              bat   SP-T52  nuc  orin-agx  orin-nx
    [Setup]     Connect to ghaf host
    Restart NetVM
    [Teardown]  Run Keywords  Start NetVM if dead   AND  Close All Connections

NetVM is wiped after restarting
    [Documentation]     Verify that created file will be removed after restarting VM
    [Tags]              bat   SP-T53  nuc  orin-agx  orin-nx
    [Setup]             Run Keywords
    ...                 Connect to ghaf host  AND  Connect to netvm via tunnel
    Switch Connection   ${netvm}
    Create file         /etc/test.txt
    Switch Connection   ${ghaf_host}
    Restart NetVM
    Check Network Availability      ${netvm_ip}    expected_result=True    range=5
    Connect to netvm via tunnel
    Log To Console      Create if created file still exists
    Check file doesn't exist    /etc/test.txt
    [Teardown]          Run Keywords   Close tunnel  ${ghaf_host}  AND  Close All Connections

Verify wpa_supplicant.service is running
    [Documentation]     Verify that wpa_supplicant.service exists and is running
    [Tags]              bat   SP-T82  nuc  orin-agx
    [Setup]             Run Keywords
    ...                 Connect to ghaf host  AND  Connect to netvm via tunnel
    Switch Connection   ${netvm}
    Verify service status   service=wpa_supplicant.service


*** Keywords ***

Restart NetVM
    [Documentation]    Stop NetVM via systemctl, wait ${delay} and start NetVM
    ...                Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]        ${delay}=3
    Stop NetVM
    Sleep  ${delay}
    Start NetVM
    Check if ssh is ready on netvm

Create tunnel
    [Documentation]  Set up forwarding from a local port through a tunneled connection to NetVM
    ${command}=      Set Variable    ssh -o StrictHostKeyChecking=no -L ${DEVICE_IP_ADDRESS}:${local_port}:${NETVM_IP}:22 ${NETVM_IP} -fN
    ${output}=       Execute Command   ${command}
    @{pid}=          Find pid by name    ${command}

Close tunnel
    [Documentation]    Check if tunnel to netvm exists and kill the process
    [Arguments]        ${ghaf_host}
    Switch Connection  ${ghaf_host}
    Log to Console  ${\n}Check if there are existing tunnels to NetVM
    ${command}=     Set Variable    ssh -o StrictHostKeyChecking=no -L ${DEVICE_IP_ADDRESS}:${local_port}:${NETVM_IP}:22 ${NETVM_IP} -fN
    @{pid}=         Find pid by name    ${command}
    IF  @{pid} != @{EMPTY}
        Log to Console  Close existing tunnels with pids: @{pid}
        Kill process    @{pid}  sig=9
    END

Connect to ghaf host
    [Documentation]      Open ssh connection to ghaf host
    ${connection}=       Connect
    Set Global Variable  ${ghaf_host}    ${connection}
    [Return]             ${connection}

Connect to netvm in console
    [Documentation]    Open connection to ghaf host and connect to NetVM inside the console, execute sudo su,
    ...                allow executing commands in netvm only through Write/read
    ${netvm_root}=	Open Connection    ${DEVICE_IP_ADDRESS}
    Login           username=${LOGIN}  password=${PASSWORD}
    Write           ssh-keygen -R ${netvm_ip}
    Login into NetVM
    [Return]        ${netvm_root}

Connect to netvm via tunnel
    [Documentation]    Create tunnel using port ${local_port}, connect to netvm directly from test run machine,
    ...                allow using standard SSHLibrary commands, like 'Execute Command'
    Switch connection  ${ghaf_host}
    Close tunnel       ${ghaf_host}
    Log To Console     Configuring tunnel...
    Write              ssh-keygen -R ${netvm_ip}
    Copy keys
    Clear iptables rules
    Create tunnel
    Log To Console     Connecting to NEtVM via tunnel
    ${connection}=       Connect     IP=${DEVICE_IP_ADDRESS}    PORT=${local_port}    target_output=${LOGIN}@${NETVM_NAME}
    Set Global Variable  ${netvm}    ${connection}
    [Return]           ${netvm}

Copy keys
    [Documentation]  Generate new local ssh keys and copy public keys to NetVM
    Execute Command  rm /home/ghaf/.ssh/id_rsa
    Write            ssh-keygen
    Read Until       Enter file in which to save the key (/home/ghaf/.ssh/id_rsa):
    Write            ${\n}
    Read Until       Enter passphrase (empty for no passphrase):
    Write            ${\n}
    Read Until       Enter same passphrase again:
    Write            ${\n}
    Read Until       ${LOGIN}@ghaf-host:
    Write            ssh-copy-id -o StrictHostKeyChecking=no ${netvm_ip}
    ${output}=       Read       delay=30s
    Should Contain   ${output}  Password:
    Write            ${password}
    Read Until       ${LOGIN}@ghaf-host:

Clear iptables rules
    [Documentation]  Clear IP tables rules to open ports for creating tunnel
    Execute Command  iptables -F  sudo=True  sudo_password=${PASSWORD}

Login into NetVM
    Log To Console  Login into NetVM
    Write           ssh-keygen -R ${netvm_ip}
    Write           ssh ${LOGIN}@${netvm_ip}
    ${output}=	    Read	delay=0.5s
    ${fingerprint}  Run Keyword And Return Status    Should Contain    ${output}     fingerprint
    IF  ${fingerprint}
        Write       yes
    END
    ${output}=	    Read    delay=0.5s
    ${passw}        Run Keyword And Return Status    Should Contain    ${output}     Password
    IF  ${passw}
        Write       ${PASSWORD}
        Read Until  ${LOGIN}@${NETVM_NAME}
    END
    Write           sudo su
    Read Until      password
    Write           ${PASSWORD}
    Read Until      root@${NETVM_NAME}

Configure wifi
    [Arguments]   ${netvm}  ${SSID}  ${passw}
    Switch Connection  ${netvm}
    Log To Console     Configuring Wifi
    Execute Command    sh -c "wpa_passphrase ${SSID} ${passw} > /etc/wpa_supplicant.conf"   sudo=True    sudo_password=${PASSWORD}
    Execute Command    systemctl restart wpa_supplicant.service   sudo=True    sudo_password=${PASSWORD}

Remove Wifi configuration
    Switch Connection   ${netvm}
    Log To Console      Removing Wifi configuration
    Execute Command     rm /etc/wpa_supplicant.conf  sudo=True    sudo_password=${PASSWORD}
    Execute Command     systemctl restart wpa_supplicant.service  sudo=True    sudo_password=${PASSWORD}
    [Teardown]          Close All Connections

Stop NetVM
    [Documentation]     Ensure that NetVM is started, stop it and check the status.
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Verify service status   service=${netvm_service}   expected_status=active   expected_state=running
    Log To Console          Going to stop NetVM
    Execute Command         systemctl stop ${netvm_service}  sudo=True  sudo_password=${PASSWORD}
    Sleep    3
    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=inactive  expected_state=dead
    Verify service shutdown status   service=${netvm_service}
    Set Global Variable     ${netvm_state}   ${state}
    Log To Console          NetVM is ${state}

Start NetVM
    [Documentation]     Try to start NetVM service
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Log To Console          Going to start NetVM
    Execute Command         systemctl start ${netvm_service}  sudo=True  sudo_password=${PASSWORD}
    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running
    Set Global Variable     ${netvm_state}   ${state}
    Log To Console          NetVM is ${state}
    Wait until NetVM service started

Start NetVM if dead
    [Documentation]     Teardown keyword. Check global variable ${netvm_state} and start NetVM if it's stopped.
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    IF  '${netvm_state}' == 'dead'
        Start NetVM
    END
