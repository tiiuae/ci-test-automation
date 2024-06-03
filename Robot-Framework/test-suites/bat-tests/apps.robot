# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Teardown      Close All Connections


*** Variables ***
@{app_pids}         ${EMPTY}


*** Test Cases ***

Start Firefox
    [Documentation]   Start Firefox and verify process started
    [Tags]            bat   SP-T45  nuc  orin-agx
    [Setup]           Skip If   "${JOB}" == "nvidia-jetson-orin-agx-debug-nodemoapps-from-x86_64.x86_64-linux"
    ...               Skipped because this build doesn't contain applications
    Connect
    Start Firefox
    Check that the application was started    firefox
    [Teardown]  Kill process  @{app_pids}

Start Chromium on LenovoX1
    [Documentation]   Start Chromium in dedicated VM and verify process started
    [Tags]            bat   SP-T97   lenovo-x1
    Verify service status  range=15  service=microvm@chromium-vm.service  expected_status=active  expected_state=running
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   Chromium
    Connect to VM       ${CHROMIUM_VM}
    Check that the application was started    chromium
    [Teardown]  Kill process  @{app_pids}

Start Zathura on LenovoX1
    [Documentation]   Start Zathura in dedicated VM and verify process started
    [Tags]            bat   SP-T112   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   'PDF Viewer'
    Connect to VM       ${ZATHURA_VM}
    Check that the application was started    zathura
    [Teardown]  Kill process  @{app_pids}

Start Gala on LenovoX1
    [Documentation]   Start Gala in dedicated VM and verify process started
    [Tags]            bat   SP-T111   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   GALA
    Connect to VM       ${GALA_VM}
    Check that the application was started    gala
    [Teardown]  Kill process  @{app_pids}

Start Element on LenovoX1
    [Documentation]   Start Element in dedicated VM and verify process started
    [Tags]            bat   SP-T57   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}
    Start XDG application  Element
    Connect to VM          ${ELEMENT_VM}
    Check that the application was started    element
    [Teardown]  Kill process  @{app_pids}

Start Appflowy on LenovoX1
    [Documentation]   Start Appflowy in dedicated VM and verify process started
    [Tags]            bat   appflowy   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}
    Start XDG application  AppFlowy
    Connect to VM          ${APPFLOWY_VM}
    Check that the application was started    appflowy
    [Teardown]  Kill process  @{app_pids}


*** Keywords ***

Check that the application was started
    [Arguments]          ${app_name}  ${range}=2
    FOR   ${i}   IN RANGE  ${range}
        @{found_pids}        Find pid by name    ${app_name}
        Set Global Variable  @{app_pids}  @{found_pids}
        ${status}    Run Keyword And Return Status   Should Not Be Empty  ${app_pids}
        IF    ${status}    BREAK
        Sleep   1
    END
    Should Not Be Empty  ${app_pids}  ${app_name} is not started
    Log To Console       ${app_name} is started
