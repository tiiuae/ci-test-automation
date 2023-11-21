# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Network VM
Force Tags          netvm
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/virtualization_keywords.resource
Resource            ../../config/variables.robot
Suite Teardown      Close All Connections


*** Variables ***
${netvm_ip}        192.168.101.1
${SSID}            test_network
${wifi_pswd}       test1234
${netwotk_ip}      192.168.1.1
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
    ...                 Connect to ghaf host  AND  Connect to netvm  AND
    ...                 Verify service status      service=wpa_supplicant.service
    Configure wifi      ${netvm}  ${SSID}  ${wifi_pswd}
    Get wifi IP
    Check Network Availability    ${netwotk_ip}  expected_result=True
    Log To Console      Switch connection to Ghaf Host
    Switch Connection	${ghaf_host}
    Check Network Availability    ${netwotk_ip}  expected_result=False
    [Teardown]          Run Keywords  Remove Wifi configuration  AND  Close All Connections

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
    ...                 Connect to ghaf host  AND  Connect to netvm
    Switch Connection   ${netvm}
    Create file         /etc/test.txt
    Switch Connection   ${ghaf_host}
    Restart NetVM
    Close All Connections
    Connect to ghaf host
    Check Network Availability      ${netvm_ip}    expected_result=True    range=5
    Connect to netvm
    Log To Console      Create if created file still exists
    Check file doesn't exist    /etc/test.txt
    [Teardown]          Run Keywords   Close All Connections

Verify wpa_supplicant.service is running
    [Documentation]     Verify that wpa_supplicant.service exists and is running
    [Tags]              bat   SP-T82  nuc  orin-agx
    [Setup]             Run Keywords
    ...                 Connect to ghaf host  AND  Connect to netvm
    Switch Connection   ${netvm}
    Verify service status   service=wpa_supplicant.service
    [Teardown]          Run Keywords   Close All Connections

Verify NetVM PCI device passthrough
    [Documentation]     Verify that proper PCI devices have been passed through to the NetVM
    [Tags]              bat   SP-T101  nuc  orin-agx  orin-nx
    [Setup]             Run Keywords
    ...                 Connect to ghaf host  AND  Connect to netvm
    Verify microvm PCI device passthrough    host_connection=${ghaf_host}    vm_connection=${netvm}    vmname=${NETVM_NAME}
    [Teardown]          Run Keywords   Close All Connections


*** Keywords ***

Restart NetVM
    [Documentation]    Stop NetVM via systemctl, wait ${delay} and start NetVM
    ...                Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]        ${delay}=3
    Stop NetVM
    Sleep  ${delay}
    Start NetVM
    Check if ssh is ready on netvm

Connect to ghaf host
    [Documentation]      Open ssh connection to ghaf host
    ${connection}=       Connect
    Set Global Variable  ${ghaf_host}    ${connection}
    [Return]             ${connection}

Connect to netvm
    [Documentation]    Connect to netvm directly from test run machine, using
    ...                jumphost, this allows using standard SSHLibrary
    ...                commands, like 'Execute Command'
    Log To Console     Connecting to NetVM
    ${connection}=     Open Connection     ${NETVM_IP}    port=22
    ${output}=         Login    username=${LOGIN}    password=${PASSWORD}    jumphost_index_or_alias=${ghaf_host}
    Set Global Variable  ${netvm}    ${connection}
    [Return]           ${netvm}

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
