# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Network VM
Force Tags          netvm  bat  regression
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/virtualization_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../config/variables.robot
Suite Teardown      Close All Connections


*** Variables ***
${NETVM_STATE}     ${EMPTY}
${GHAF_HOST_SSH}   ${EMPTY}
${NETVM_SSH}       ${EMPTY}


*** Test Cases ***

Verify NetVM is started
    [Documentation]         Verify that NetVM is active and running
    [Tags]                  SP-T45  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1   dell-7330  fmo
    [Setup]                 Connect to ghaf host
    Verify service status   service=${netvm_service}
    Check Network Availability      ${NETVM_IP}    expected_result=True    range=5
    [Teardown]              Close All Connections

Wifi passthrough into NetVM (Orin-AGX)
    [Documentation]     Verify that wifi works inside netvm
    [Tags]              SP-T111  orin-agx  orin-agx-64
    [Setup]             Connect to netvm
    Configure wifi      ${NETVM_SSH}  ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP
    Check Network Availability    8.8.8.8   expected_result=True
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=False
    Turn ON WiFi        ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=True
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=False
    Sleep               1
    [Teardown]          Run Keywords  Remove Wifi configuration  ${TEST_WIFI_SSID}  AND  Close All Connections

Wifi passthrough into NetVM (Lenovo-X1)
    [Documentation]     Verify that wifi works inside netvm
    [Tags]              SP-T101   lenovo-x1   dell-7330
    [Setup]             Connect to netvm
    Configure wifi      ${NETVM_SSH}  ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Sleep               1
    ${pass_status}    ${output}   Run Keyword And Ignore Error    Get wifi IP
        IF    $pass_status=='PASS'
            FAIL    Expected: no IP address on wifi interface after turning wifi off.
        END
    Turn ON WiFi        ${TEST_WIFI_SSID}
    Get wifi IP
    [Teardown]          Run Keywords  Remove Wifi configuration  ${TEST_WIFI_SSID}  AND  Close All Connections

Wifi passthrough into NetVM (NUC)
    [Documentation]     Verify that wifi works inside netvm
    [Tags]              SP-T111  nuc
    [Setup]             Connect to netvm
    Configure wifi via wpa_supplicant      ${netvm_ssh}  ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Check Network Availability    8.8.8.8   expected_result=True
    Remove wpa_supplicant configuration
    Check Network Availability    8.8.8.8   expected_result=False
    [Teardown]          Run Keywords  Remove wpa_supplicant configuration  AND  Close All Connections

NetVM stops and starts successfully
    [Documentation]     Verify that NetVM stops properly and starts after that
    [Tags]              SP-T47  SP-T90  nuc  orin-agx  orin-agx-64
    [Setup]             Connect to ghaf host
    Restart NetVM
    [Teardown]          Run Keywords  Start NetVM if dead   AND  Close All Connections

NetVM is wiped after restarting
    [Documentation]     Verify that created file will be removed after restarting VM
    [Tags]              SP-T48  nuc  orin-agx  orin-agx-64
    [Setup]             Connect to netvm
    Create file         /etc/test.txt
    Switch Connection   ${GHAF_HOST_SSH}
    Restart NetVM
    Close All Connections
    Connect to ghaf host
    Check Network Availability      ${NETVM_IP}    expected_result=True    range=15
    Connect to netvm
    Log To Console      Check if created file still exists
    Check file doesn't exist    /etc/test.txt
    [Teardown]          Run Keywords  Close All Connections   AND
    ...                 Run Keyword If  "AGX" in "${DEVICE}"  Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-6423"

Verify NetVM PCI device passthrough
    [Documentation]     Verify that proper PCI devices have been passed through to the NetVM
    [Tags]              SP-T96  nuc  orin-agx  orin-agx-64  orin-nx
    [Setup]             Connect to netvm
    Verify microvm PCI device passthrough    vmname=${NET_VM}
    [Teardown]          Run Keywords  Close All Connections   AND
    ...                 Run Keyword If  "AGX" in "${DEVICE}"  Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-6423"


*** Keywords ***

Restart NetVM
    [Documentation]    Stop NetVM via systemctl, wait ${delay} and start NetVM
    ...                Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]        ${delay}=5
    Stop NetVM
    Sleep  ${delay}
    Start NetVM
    Check if ssh is ready on vm   ${NET_VM}

Stop NetVM
    [Documentation]     Ensure that NetVM is started, stop it and check the status.
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Verify service status   service=${netvm_service}   expected_status=active   expected_state=running
    Log To Console          Going to stop NetVM
    Execute Command         systemctl stop ${netvm_service}  sudo=True  sudo_password=${PASSWORD}  timeout=120  output_during_execution=True
    Sleep    3
    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=inactive  expected_state=dead
    Verify service shutdown status   service=${netvm_service}
    Set Global Variable     ${NETVM_STATE}   ${state}
    Log To Console          NetVM is ${state}

Start NetVM
    [Documentation]     Try to start NetVM service
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Log To Console          Going to start NetVM
    Execute Command         systemctl start ${netvm_service}  sudo=True  sudo_password=${PASSWORD}  timeout=120  output_during_execution=True
    ${status}  ${state}=    Verify service status  service=${netvm_service}  expected_status=active  expected_state=running
    Set Global Variable     ${NETVM_STATE}   ${state}
    Log To Console          NetVM is ${state}
    Wait until NetVM service started

Start NetVM if dead
    [Documentation]     Teardown keyword. Check global variable ${NETVM_STATE} and start NetVM if it's stopped.
    ...                 Pre-condition: requires active ssh connection to ghaf host.
    Start NetVM

Configure wifi via wpa_supplicant
    [Arguments]         ${netvm_ssh}  ${SSID}  ${passw}  ${lenovo}=False
    Switch Connection   ${netvm_ssh}
    Log To Console      Configuring Wifi
    Set Log Level       NONE
    Execute Command     sh -c "wpa_passphrase ${SSID} ${passw} > /etc/wpa_supplicant.conf"   sudo=True    sudo_password=${PASSWORD}
    Execute Command     systemctl restart wpa_supplicant.service   sudo=True    sudo_password=${PASSWORD}
    Set Log Level       INFO

Remove wpa_supplicant configuration
    Switch Connection   ${netvm_ssh}
    Log To Console      Removing Wifi configuration
    Execute Command     rm /etc/wpa_supplicant.conf  sudo=True    sudo_password=${PASSWORD}
    Execute Command     systemctl restart wpa_supplicant.service  sudo=True    sudo_password=${PASSWORD}
