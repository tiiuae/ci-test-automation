# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Network VM
Force Tags          net-vm  bat  regression

Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/virtualization_keywords.resource
Resource            ../../resources/wifi_keywords.resource


*** Test Cases ***

Verify NetVM is started
    [Documentation]         Verify that NetVM is active and running
    [Tags]                  pre-merge  SP-T45  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330  fmo
    [Setup]                 Switch to vm   ghaf-host
    Verify service status   service=${netvm_service}
    Check Network Availability      ${NETVM_IP}    expected_result=True    range=5

Wifi passthrough into NetVM (Orin-AGX)
    [Documentation]     Verify that wifi works inside netvm
    ...                 Test case not in use in CI/CD Pipeline.
    ...                 Obsoleted when AGX devices use a network adapter.
    [Tags]              # SP-T111  orin-agx  orin-agx-64
    [Setup]             Switch to vm   ${NET_VM}
    Configure wifi      ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP
    Check Network Availability    8.8.8.8   expected_result=True
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=False
    Turn ON WiFi        ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=True
    Turn OFF WiFi       ${TEST_WIFI_SSID}
    Check Network Availability    8.8.8.8   expected_result=False
    Sleep               1
    [Teardown]          Run Keyword  Remove Wifi configuration  ${TEST_WIFI_SSID}

Wifi passthrough into NetVM
    [Documentation]     Verify that wifi works inside netvm
    [Tags]              SP-T101  orin-agx  orin-agx-64  lenovo-x1  darter-pro  dell-7330
    [Setup]             Switch to vm   ${NET_VM}
    Configure wifi      ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
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

NetVM stops and starts successfully
    [Documentation]     Verify that NetVM stops properly and starts after that
    ...                 Test case not in use in CI/CD Pipeline.
    ...                 Obsoleted when AGX devices use a network adapter.
    [Tags]              # SP-T47  SP-T90   orin-agx  orin-agx-64
    [Setup]             Switch to vm   ghaf-host
    Restart NetVM
    [Teardown]          Run Keywords  Start NetVM   AND  Close All Connections

Verify NetVM PCI device passthrough
    [Documentation]     Verify that proper PCI devices have been passed through to the NetVM
    [Tags]              SP-T96  nuc  orin-agx  orin-agx-64  orin-nx
    [Setup]             Switch to vm   ${NET_VM}
    Verify microvm PCI device passthrough    vmname=${NET_VM}
    [Teardown]          Run Keyword If Test Failed  Skip Test If Known Failure


*** Keywords ***

Configure wifi via wpa_supplicant
    [Arguments]         ${SSID}  ${passw}  ${lenovo}=False
    Switch to vm        ${NET_VM}
    Log To Console      Configuring Wifi
    Set Log Level       NONE
    Execute Command     sh -c "wpa_passphrase ${SSID} ${passw} > /etc/wpa_supplicant.conf"   sudo=True    sudo_password=${PASSWORD}
    Execute Command     systemctl restart wpa_supplicant.service   sudo=True    sudo_password=${PASSWORD}
    Set Log Level       INFO

Remove wpa_supplicant configuration
    Switch to vm        ${NET_VM}
    Log To Console      Removing Wifi configuration
    Execute Command     rm /etc/wpa_supplicant.conf  sudo=True    sudo_password=${PASSWORD}
    Execute Command     systemctl restart wpa_supplicant.service  sudo=True    sudo_password=${PASSWORD}

Skip test if known failure
    [Documentation]    Elaborate it possible failure is due to some known reason.
    IF  "AGX" in "${DEVICE}"
        ${journal_log}  Execute command  journalctl -b | grep -i 'Unrecoverable error detected.'
        Run Keyword If  $journal_log != '${EMPTY}'   SKIP  "Known issue: SSRCSP-6423"
    END
