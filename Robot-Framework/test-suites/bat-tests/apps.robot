# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
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
    Check if ssh is ready on vm    ${CHROMIUM_VM}
    Start XDG application   Chromium
    Connect to VM       ${CHROMIUM_VM}
    Check that the application was started    chromium
    [Teardown]  Kill process  @{app_pids}

Start Zathura on LenovoX1
    [Documentation]   Start Zathura in dedicated VM and verify process started
    [Tags]            bat   SP-T112   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM       ${GUI_VM}
    Check if ssh is ready on vm    ${ZATHURA_VM}
    Start XDG application   'PDF Viewer'
    Connect to VM       ${ZATHURA_VM}
    Check that the application was started    zathura
    [Teardown]  Kill process  @{app_pids}

Start Gala on LenovoX1
    [Documentation]   Start Gala in dedicated VM and verify process started
    [Tags]            bat   SP-T111   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM       ${GUI_VM}
    Check if ssh is ready on vm    ${GALA_VM}
    Start XDG application   GALA
    Connect to VM       ${GALA_VM}
    Check that the application was started    gala
    [Teardown]  Kill process  @{app_pids}

Start Element on LenovoX1
    [Documentation]   Start Element in dedicated VM and verify process started
    [Tags]            bat   SP-T57   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}
    Check if ssh is ready on vm    ${COMMS_VM}
    Start XDG application  Element
    Connect to VM          ${COMMS_VM}
    Check that the application was started    element
    [Teardown]  Kill process  @{app_pids}

Start Slack on LenovoX1
    [Documentation]   Start Slack in dedicated VM and verify process started
    [Tags]            bat   SP-T191   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}
    Check if ssh is ready on vm    ${COMMS_VM}
    Start XDG application  Slack
    Connect to VM          ${COMMS_VM}
    Check that the application was started    slack
    [Teardown]  Kill process  @{app_pids}

Start Appflowy on LenovoX1
    [Documentation]   Start Appflowy in dedicated VM and verify process started
    [Tags]            bat   appflowy   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}
    Check if ssh is ready on vm    appflowy-vm
    Start XDG application  AppFlowy
    Connect to VM          ${APPFLOWY_VM}
    Check that the application was started    appflowy
    [Teardown]  Kill process  @{app_pids}
