# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check persistence
Force Tags          security   persistence   regression
Library             ../../lib/output_parser.py
Library             ../../lib/TimeLibrary.py
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Persistence Suite Setup
Suite Teardown      Persistence Suite Teardown
Test Setup          Persistence Test Setup


*** Variables ***
${EXPECTED_BRIGHTNESS}    16290
${EXPECTED_VOLUME}        42
${EXPECTED_TIMEZONE}      UTC
${EXPECTED_CAM_STATE}     blocked

*** Test Cases ***

Verify brightness persisted
    [Tags]    # SP-T326-1   lenovo-x1
    ${brightness}     Get screen brightness
    Should Be Equal   ${EXPECTED_BRIGHTNESS}  ${brightness}

Verify volume persisted
    [Tags]    SP-T326-2   lenovo-x1   darter-pro
    ${volume}         Get volume level
    Should Be Equal   ${EXPECTED_VOLUME}  ${volume}

Verify timezone persisted
    [Tags]    # SP-T326-3   lenovo-x1   darter-pro
    ${timezone}       Get timezone
    Should Be Equal   ${EXPECTED_TIMEZONE}  ${timezone}

Verify camera block persisted
    [Tags]    SP-T305   lenovo-x1   darter-pro
    ${cam_state}      Get cam state
    Should Be Equal   ${EXPECTED_CAM_STATE}  ${cam_state}


*** Keywords ***

Persistence Suite Setup
    Switch to vm      ${NET_VM}
    Login to laptop   enable_dnd=True
    Save original values
    Set values        EXPECTED

    Soft Reboot Device
    Verify Reboot and Connect
    Login to laptop   enable_dnd=True

Persistence Suite Teardown
    Set values   ORIGINAL

Persistence Test Setup
    Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Save original values
    ${ORIGINAL_BRIGHTNESS}   Run Keyword And Continue On Failure   Get screen brightness
    Set Suite Variable       ${ORIGINAL_BRIGHTNESS}
    ${ORIGINAL_VOLUME}       Run Keyword And Continue On Failure   Get volume level
    Set Suite Variable       ${ORIGINAL_VOLUME}
    ${ORIGINAL_TIMEZONE}     Run Keyword And Continue On Failure   Get timezone
    Set Suite Variable       ${ORIGINAL_TIMEZONE}
    ${ORIGINAL_CAM_STATE}    Run Keyword And Continue On Failure   Get cam state
    Set Suite Variable       ${ORIGINAL_CAM_STATE}

Set values
    [Arguments]    ${type}
    Should Be True  '${type}' in ['ORIGINAL', 'EXPECTED']   Wrong type
    Run Keyword And Continue On Failure   Set brightness    ${${type}_BRIGHTNESS}
    Run Keyword And Continue On Failure   Set volume        ${${type}_VOLUME}
    Run Keyword And Continue On Failure   Set timezone      ${${type}_TIMEZONE}
    Run Keyword And Continue On Failure   Set cam state     ${${type}_CAM_STATE}

Set cam state
    [Documentation]   Change camera state to ${expected_state}
    [Arguments]       ${expected_state}
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    Should Be True   '${expected_state}' in ['blocked', 'unblocked']   Wrong state
    ${cam_state}      Get cam state
    ${status}         Run Keyword And Return Status   Should Be Equal   ${cam_state}   ${expected_state}
    IF    ${status}
        Log To Console   Camera state is already ${expected_state}
    ELSE
        IF   '${expected_state}' == 'blocked'
            ${state_to_set}   Set Variable   block
        ELSE
            ${state_to_set}   Set Variable   unblock
        END
        ${output}        Execute Command   ghaf-killswitch ${state_to_set} cam
        Log  ${output}
        ${cam_state}      Get cam state
        Should Be Equal   ${cam_state}   ${expected_state}
    END

Get cam state
    [Setup]         Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}       Execute Command   ghaf-killswitch status
    ${state}        Get kill switch status   ${output}   cam
    RETURN          ${state}
