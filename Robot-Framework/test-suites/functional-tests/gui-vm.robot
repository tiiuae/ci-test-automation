# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Gui-vm
Force Tags          gui-vm   regression

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to netvm
Test Setup          Gui-vm Test Setup
Test Teardown       Gui-vm Test Teardown


*** Variables ***
@{APP_PIDS}         ${EMPTY}


*** Test Cases ***

Start Calculator on LenovoX1
    [Documentation]   Start Calculator and verify process started
    [Tags]            bat   pre-merge  calculator  SP-T202  lenovo-x1  dell-7330  fmo
    Start XDG application  Calculator  gui_vm_app=true
    Check that the application was started    calculator

Start Sticky Notes on LenovoX1
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            bat   pre-merge  sticky_notes  SP-T201-1  lenovo-x1  dell-7330  fmo
    Start XDG application  'Sticky Notes'  gui_vm_app=true
    Check that the application was started    sticky-wrapped

Start Ghaf Control Panel on LenovoX1
    [Documentation]   Start Ghaf Control Panel and verify process started
    [Tags]            bat   pre-merge  control_panel  SP-T205  lenovo-x1  dell-7330  fmo
    Start XDG application  'Ghaf Control Panel'  gui_vm_app=true
    Check that the application was started    ctrl-panel

Start Bluetooth Settings on LenovoX1
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            bat   pre-merge  bluetooth_settings  SP-T204  lenovo-x1  dell-7330  fmo
    Start XDG application  'Bluetooth Settings'  gui_vm_app=true
    Check that the application was started    blueman-manager-wrapped-wrapped

Start COSMIC Files on LenovoX1
    [Documentation]   Start Cosmic Files and verify process started
    [Tags]            bat   pre-merge  cosmic_files  SP-T206  lenovo-x1  dell-7330  fmo
    Start XDG application  com.system76.CosmicFiles  gui_vm_app=true
    Check that the application was started    cosmic-files %U  exact_match=true

Start COSMIC Settings on LenovoX1
    [Documentation]   Start Cosmic Settings and verify process started
    [Tags]            bat   pre-merge  cosmic_settings  SP-T254  lenovo-x1  dell-7330  fmo
    Start XDG application  com.system76.CosmicSettings  gui_vm_app=true
    Check that the application was started    cosmic-settings  exact_match=true

Start COSMIC Text Editor on LenovoX1
    [Documentation]   Start Cosmic Text Editor and verify process started
    [Tags]            bat   pre-merge  cosmic_editor  SP-T243  lenovo-x1  dell-7330  fmo
    Start XDG application   com.system76.CosmicEdit  gui_vm_app=true
    Check that the application was started    cosmic-edit %F  exact_match=true

Start COSMIC Terminal on LenovoX1
    [Documentation]   Start Cosmic Terminal and verify process started
    [Tags]            bat   cosmic_term  SP-T263  lenovo-x1   dell-7330  fmo
    Launch Cosmic Term

Start Falcon AI on LenovoX1
    [Documentation]   Start Falcon AI and verify process started
    [Tags]            falcon_ai  SP-T223-1  lenovo-x1   dell-7330
    Get Falcon LLM Name
    Start XDG application  'Falcon AI'
    Wait Until Falcon Download Complete
    Check that the application was started    alpaca    range=20

    ${answer}  Ask the question     2+2=? Return just the number.
    Should Be Equal As Integers     ${answer}   4


Check user systemctl status
    [Documentation]   Verify systemctl status --user is running
    [Tags]            bat   SP-T260  lenovo-x1   dell-7330  fmo

    ${known_issues}=    Create List
    # Add any known failing services here with the target device and bug ticket number.
    # ...    device|service-name|ticket-number
    Verify Systemctl status    range=3   user=True

    [Teardown]   Run Keyword If Test Failed   Check systemctl status for known issues  ${known_issues}  ${failed_units}

Start Firefox GPU on FMO
    [Documentation]   Start Firefox GPU and verify process started
    [Tags]            bat   firefox_gpu  fmo
    Start XDG application  'Firefox GPU'  gui_vm_app=true
    Check that the application was started    firefox

Start Google Chrome GPU on FMO
    [Documentation]   Start Google Chrome GPU and verify process started
    [Tags]            bat   chrome_gpu  fmo
    Start XDG application  'Google Chrome GPU'  gui_vm_app=true
    Check that the application was started    chrome

Start Display Settings on FMO
    [Documentation]   Start Display Settings and verify process started
    [Tags]            bat   display_settings  fmo
    Start XDG application  'Display Settings'  gui_vm_app=true
    Check that the application was started    wdisplays

*** Keywords ***

Gui-vm Test Setup
    Switch to vm    gui-vm  user=${USER_LOGIN}

Gui-vm Test Teardown
    Switch to vm    gui-vm
    Kill process        @{APP_PIDS}
    Switch to vm    gui-vm  user=${USER_LOGIN}
    ${app_log}          Execute command    cat output.log
    Log                 ${app_log}

Wait Until Falcon Download Complete
    FOR  ${i}  IN RANGE   100
        ${output}          Execute Command  ollama list
        ${download_done}   Run Keyword And Return Status  Should contain   ${output}  ${LLM_NAME}
        IF  ${download_done}  BREAK
        Sleep  3
    END

Ask the question
    [Arguments]      ${question}
    Log              Asking AI: ${question}  console=True
    Execute Command  script -q -c 'ollama run falcon3:10b "${question}" > result.txt'     return_stderr=True    timeout=60
    ${answer}        Execute Command  cat result.txt
    Log              The answer is: ${answer}  console=True
    RETURN           ${answer}