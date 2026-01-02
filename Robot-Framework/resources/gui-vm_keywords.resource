# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
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
    ${brightness}     Execute Command    ${output}/bin/brightnessctl get
    IF  ${log_brightness}    Log To Console    Brightness is ${brightness}
    # For debugging, save some logs
    ${output}   Execute Command   journalctl -u systemd-backlight*
    Log   ${output}
    RETURN            ${brightness}
    [Teardown]   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Set brightness
    [Documentation]   Set brightness to ${brightness_to_set}
    [Arguments]       ${brightness_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    Log               Settings brightness to ${brightness_to_set}   console=True
    ${path}           Search nix store   brightnessctl
    ${output}  ${rc}     Execute Command    ${path}/bin/brightnessctl s ${brightness_to_set}  sudo=True  sudo_password=${PASSWORD}  return_rc=True
    Should Be Equal As Integers   ${rc}   0
    ${brightness}     Get screen brightness
    [Teardown]   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Get timezone
    [Documentation]   Get and return current timezone
    [Setup]       Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}  ${err}  ${rc}   Execute Command    file /etc/localtime   return_stderr=True  return_rc=True
    Log    ${output}
    Should Be Equal As Integers   ${rc}   0   ${err}
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
    Switch to vm    ${GUI_VM}
    ${output}  ${err}  ${rc}   Execute Command   givc-cli set-timezone ${timezone_to_set}  return_stderr=True  return_rc=True  sudo=True  sudo_password=${PASSWORD}
    Log    ${output}, ${err}
    Should Be Equal As Integers   ${rc}   0   ${err}
    Sleep   3
    ${timezone}       Get timezone
    Log               Timezone is ${timezone}  console=True
    Should Be Equal   ${timezone_to_set}    ${timezone}

Get volume level
    [Documentation]   Get and return current volume value
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${pamixer}        Search nix store   pamixer
    ${volume}  ${err}  ${rc}    Execute Command    ${pamixer}/bin/pamixer --get-volume  return_stderr=True  return_rc=True
    Should Be Equal As Integers   ${rc}   0   ${err}
    RETURN            ${volume}

Get mute status
    [Documentation]   Get and return current mute status
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${pamixer}        Search nix store   pamixer
    ${mute}           Execute Command    ${pamixer}/bin/pamixer --get-mute
    RETURN            ${mute}

Set volume
    [Documentation]   Set volume to ${volume_to_set}
    [Arguments]       ${volume_to_set}
    [Setup]           Switch to vm    ${GUI_VM}
    ${path}           Search nix store   pamixer
    ${output}  ${err}  ${rc}    Execute Command    ${path}/bin/pamixer --set-volume ${volume_to_set}  return_stderr=True  return_rc=True  sudo=True  sudo_password=${PASSWORD}
    Should Be Equal As Integers  ${rc}   0   ${err}
    ${volume}  ${err}  ${rc}    Execute Command    ${path}/bin/pamixer --get-volume  return_stderr=True  return_rc=True
    Should Be Equal As Integers  ${rc}   0   ${err}
    Log                Volume is ${volume}   console=True
    Should Be Equal   ${volume_to_set}    ${volume}

Check the screen state
    [Documentation]     Check screen state on/off
    [Arguments]         ${state}
    [Setup]             Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ${output}           Search nix store   wlopm
    ${output}  ${err}   Execute Command    WAYLAND_DISPLAY=wayland-1 ${output}/bin/wlopm    return_stderr=True
    Log                 Screen state: ${output}  console=True
    Should Contain      ${output}    ${state}