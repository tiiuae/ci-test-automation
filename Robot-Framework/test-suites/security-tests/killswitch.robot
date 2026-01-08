# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check killswitch functionality
Force Tags          killswitch  regression  security  lenovo-x1  darter-pro
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/audio_and_video_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/wifi_keywords.resource

*** Variables ***

${AUDIO_DIR}    ${OUTPUT_DIR}/outputs/audio-temp


*** Test Cases ***

Killswitch disconnects camera
    [Documentation]  Check that camera works, then block it using killswitch and verify that it doesn't work
    [Tags]           SP-T275  SP-T275-1
    Check camera     expected=True
    Set device state  blocked    cam
    Check camera     expected=False
    [Teardown]       Set device state    unblocked    cam

Killswitch disconnects microphone
    [Documentation]  Check that microphone works, then block it using killswitch and verify that it doesn't work
    [Tags]           SP-T275  SP-T275-2
    Record Audio And Verify   ${BUSINESS_VM}
    Set device state  blocked    mic
    Record Audio And Verify   ${BUSINESS_VM}    expected_duration=0
    [Teardown]       Set device state  unblocked    mic

Killswitch disconnects WLAN
    [Documentation]  Verify that killswitch disconnect wi-fi connection and make interface unavailable
    [Tags]           SP-T304  lab-only
    [Setup]          WLAN setup
    Verify nmcli device status    ${wifi_if}  connected
    Check Network Availability    8.8.8.8     expected_result=True    limit_freq=${False}    interface=${wifi_if}
    Set device state   blocked    net
    Switch to vm       ${NET_VM}
    Verify nmcli device status    ${wifi_if}  absent
    Check Network Availability    8.8.8.8     expected_result=False   limit_freq=${False}    interface=${wifi_if}
    Check Network Availability    8.8.8.8     expected_result=True    limit_freq=${False}    interface=${eth_if}
    Set device state   unblocked    net
    Verify nmcli device status    ${wifi_if}  connected  range=30
    [Teardown]       WLAN teardown


*** Keywords ***

WLAN setup
    Switch to vm       ${NET_VM}
    ${wifi_if}         Get Wifi Interface name
    Set Test Variable  ${wifi_if}
    ${eth_if}          Get Ethernet Interface name
    Set Test Variable  ${eth_if}
    Configure wifi     ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP

WLAN teardown
    Set device state  unblocked  net
    Remove Wifi configuration  ${TEST_WIFI_SSID}
