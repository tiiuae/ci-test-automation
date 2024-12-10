# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications on gui-vm
Force Tags          gui-vm-apps  bat  lenovo-x1
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Suite Teardown      Close All Connections
Test Setup         Run Keywords  Connect to netvm  AND  Connect to VM  ${GUI_VM}


*** Variables ***
@{app_pids}         ${EMPTY}


*** Test Cases ***
Start Calculator on LenovoX1
    [Documentation]   Start Calculator and verify process started
    [Tags]            calculator  SP-T202
    Start XDG application  Calculator
    Check that the application was started    calculator
    [Teardown]  Kill process  @{app_pids}

Start Sticky Notes on LenovoX1
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            sticky_notes  SP-T201
    Start XDG application  'Sticky Notes'
    Check that the application was started    sticky-wrapped
    [Teardown]  Kill process  @{app_pids}

Start Control Panel on LenovoX1
    [Documentation]   Start Control Panel and verify process started
    [Tags]            control_panel  SP-T205
    Start XDG application  'Control Panel'
    Check that the application was started    ctrl-panel
    [Teardown]  Kill process  @{app_pids}

Start Bluetooth Settings on LenovoX1
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            bluetooth_settings  SP-T204
    Start XDG application  'Bluetooth Settings'
    Check that the application was started    blueman
    [Teardown]  Kill process  @{app_pids}

Start Audio Control on LenovoX1
    [Documentation]   Start Audio Control and verify process started
    [Tags]            audio_control  SP-T203
    Start XDG application  'Audio Control'
    Check that the application was started    audio-control
    [Teardown]  Kill process  @{app_pids}

Start File Manager on LenovoX1
    [Documentation]   Start File Manager and verify process started
    [Tags]            file_manager  SP-T206
    Start XDG application  'File Manager'
    Check that the application was started    pcmanfm
    [Teardown]  Kill process  @{app_pids}
