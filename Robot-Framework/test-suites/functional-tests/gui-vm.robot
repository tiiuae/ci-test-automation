# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Gui-vm
Force Tags          gui-vm   regression   lenovo-x1   dell-7330
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Test Setup          Gui-vm Test Setup
Test Teardown       Gui-vm Test Teardown


*** Variables ***
@{APP_PIDS}         ${EMPTY}


*** Test Cases ***
Start Calculator on LenovoX1
    [Documentation]   Start Calculator and verify process started
    [Tags]            bat   calculator  SP-T202
    Start XDG application  Calculator  gui_vm_app=true
    Check that the application was started    calculator

Start Sticky Notes on LenovoX1
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            bat   sticky_notes  SP-T201-1
    IF  $COMPOSITOR == 'cosmic'
        Skip   App not available in Cosmic
    ELSE
        Start XDG application  'Sticky Notes'  gui_vm_app=true
        Check that the application was started    sticky-wrapped
    END

Start Ghaf Control Panel on LenovoX1
    [Documentation]   Start Ghaf Control Panel and verify process started
    [Tags]            bat   control_panel  SP-T205
    Start XDG application  'Ghaf Control Panel'  gui_vm_app=true
    Check that the application was started    ctrl-panel

Start Bluetooth Settings on LenovoX1
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            bat   bluetooth_settings  SP-T204
    Start XDG application  'Bluetooth Settings'  gui_vm_app=true
    Check that the application was started    blueman-manager-wrapped-wrapped

Start COSMIC Files on LenovoX1
    [Documentation]   Start Cosmic Files and verify process started
    [Tags]            bat   cosmic_files  SP-T206
    IF  $COMPOSITOR == 'cosmic'
        Start XDG application  com.system76.CosmicFiles  gui_vm_app=true
        Check that the application was started    cosmic-files %U  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

Start COSMIC Settings on LenovoX1
    [Documentation]   Start Cosmic Settings and verify process started
    [Tags]            bat   cosmic_settings  SP-T254
    IF  $COMPOSITOR == 'cosmic'
        Start XDG application  com.system76.CosmicSettings  gui_vm_app=true
        Check that the application was started    cosmic-settings  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

Start COSMIC Text Editor on LenovoX1
    [Documentation]   Start Cosmic Text Editor and verify process started
    [Tags]            bat   cosmic_editor  SP-T243
    IF  $COMPOSITOR == 'cosmic'
        Start XDG application   com.system76.CosmicEdit  gui_vm_app=true
        Check that the application was started    cosmic-edit %F  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

Start Falcon AI on LenovoX1
    [Documentation]   Start Falcon AI and verify process started
    [Tags]            falcon_ai  SP-T223-1
    IF  $COMPOSITOR == 'cosmic'
        Get Falcon LLM Name
        Start XDG application  'Falcon AI'
        Wait Until Falcon Download Complete (Cosmic)
        Check that the application was started    alpaca    range=20
    ELSE
        Get mako path
        Start XDG application  'Falcon AI'
        Wait Until Download Is 100 Percent
        Wait Until Download Complete
        Check that the application was started    alpaca    range=20
    END

Check user systemctl status
    [Documentation]   Verify systemctl status --user is running
    [Tags]            bat   SP-T260
    Verify Systemctl status    range=3   user=True

*** Keywords ***

Gui-vm Test Setup
    Connect to netvm
    Connect to VM       ${GUI_VM}  ${USER_LOGIN}  ${USER_PASSWORD}

Gui-vm Test Teardown
    Connect to VM       ${GUI_VM}
    Kill process        @{APP_PIDS}
    Connect to VM       ${GUI_VM}  ${USER_LOGIN}  ${USER_PASSWORD}
    ${app_log}          Execute command    cat output.log
    Log                 ${app_log}
    Close All Connections

Check If Download Reached 100
    ${notifications}  Execute Command  /nix/store/${MAKO_PATH}/bin/makoctl list
    ${notifications}  Parse notifications    ${notifications}

    ${count}=    Get Length    ${notifications}
    Should Be True    ${count} > 0    No notifications received at all

    FOR    ${key}     ${value}    IN    &{notifications}
        ${status}     Run Keyword And Return Status    Should Contain    ${value}    Downloading Falcon 3
        IF    ${status}
            ${percentage}    Get Percentage    ${value}
            Log to console   Current percentage: ${percentage}%
            Should Be Equal As Integers    ${percentage}    100
            BREAK
        END
    END

Get Percentage
    [Arguments]       ${text}
    ${match_status}   ${match_msg}    Run Keyword And Ignore Error    Should Match Regexp    ${text}    .*?(\\d+)%.*?
    IF  '${match_status}' == 'PASS'
        ${percent}    Set Variable    ${match_msg}[1]
        Log           Current percentage: ${percent}%
    END
    Should Not Be Empty  ${percent}   Could not find percent in text: ${text}
    RETURN            ${percent}

Wait Until Download Is 100 Percent
    Wait Until Keyword Succeeds    420s    5s    Check If Download Reached 100

Check If Download Completed
    ${notifications}  Execute Command  /nix/store/${MAKO_PATH}/bin/makoctl history
    ${notifications}  Parse notifications    ${notifications}

    ${completed}      Set Variable  ${False}
    FOR    ${key}     ${value}    IN    &{notifications}
        ${status}     Run Keyword And Return Status    Should Contain    ${value}    Download complete
        IF    ${status}
            Log to console    Falcon download completed
            ${completed}      Set Variable    ${True}
            BREAK
        END
    END

    IF  not ${completed}
        Fail    No notifications contained 'Download complete'
    END

Wait Until Download Complete
    Wait Until Keyword Succeeds    30s    3s     Check If Download Completed

Wait Until Falcon Download Complete (Cosmic)
    FOR  ${i}  IN RANGE   100
        ${output}          Execute Command  ollama list
        ${download_done}   Run Keyword And Return Status  Should contain   ${output}  ${LLM_NAME}
        IF  ${download_done}  BREAK
        Sleep  3
    END
