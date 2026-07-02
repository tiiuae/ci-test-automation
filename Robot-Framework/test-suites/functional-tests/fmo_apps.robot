# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing FMO target
Test Tags           fmo-apps  bat  fmo

Resource            ../../resources/app_keywords.resource

Test Template       App Launch Test Template


*** Test Cases ***

Start Display Settings
    [Tags]            display_settings
    ${Display Settings}

Start Firefox GPU
    [Tags]            firefox_gpu
    ${Firefox GPU}

Start FMO Onboarding Agent
    [Tags]            onboarding
    ${FMO Onboarding Agent}

Start FMO Offboarding
    [Tags]            offboarding
    ${FMO Offboarding}

Start Google Chrome GPU
    [Tags]            chrome_gpu
    ${Google Chrome GPU}
