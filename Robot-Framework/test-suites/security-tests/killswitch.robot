# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Check killswitch functionality

Resource            ../../resources/audio_and_video_keywords.resource
Resource            ../../resources/bluetooth.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/wifi_keywords.resource

Test Tags           killswitch  lenovo-x1  darter-pro


*** Variables ***
${AUDIO_DIR}    ${OUTPUT_DIR}/outputs/audio-temp


*** Test Cases ***
Killswitch disconnects camera
    [Documentation]  Check that camera works, then block it using killswitch and verify that it doesn't work
    [Tags]           SP-T435  bat
    [Setup]           Attach integrated camera   ${BUSINESS_VM}
    Check camera      ${BUSINESS_VM}  expected=True
    Set device state  blocked         cam
    Check camera      ${BUSINESS_VM}  expected=False
    [Teardown]        Run Keywords    Set device state    unblocked    cam    AND    Detach integrated camera

Killswitch disconnects microphone
    [Documentation]  Check that microphone works, then block it using killswitch and verify that it doesn't work
    [Tags]           SP-T436  bat
    Record Audio And Verify   ${BUSINESS_VM}
    Set device state  blocked    mic
    Record Audio And Verify   ${BUSINESS_VM}    expected_duration=0
    [Teardown]       Set device state  unblocked    mic

Killswitch blocks all devices at once
    [Documentation]  Verify that ghaf-killswitch block --all and unblock --all change all device states
    [Tags]           SP-T368  bat  lab-only
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
    Configure wifi                  ${TEST_WIFI_SSID}  ${TEST_WIFI_PSWD}
    Get wifi IP
    [Teardown]       WLAN teardown

Kill switch disconnects Bluetooth
    [Documentation]    Verify that blocking removes the Bluetooth controller and unblocking restores it
    ...                Check that Bluetooth functionality continues working
    [Tags]             SP-T339  lab-only
    [Setup]            Wait Until Keyword Succeeds    180s    5s    Try Acquire Bluetooth Board Lock
    Verify Bluetooth controller availability    ${True}
    ${bt_board_mac}    Discover bluetooth device by name
    Open Bluetooth Board Serial Port
    Connect bluetooth device       ${bt_board_mac}
    Set device state  blocked    bluetooth
    Verify Bluetooth controller availability    ${False}
    Set device state  unblocked    bluetooth
    Verify Bluetooth controller availability    ${True}
    ${bt_board_mac}    Discover bluetooth device by name
    Connect bluetooth device       ${bt_board_mac}
    Disconnect bluetooth device    ${bt_board_mac}
    Remove bluetooth device        ${bt_board_mac}
    [Teardown]         Bluetooth teardown


*** Keywords ***
WLAN setup
    Switch to vm       ${NET_VM}
    ${wifi_if}         Get Interface name    wifi
    Set Test Variable  ${wifi_if}
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

Bluetooth teardown
    Set device state    unblocked    bluetooth
    Switch to vm       ${AUDIO_VM}
    Remove cached bluetooth devices by name
    Close Bluetooth Board Serial Port
    Release Bluetooth Board Lock
