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
    [Tags]            bat   pre-merge   SP-T41  nuc  orin-agx
    [Setup]           Skip If   "${JOB}" == "nvidia-jetson-orin-agx-debug-nodemoapps-from-x86_64.x86_64-linux"
    ...               Skipped because this build doesn't contain applications
    Connect
    Start Firefox
    Check that the application was started    firefox
    [Teardown]  Kill Process And Log journalctl

Start Chrome on LenovoX1
    [Documentation]   Start Chrome in dedicated VM and verify process started
    [Tags]            bat   pre-merge   SP-T92   lenovo-x1
    Verify service status  range=15  service=microvm@chrome-vm.service  expected_status=active  expected_state=running
    Connect to netvm
    Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Check if ssh is ready on vm    ${CHROME_VM}
    Start XDG application   'Google Chrome'
    Connect to VM       ${CHROME_VM}
    Check that the application was started    chrome
    [Teardown]  Kill Process And Log journalctl

Start Zathura on LenovoX1
    [Documentation]   Start Zathura in dedicated VM and verify process started
    [Tags]            bat   pre-merge   SP-T105   lenovo-x1
    [Setup]           Log in for apps
    # Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Check if ssh is ready on vm    ${ZATHURA_VM}
    Start XDG application   'PDF Viewer'
    Connect to VM       ${ZATHURA_VM}
    Check that the application was started    zathura
    [Teardown]  Run Keywords
    ...         Kill Process And Log journalctl    AND
    ...         Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-5385"

Start Gala on LenovoX1
    [Documentation]   Start Gala in dedicated VM and verify process started
    [Tags]            bat   pre-merge   SP-T104   lenovo-x1
    [Setup]           Log in for apps
    # Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Check if ssh is ready on vm    ${GALA_VM}
    Start XDG application   GALA
    Connect to VM       ${GALA_VM}
    Check that the application was started    gala
    [Teardown]  Kill Process And Log journalctl

Start Element on LenovoX1
    [Documentation]   Start Element in dedicated VM and verify process started
    [Tags]            bat   pre-merge   SP-T52   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Check if ssh is ready on vm    ${COMMS_VM}
    Start XDG application  Element
    Connect to VM          ${COMMS_VM}
    Check that the application was started    element
    [Teardown]  Kill Process And Log journalctl

Start Slack on LenovoX1
    [Documentation]   Start Slack in dedicated VM and verify process started
    [Tags]            bat   pre-merge   SP-T181   lenovo-x1
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Check if ssh is ready on vm    ${COMMS_VM}
    Start XDG application  Slack
    Connect to VM          ${COMMS_VM}
    Check that the application was started    slack
    [Teardown]  Kill Process And Log journalctl

Start Appflowy on LenovoX1
    [Documentation]   Start Appflowy in dedicated VM and verify process started
    [Tags]            appflowy  # Removed bat tag & lenovo-x1 tag until final decision of this app is made
    [Setup]           Connect to netvm
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
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
