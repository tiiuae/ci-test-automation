# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check persistence
Force Tags          security   persistence   regression
Library             ../../lib/TimeLibrary.py
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource

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
    ${cam_state}      Get device state    cam
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
    ${ORIGINAL_CAM_STATE}    Run Keyword And Continue On Failure   Get device state   cam
    Set Suite Variable       ${ORIGINAL_CAM_STATE}

Set values
    [Arguments]    ${type}
    Should Be True  '${type}' in ['ORIGINAL', 'EXPECTED']   Wrong type
    Run Keyword And Continue On Failure   Set brightness    ${${type}_BRIGHTNESS}
    Run Keyword And Continue On Failure   Set volume        ${${type}_VOLUME}
    Run Keyword And Continue On Failure   Set timezone      ${${type}_TIMEZONE}
    Run Keyword And Continue On Failure   Set device state  ${${type}_CAM_STATE}  cam
