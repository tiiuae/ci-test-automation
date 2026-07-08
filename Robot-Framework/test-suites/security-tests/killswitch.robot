# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check killswitch functionality
Test Tags           killswitch  lenovo-x1  darter-pro
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
    [Tags]           SP-T275  SP-T275-1  bat
    Check camera     expected=True
    Set device state  blocked    cam
    Check camera     expected=False
    [Teardown]       Set device state    unblocked    cam

Killswitch disconnects microphone
    [Documentation]  Check that microphone works, then block it using killswitch and verify that it doesn't work
    [Tags]           SP-T275  SP-T275-2  bat
    Record Audio And Verify   ${BUSINESS_VM}
    Set device state  blocked    mic
    Record Audio And Verify   ${BUSINESS_VM}    expected_duration=0
    [Teardown]       Set device state  unblocked    mic

Killswitch blocks all devices at once
    [Documentation]  Verify that ghaf-killswitch block --all and unblock --all change all device states
    [Tags]           SP-T368    bat
    Set all devices state      blocked
    Verify all devices state   blocked
    Set all devices state      unblocked
    Verify all devices state   unblocked
    [Teardown]       Set all devices state   unblocked

Killswitch disconnects WLAN
    [Documentation]  Verify that killswitch disconnects wi-fi connection and makes interface unavailable
    [Tags]           SP-T304  lab-only
    [Setup]          WLAN setup
    Verify nmcli device status    ${wifi_if}  connected
    ${gateway}     Get gateway    wifi
    Check Network Availability    ${gateway}     expected_result=True    limit_freq=${False}    interface=${wifi_if}
    Set device state   blocked    net
    Switch to vm       ${NET_VM}
    Verify nmcli device status    ${wifi_if}  absent
    Check Network Availability    ${gateway}     expected_result=False   limit_freq=${False}
    Check Network Availability    8.8.8.8        expected_result=True    limit_freq=${False}    interface=eth
    Set device state   unblocked    net
    Remove Wifi configuration       ${TEST_WIFI_SSID}
    Wait Until Keyword Succeeds     10x   1s   Scan for Wifi   ${TEST_WIFI_SSID}
    Configure wifi                  ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP
    [Teardown]       WLAN teardown


*** Keywords ***

WLAN setup
    Switch to vm       ${NET_VM}
    ${wifi_if}         Get Interface name    wifi
    Set Test Variable  ${wifi_if}
    Wait Until Keyword Succeeds     30x   2s   Scan for Wifi   ${TEST_WIFI_SSID}
    Configure wifi     ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP

WLAN teardown
    IF  $TEST_STATUS!='PASS'
        Switch to vm       ${NET_VM}
        Run Command        nmcli device
        Run Command        nmcli dev wifi list
    END
    Set device state  unblocked  net
    Remove Wifi configuration  ${TEST_WIFI_SSID}
