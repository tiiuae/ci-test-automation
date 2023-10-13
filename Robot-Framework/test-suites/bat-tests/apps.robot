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
    @{pid}=         Find pid by name    firefox
    Should Not Be Empty       ${pid}    Firefox is not started
    [Teardown]  Kill process  @{pid}


Start Chromium
    [Documentation]   Start Chromium and verify process started
    [Tags]            depricated
    Connect
    Start Chromium
    @{pid}=         Find pid by name    chromium
    Should Not Be Empty       ${pid}    Chromium is not started
    [Teardown]  Kill process  @{pid}

