# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing FMO target
Force Tags          fmo-apps  bat  regression  fmo

Resource            ../../resources/app_keywords.resource


*** Test Cases ***

Start Display Settings on FMO
    [Documentation]   Start Display Settings and verify process started
    [Tags]            display_settings
    Start application in VM   'Display Settings'   ${GUI_VM}   wdisplays
    [Teardown]        Kill App in VM   ${GUI_VM}

Start Firefox GPU on FMO
    [Documentation]   Start Firefox GPU and verify process started
    [Tags]            firefox_gpu
    Start application in VM   'Firefox GPU'   ${GUI_VM}   firefox
    [Teardown]        Kill App in VM   ${GUI_VM}

Start FMO Onboarding Agent
    [Documentation]   Start FMO Onboarding Agent and verify process started
    [Tags]            onboarding
    Start application in VM   "FMO Onboarding Agent"   ${DOCKER_VM}   fmo-onboarding
    [Teardown]        Kill App in VM   ${DOCKER_VM}

Start FMO Offboarding
    [Documentation]   Start FMO Offboarding and verify process started
    [Tags]            offboarding
    Start application in VM   "FMO Offboarding"   ${DOCKER_VM}   fmo-offboarding
    [Teardown]        Kill App in VM   ${DOCKER_VM}

Start Google Chrome GPU on FMO
    [Documentation]   Start Google Chrome GPU and verify process started
    [Tags]            chrome_gpu
    Start application in VM   'Google Chrome GPU'   ${GUI_VM}   chrome
    [Teardown]        Kill App in VM   ${GUI_VM}
