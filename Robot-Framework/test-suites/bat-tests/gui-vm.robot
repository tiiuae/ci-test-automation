# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications on gui-vm
Force Tags          gui-vm-apps  bat  lenovo-x1   dell-7330
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Test Setup          Gui-vm Apps Test Setup
Test Teardown       Gui-vm Apps Test Teardown


*** Variables ***
@{APP_PIDS}         ${EMPTY}


*** Test Cases ***
Start Calculator on LenovoX1
    [Documentation]   Start Calculator and verify process started
    [Tags]            calculator  SP-T202
    Start XDG application  Calculator
    Check that the application was started    calculator

Start Sticky Notes on LenovoX1
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            sticky_notes  SP-T201-1
    Start XDG application  'Sticky Notes'
    Check that the application was started    sticky-wrapped

Start Control Panel on LenovoX1
    [Documentation]   Start Control Panel and verify process started
    [Tags]            control_panel  SP-T205
    Start XDG application  'Control Panel'
    Check that the application was started    ctrl-panel

Start Bluetooth Settings on LenovoX1
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            bluetooth_settings  SP-T204
    Start XDG application  'Bluetooth Settings'
    Check that the application was started    blueman-manager

Start File Manager on LenovoX1
    [Documentation]   Start File Manager and verify process started
    [Tags]            file_manager  SP-T206
    Start XDG application  'File Manager'
    Check that the application was started    pcmanfm

Start Falcon AI on LenovoX1
    [Documentation]   Start Falcon AI and verify process started
    [Tags]            falcon_ai  SP-T223-1
    Start XDG application  'Falcon AI'
    Check that the application was started    alpaca-wrapped

*** Keywords ***

Gui-vm Apps Test Setup
    Connect to netvm
    Connect to VM  ${GUI_VM}  ${USER_LOGIN}  ${USER_PASSWORD}

Gui-vm Apps Test Teardown
    Connect to VM       ${GUI_VM}
    Kill process        @{APP_PIDS}
    Connect to VM       ${GUI_VM}  ${USER_LOGIN}  ${USER_PASSWORD}
    ${app_log}          Execute command    cat output.log
    Log                 ${app_log}
    Close All Connections
