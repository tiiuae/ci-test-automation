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
Test Teardown       Run Keyword If Test Failed   Log persistence setup errors

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
    ${PERSISTENCE_SETUP_ERRORS}    Create List
    Set Suite Variable             ${PERSISTENCE_SETUP_ERRORS}
    Switch to vm      ${NET_VM}
    Login to laptop   enable_dnd=True
    Save original values
    Set values        EXPECTED
    Soft Reboot Device And Connect   vm=${GUI_VM}
    Login to laptop   enable_dnd=True

Persistence Suite Teardown
    IF  $SUITE_STATUS=='FAIL'
        Reboot Laptop
        Connect After Reboot
        Login to laptop   enable_dnd=True
    END
    Set values   ORIGINAL

Save original values
    Save original value    ORIGINAL_BRIGHTNESS   Get screen brightness  False
    Save original value    ORIGINAL_VOLUME       Get volume level
    Save original value    ORIGINAL_TIMEZONE     Get timezone
    Save original value    ORIGINAL_CAM_STATE    Get device state   cam
    Save original value    ORIGINAL_MIC_STATE    Get device state   mic
    Save original value    ORIGINAL_BT_STATE     Get device state   bluetooth
    Save original value    ORIGINAL_NET_STATE    Get device state   net

Save original value
    [Arguments]    ${variable}    ${keyword}    @{args}
    ${status}    ${value}=    Run Keyword And Ignore Error    ${keyword}    @{args}
    IF    '${status}' == 'PASS'
        Set Suite Variable    ${${variable}}    ${value}
    ELSE
        Set Suite Variable    ${${variable}}    ${EMPTY}
        Append To List    ${PERSISTENCE_SETUP_ERRORS}    Failed to get ${variable}: ${value}
    END

Set values
    [Arguments]    ${type}
    [Setup]   Set value and record error    Set device state   unblocked    mic  # Mic needs to be unblocked before volume can be set
    Should Be True  '${type}' in ['ORIGINAL', 'EXPECTED']   Wrong type
    Set value and record error    Set brightness     ${${type}_BRIGHTNESS}
    Set value and record error    Set volume         ${${type}_VOLUME}
    Set value and record error    Set timezone       ${${type}_TIMEZONE}
    Set value and record error    Set device state   ${${type}_CAM_STATE}   cam
    Set value and record error    Set device state   ${${type}_MIC_STATE}   mic
    Set value and record error    Set device state   ${${type}_BT_STATE}    bluetooth
    Set value and record error    Set device state   ${${type}_NET_STATE}   net

Set value and record error
    [Arguments]    ${keyword}    @{args}
    ${status}    ${message}    Run Keyword And Ignore Error    ${keyword}    @{args}
    IF    '${status}' == 'FAIL'
        ${args_text}    Catenate    SEPARATOR=,    @{args}
        Append To List    ${PERSISTENCE_SETUP_ERRORS}    Failed to run ${keyword} (${args_text}): ${message}
    END

Log persistence setup errors
    ${error_count}    Get Length    ${PERSISTENCE_SETUP_ERRORS}
    IF    ${error_count} > 0
        ${error_message}    Catenate    SEPARATOR=\n    @{PERSISTENCE_SETUP_ERRORS}
        FAIL    Persistence suite setup had ${error_count} issue(s):\n${error_message}
    END
