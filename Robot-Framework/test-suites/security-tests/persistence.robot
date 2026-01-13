# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check persistence
Test Tags           persistence  lenovo-x1  darter-pro  lab-only
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Persistence Suite Setup
Suite Teardown      Persistence Suite Teardown

*** Variables ***
${EXPECTED_BRIGHTNESS}    7758
${EXPECTED_VOLUME}        42
${EXPECTED_TIMEZONE}      Asia/Dubai
${EXPECTED_CAM_STATE}     blocked
${EXPECTED_MIC_STATE}     blocked
${EXPECTED_BT_STATE}      blocked
${EXPECTED_NET_STATE}     blocked


*** Test Cases ***

Verify camera block persisted
    [Tags]    SP-T305  SP-T305-1
    ${cam_state}      Get device state   cam
    Should Be Equal   ${EXPECTED_CAM_STATE}  ${cam_state}

Verify microphone block persisted
    [Tags]    SP-T305  SP-T305-2
    ${mic_state}      Get device state   mic
    Should Be Equal   ${EXPECTED_MIC_STATE}  ${mic_state}

Verify Bluetooth block persisted
    [Tags]    SP-T305  SP-T305-3
    ${bt_state}      Get device state   bluetooth
    Should Be Equal   ${EXPECTED_BT_STATE}  ${bt_state}

Verify Wi-Fi block persisted
    [Tags]    SP-T305  SP-T305-4
    ${net_state}      Get device state   net
    Should Be Equal   ${EXPECTED_NET_STATE}  ${net_state}

Verify brightness persisted
    [Tags]    SP-T326  SP-T326-1
    ${brightness}     Get screen brightness
    Should Be Equal   ${EXPECTED_BRIGHTNESS}  ${brightness}

Verify volume persisted
    [Tags]    SP-T326  SP-T326-2
    [Setup]   Set device state  unblocked  mic  # Unblock audio before checking volume
    ${volume}         Get volume level
    Should Be Equal   ${EXPECTED_VOLUME}  ${volume}

Verify timezone persisted
    [Tags]    SP-T326  SP-T326-3
    ${timezone}       Get timezone
    Should Be Equal   ${EXPECTED_TIMEZONE}  ${timezone}


*** Keywords ***

Persistence Suite Setup
    Switch to vm      ${NET_VM}
    Login to laptop   enable_dnd=True
    Save original values
    Set values        EXPECTED

    Soft Reboot Device   ${GUI_VM}
    Wait Until Device Is Down
    Connect After Reboot
    Login to laptop   enable_dnd=True

Persistence Suite Teardown
    IF  $SUITE_STATUS=='FAIL'
        Reboot Laptop
        Connect After Reboot
        Login to laptop   enable_dnd=True
    END
    Set values   ORIGINAL

Save original values
    ${ORIGINAL_BRIGHTNESS}   Run Keyword And Continue On Failure   Get screen brightness  log_brightness=False
    Set Suite Variable       ${ORIGINAL_BRIGHTNESS}
    ${ORIGINAL_VOLUME}       Run Keyword And Continue On Failure   Get volume level
    Set Suite Variable       ${ORIGINAL_VOLUME}
    ${ORIGINAL_TIMEZONE}     Run Keyword And Continue On Failure   Get timezone
    Set Suite Variable       ${ORIGINAL_TIMEZONE}
    ${ORIGINAL_CAM_STATE}    Run Keyword And Continue On Failure   Get device state   cam
    Set Suite Variable       ${ORIGINAL_CAM_STATE}
    ${ORIGINAL_MIC_STATE}    Run Keyword And Continue On Failure   Get device state   mic
    Set Suite Variable       ${ORIGINAL_MIC_STATE}
    ${ORIGINAL_BT_STATE}     Run Keyword And Continue On Failure   Get device state   bluetooth
    Set Suite Variable       ${ORIGINAL_BT_STATE}
    ${ORIGINAL_NET_STATE}    Run Keyword And Continue On Failure   Get device state   net
    Set Suite Variable       ${ORIGINAL_NET_STATE}

Set values
    [Arguments]    ${type}
    [Setup]    Run Keyword And Continue On Failure   
    ...    Set device state  unblocked  mic  # Mic needs to be unblocked before volume can be set
    Should Be True  '${type}' in ['ORIGINAL', 'EXPECTED']   Wrong type
    Run Keyword And Continue On Failure   Set brightness    ${${type}_BRIGHTNESS}
    Run Keyword And Continue On Failure   Set volume        ${${type}_VOLUME}
    Run Keyword And Continue On Failure   Set timezone      ${${type}_TIMEZONE}
    Run Keyword And Continue On Failure   Set device state  ${${type}_CAM_STATE}  cam
    Run Keyword And Continue On Failure   Set device state  ${${type}_MIC_STATE}  mic
    Run Keyword And Continue On Failure   Set device state  ${${type}_BT_STATE}   bluetooth
    Run Keyword And Continue On Failure   Set device state  ${${type}_NET_STATE}  net