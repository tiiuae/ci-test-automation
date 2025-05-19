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
    Start XDG application  Calculator  gui_vm_app=true
    Check that the application was started    calculator

Start Sticky Notes on LenovoX1
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            sticky_notes  SP-T201-1
    IF  $COMPOSITOR == 'cosmic'
        Skip   App not available in Cosmic
    ELSE
        Start XDG application  'Sticky Notes'  gui_vm_app=true
        Check that the application was started    sticky-wrapped
    END
    [Teardown]  Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-6624"

Start Ghaf Control Panel on LenovoX1
    [Documentation]   Start Ghaf Control Panel and verify process started
    [Tags]            control_panel  SP-T205
    Start XDG application  'Ghaf Control Panel'  gui_vm_app=true
    Check that the application was started    ctrl-panel

Start Bluetooth Settings on LenovoX1
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            bluetooth_settings  SP-T204
    Start XDG application  'Bluetooth Settings'  gui_vm_app=true
    Check that the application was started    blueman-manager-wrapped-wrapped

Start COSMIC Files on LenovoX1
    [Documentation]   Start Cosmic Files and verify process started
    [Tags]            cosmic_files  SP-T206
    IF  $COMPOSITOR == 'cosmic'
        Start XDG application  com.system76.CosmicFiles  gui_vm_app=true
        Check that the application was started    cosmic-files %U  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

Start COSMIC Settings on LenovoX1
    [Documentation]   Start Cosmic Settings and verify process started
    [Tags]            cosmic_settings  SP-T254
    IF  $COMPOSITOR == 'cosmic'
        Start XDG application  com.system76.CosmicSettings  gui_vm_app=true
        Check that the application was started    cosmic-settings  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

Start COSMIC Text Editor on LenovoX1
    [Documentation]   Start Cosmic Text Editor and verify process started
    [Tags]            cosmic_editor  SP-T243
    IF  $COMPOSITOR == 'cosmic'
        Start XDG application   com.system76.CosmicEdit  gui_vm_app=true
        Check that the application was started    cosmic-edit %F  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

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
