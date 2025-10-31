# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check persistence
Force Tags          security   persistence   regression
Library             ../../lib/output_parser.py
Library             ../../lib/TimeLibrary.py
Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Persistence Suite Setup
Suite Teardown      Persistence Suite Teardown
Test Setup          Persistence Test Setup


*** Variables ***
${EXPECTED_BRIGHTNESS}    16290
${EXPECTED_VOLUME}        42
${EXPECTED_TIMEZONE}      UTC
${EXPECTED_CAM_STATE}     block

*** Test Cases ***

Verify brightness persisted
    [Tags]    SP-T326-1   lenovo-x1
    ${brightness}     Get screen brightness
    Should Be Equal   ${EXPECTED_BRIGHTNESS}  ${brightness}

Verify volume persisted
    [Tags]    SP-T326-2   lenovo-x1   darter-pro
    ${volume}         Get volume level
    Should Be Equal   ${EXPECTED_VOLUME}  ${volume}

Verify timezone persisted
    [Tags]    SP-T326-3   lenovo-x1   darter-pro
    ${timezone}       Get timezone
    Should Be Equal   ${EXPECTED_TIMEZONE}  ${timezone}

Verify camera block persisted
    [Tags]    SP-T326-4   lenovo-x1   darter-pro
    ${cam_state}      Get cam state
    Should Be Equal   ${EXPECTED_CAM_STATE}  ${cam_state}


*** Keywords ***

Persistence Suite Setup
    Connect to vm     ${NET_VM}
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
    Run Keyword And Continue On Failure   Set volume        ${${type}_VOLUME_}
    Run Keyword And Continue On Failure   Set timezone      ${${type}_TIMEZONE_}
    Run Keyword And Continue On Failure   Set cam state     ${${type}_CAM_STATE_}

Set brightness
    [Documentation]   Set brightness to ${brightness_to_set}
    [Arguments]       ${brightness_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    ${path}           Execute Command    ls /nix/store | grep brightnessctl | grep -v .drv
    ${output}         Execute Command    /nix/store/${path}/bin/brightnessctl s ${brightness_to_set}  sudo=True  sudo_password=${PASSWORD}
    ${brightness}     Execute Command    /nix/store/${path}/bin/brightnessctl get
    Log To Console    Brightness is ${brightness}
    Should Be Equal   ${brightness_to_set}    ${brightness}

Set volume
    [Documentation]   Set volume to ${volume_to_set}
    [Arguments]       ${volume_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    ${path}           Execute Command    ls /nix/store/ | grep pamixer | grep -v .drv
    ${output}         Execute Command    /nix/store/${path}/bin/pamixer --set-volume ${volume_to_set}  sudo=True  sudo_password=${PASSWORD}
    ${volume}         Execute Command    /nix/store/${path}/bin/pamixer --get-volume
    Log To Console    Volume is ${volume}
    Should Be Equal   ${volume_to_set}    ${volume}

Set timezone
    [Documentation]   Set volume to ${timezone_to_set}
    [Arguments]       ${timezone_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    Execute Command   timedatectl set-timezone ${timezone_to_set}  sudo=True  sudo_password=${PASSWORD}
    ${timezone}       Get timezone
    Log To Console    Timezone is ${timezone_to_set}
    Should Be Equal   ${timezone_to_set}    ${timezone}

Set cam state
    [Documentation]   Change camera state to ${cam_state_to_set}
    [Arguments]       ${cam_state_to_set}
    [Setup]           Switch to vm    ${HOST}
    Should Be True  '${cam_state_to_set}' in ['block', 'unblock']   Wrong state
     ${cam_state}   Get cam state   
    ${status}       Run Keyword And Return Status   Should Be Equal   ${cam_state}   ${cam_state_to_set}
    IF    ${status}
        Log To Console   Camera state is already ${cam_state_to_set}
    ELSE
        ${output}        Execute Command   ghaf-killswitch ${cam_state_to_set} cam   sudo=True  sudo_password=${PASSWORD}
        Log  ${output}
        Should Contain   ${output}   ${cam_state_to_set}ing device   ignore_case=True
        Log To Console   Camera ${cam_state_to_set}ed
    END
    ${cam_state}   Get cam state
    ${status}      Should Be Equal   ${cam_state}   ${cam_state_to_set}

Get timezone
    [Setup]       Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}     Execute Command    timedatectl -a
    Log           ${output}
    ${timezone}   Extract timezone   ${output}
    RETURN        ${timezone}

Get cam state
    [Setup]         Switch to vm    ${HOST}
    ${output}       Execute Command   lsusb
    ${camera_id}    Get Camera Id     ${output}
    ${output}       Execute Command   cat /var/lib/vhotplug/vhotplug.state   sudo=True  sudo_password=${PASSWORD}
    ${status}       Run Keyword And Return Status   Should Not Contain   ${output}   ${camera_id}
    IF    ${status}
        RETURN   unblock
    ELSE
        RETURN   block
    END
