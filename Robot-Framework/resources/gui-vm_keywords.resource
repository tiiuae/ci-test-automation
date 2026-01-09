# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***

Library             ../lib/output_parser.py
Library             ../lib/TimeLibrary.py
Resource            ../resources/common_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Keywords ***

Get screen brightness
    [Documentation]   Get and return current brightness value
    [Arguments]       ${log_brightness}=True
    [Setup]   Switch to vm    ${GUI_VM}
    ${output}         Search nix store   brightnessctl
    ${brightness}     Run Command    ${output}/bin/brightnessctl get
    IF  ${log_brightness}    Log To Console    Brightness is ${brightness}
    # For debugging, save some logs
    Run Command       journalctl -u systemd-backlight*   rc_match=skip
    RETURN            ${brightness}
    [Teardown]   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Set brightness
    [Documentation]   Set brightness to ${brightness_to_set}
    [Arguments]       ${brightness_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    Log               Settings brightness to ${brightness_to_set}   console=True
    ${path}           Search nix store   brightnessctl
    Run Command       ${path}/bin/brightnessctl s ${brightness_to_set}  sudo=True
    ${brightness}     Get screen brightness
    [Teardown]   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Get timezone
    [Documentation]   Get and return current timezone
    [Setup]       Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}  Run Command    file /etc/localtime
    ${timezone}   Extract timezone   ${output}
    IF    '${timezone}' == 'None'
        # If timezone has not yet been set it is UTC by default
        RETURN   UTC
    ELSE
        RETURN   ${timezone}
    END

Set timezone
    [Documentation]   Set timezone to ${timezone_to_set}
    [Arguments]       ${timezone_to_set}
    ${timezone}       Get timezone
    IF   '${timezone_to_set}' == '${timezone}'   RETURN
    Switch to vm      ${GUI_VM}
    Run Command       givc-cli set-timezone ${timezone_to_set}  sudo=True
    Sleep   3
    ${timezone}       Get timezone
    Log               Timezone is ${timezone}  console=True
    Should Be Equal   ${timezone_to_set}    ${timezone}

Get volume level
    [Documentation]   Get and return current volume value
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${pamixer}        Search nix store   pamixer
    ${volume}         Run Command    ${pamixer}/bin/pamixer --get-volume
    RETURN            ${volume}

Get mute status
    [Documentation]   Get and return current mute status
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${pamixer}        Search nix store   pamixer
    ${mute}           Run Command    ${pamixer}/bin/pamixer --get-mute
    RETURN            ${mute}

Set volume
    [Documentation]   Set volume to ${volume_to_set}
    [Arguments]       ${volume_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    ${path}           Search nix store   pamixer
    Run Command       ${path}/bin/pamixer --set-volume ${volume_to_set}  sudo=True
    ${volume}         Run Command    ${path}/bin/pamixer --get-volume
    Log               Volume is ${volume}   console=True
    Should Be Equal   ${volume_to_set}    ${volume}

Check the screen state
    [Documentation]     Check screen state on/off
    [Arguments]         ${state}
    [Setup]             Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}           Search nix store   wlopm
    ${output}           Run Command    WAYLAND_DISPLAY=wayland-1 ${output}/bin/wlopm
    Log                 Screen state: ${output}  console=True
    Should Contain      ${output}    ${state}