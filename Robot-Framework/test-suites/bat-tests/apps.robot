# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Library             ../../lib/gui_testing.py
Library             Collections
Library             BuiltIn
Suite Setup         Run Keywords  Connect to netvm  AND  Connect to VM  ${GUI_VM}
Suite Teardown      Close All Connections


*** Variables ***
@{app_pids}         ${EMPTY}


*** Test Cases ***

Start Firefox
    [Documentation]   Start Firefox and verify process started
    [Tags]            bat   SP-T41  nuc  orin-agx
    [Setup]           Skip If   "${JOB}" == "nvidia-jetson-orin-agx-debug-nodemoapps-from-x86_64.x86_64-linux"
    ...               Skipped because this build doesn't contain applications
    Connect
    Start Firefox
    Check that the application was started    firefox
    [Teardown]  Kill Process And Log journalctl

Start Chromium on LenovoX1
    [Documentation]   Start Chromium in dedicated VM and verify process started
    [Tags]            bat   SP-T92   lenovo-x1
    [Setup]
    Verify service status  range=15  service=microvm@chromium-vm.service  expected_status=active  expected_state=running
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Check if ssh is ready on vm    ${CHROMIUM_VM}
    Start XDG application   Chromium
    Connect to VM       ${CHROMIUM_VM}
    Check that the application was started    chromium
    [Teardown]  Kill Process And Log journalctl

Start Zathura on LenovoX1
    [Documentation]   Start Zathura in dedicated VM and verify process started
    [Tags]            bat   SP-T105   lenovo-x1
    # [Setup]           Connect to netvm
    # Connect to VM       ${GUI_VM}
    # Sleep  3
    Check if ssh is ready on vm    ${ZATHURA_VM}
    Start XDG application   'PDF Viewer'
    Connect to VM       ${ZATHURA_VM}
    Check that the application was started    zathura
    [Teardown]  Kill Process And Log journalctl

Start Gala on LenovoX1
    [Documentation]   Start Gala in dedicated VM and verify process started
    [Tags]            bat   SP-T104   lenovo-x1
    # [Setup]           Connect to netvm
    # Connect to VM       ${GUI_VM}
    Check if ssh is ready on vm    ${GALA_VM}
    Start XDG application   GALA
    Connect to VM       ${GALA_VM}
    Check that the application was started    gala
    [Teardown]  Kill Process And Log journalctl

Start Element on LenovoX1
    [Documentation]   Start Element in dedicated VM and verify process started
    [Tags]            bat   SP-T52   lenovo-x1
    # [Setup]           Connect to netvm
    # Connect to VM          ${GUI_VM}
    Check if ssh is ready on vm    ${COMMS_VM}
    Start XDG application  Element
    Connect to VM          ${COMMS_VM}
    Check that the application was started    element
    [Teardown]  Kill Process And Log journalctl

Start Slack on LenovoX1
    [Documentation]   Start Slack in dedicated VM and verify process started
    [Tags]            bat   SP-T181   lenovo-x1
    # [Setup]           Connect to netvm
    # Connect to VM          ${GUI_VM}
    Check if ssh is ready on vm    ${COMMS_VM}
    Start XDG application  Slack
    Connect to VM          ${COMMS_VM}
    Check that the application was started    slack
    [Teardown]  Kill Process And Log journalctl

Start Appflowy on LenovoX1
    [Documentation]   Start Appflowy in dedicated VM and verify process started
    [Tags]            appflowy   lenovo-x1  # Removed bat tag until final decision of this app is made
    # [Setup]           Connect to netvm
    # Connect to VM          ${GUI_VM}
    Check if ssh is ready on vm    appflowy-vm
    Start XDG application  AppFlowy
    Connect to VM          ${APPFLOWY_VM}
    Check that the application was started    appflowy
    [Teardown]  Kill Process And Log journalctl


*** Keywords ***
Kill Process And Log journalctl
    [Documentation]  Kill all running process and log journalctl
    ${output}     Execute Command    journalctl
    Log  ${output}
    Kill process  @{app_pids}
