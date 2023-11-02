# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Teardown      Close All Connections


*** Test Cases ***

Start Firefox
    [Documentation]   Start Firefox and verify process started
    [Tags]            bat   SP-T45  nuc  orin-agx
    Connect
    Start Firefox
    Check that the application was started    firefox
    [Teardown]  Kill process  @{app_pids}

Start Chromium on LenovoX1
    [Documentation]   Start Chromium in dedicated VM and verify process started
    [Tags]            bat   SP-T97   lenovoX1
    [Setup]           Connect to netvm
    Connect to guivm
    Start Chromium
    Connect to chromium vm
    Check that the application was started    chromium
    [Teardown]  Kill process  @{app_pids}


*** Keywords ***

Check that the application was started
    [Arguments]          ${app_name}
    @{found_pids}        Find pid by name    ${app_name}
    Set Global Variable  @{app_pids}  @{found_pids}
    Should Not Be Empty  ${app_pids}  ${app_name} is not started
    Log To Console       ${app_name} is started
