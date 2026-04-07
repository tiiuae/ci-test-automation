# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Network VM
Test Tags           net-vm  bat

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/virtualization_keywords.resource
Resource            ../../resources/wifi_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/service_keywords.resource


*** Test Cases ***

Verify NetVM is started
    [Documentation]         Verify that NetVM is active and running
    [Tags]                  SP-T45  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  fmo
    [Setup]                 Switch to vm   ${HOST}
    Verify service status   service=${netvm_service}
    Check Network Availability      ${NET_VM}    expected_result=True    range=5

    [Teardown]              Run Keywords  Reboot Orin if ssh connection dropped
    ...                     AND           Run Keyword If  "${DEVICE_TYPE}" == "orin-nx"  Run Keyword If Test Failed  Skip  "Under investigation: SSRCSP-7453"

Wifi passthrough into NetVM
    [Documentation]     Verify that wifi works inside netvm and internet is available
    [Tags]              SP-T101  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  lab-only
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
    Check Network Availability   8.8.8.8   limit_freq=${False}   interface=wifi
    [Teardown]          Run Keywords  Remove Wifi configuration  ${TEST_WIFI_SSID}  AND  Close All Connections

Ethernet passthrough into NetVM
    [Documentation]     Verify that ethernet connection works inside netvm and internet is available
    [Tags]              SP-T62  SP-T62-1  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  lab-only
    [Setup]             Switch to vm   ${NET_VM}
    Check Network Availability   8.8.8.8   limit_freq=${False}   interface=eth

Verify NetVM PCI device passthrough
    [Documentation]     Verify that proper PCI devices have been passed through to the NetVM
    [Tags]              SP-T96  orin-agx  orin-agx-64  orin-nx
    [Setup]             Switch to vm   ${NET_VM}
    Verify microvm PCI device passthrough    vmname=${NET_VM}

Check net-vm hostname
    [Documentation]    Compare actual net-vm hostname with expected one from the config file,
    ...                It should never change.
    [Tags]             SP-352  SP-352-1  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  lab-only
    Switch to vm       ${NET_VM}
    Log                Comparing actual net-vm hostname ${NETVM_NAME} and expected ${STATIC_NETVM_NAME}     console=True
    Should Be Equal As Strings   ${NETVM_NAME}    ${STATIC_NETVM_NAME}    ignore_case=True
    ...                          msg=Actual NetVM hostname != Expected
    [Teardown]         Run Keyword If Test Failed    Check net-vm hostname failure

Verify native ethernet is present and in the same network as USB ethernet
    [Documentation]    Verify that native ethernet exists, both interfaces have IPs,
    ...                and belong to the same /24 subnet.
    [Tags]             SP-T62  SP-T62-2  darter-pro  lab-only
    ${usb_eth}         Get Interface name   usb-eth
    ${usb_ip}          Get VM IP            ${usb_eth}
    ${native_eth}      Get Interface name   native-eth
    ${native_ip}       Get VM IP            ${native_eth}
    Interfaces Should Be In Same Network    ${usb_ip}    ${native_ip}

*** Keywords ***

Interfaces Should Be In Same Network
    [Documentation]    Verify that two interfaces are in the same /24 subnet.
    [Arguments]        ${ip1}    ${ip2}
    ${ip1_net}         Evaluate    ".".join("${ip1}".split(".")[:3])
    ${ip2_net}         Evaluate    ".".join("${ip2}".split(".")[:3])
    Should Be Equal    ${ip1_net}    ${ip2_net}

Check net-vm hostname failure
    IF    "system76-darp11-b-storeDisk-debug-installer" in "${JOB}"
        &{ids}    Create Dictionary
        ...    DarterPRO-prod=ghaf-3225688438
        ...    DarterPRO-rel=ghaf-2302431837
        ...    DarterPRO-dev=ghaf-3875859939
        ${expected_wrong_name}    Get From Dictionary    ${ids}    ${SWITCH_BOT}
        IF    "${NETVM_NAME}" == "${expected_wrong_name}"
            SKIP   Known issue: SSRCSP-7997
        ELSE
            FAIL   Actual net-vm hostname: ${NETVM_NAME}, Should be: ${STATIC_NETVM_NAME}, Expected to fail with ${expected_wrong_name}
        END
    END
