# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Test Tags           apps  bat  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource

Test Template       App Launch Test Template


*** Test Cases ***

Start Advanced Network Configuration
    [Tags]            SP-T462
    ${Advanced Network Configuration}

Start App Store
    [Tags]            SP-T461
    ${App Store}

Start COSMIC System Monitor
    [Tags]            SP-T480  -pre-merge
    ${COSMIC System Monitor}

Start Bluetooth Settings
    [Tags]            SP-T418  fmo
    ${Bluetooth Settings}

Start Element
    [Tags]            SP-T500
    ${Element}

Start COSMIC Terminal
    [Tags]            SP-T431  -pre-merge  fmo
    ${COSMIC Terminal}

Start Gala
    [Tags]            SP-T378
    ${Gala}

Start COSMIC Document Reader
    [Tags]            SP-T380
    ${COSMIC Document Reader}

Start Getting Started
    [Tags]            SP-T470
    ${Getting Started}

Start COSMIC Text Editor
    [Tags]            SP-T427  -pre-merge  fmo
    ${COSMIC Text Editor}

Start Google Chrome
    [Tags]            SP-T498
    ${Google Chrome}

Start COSMIC Files
    [Tags]            SP-T422  fmo
    ${COSMIC Files}

Start Microsoft 365
    [Tags]            SP-T393
    ${Microsoft 365}

Start Calculator
    [Tags]            SP-T415  -pre-merge  fmo
    ${Calculator}

Start COSMIC Media Player
    [Tags]            SP-T441
    ${COSMIC Media Player}

Start Outlook
    [Tags]            SP-T389
    ${Outlook}

Start Ghaf Control Panel
    [Tags]            SP-T419  -pre-merge  fmo
    ${Ghaf Control Panel}

Start Slack
    [Tags]            SP-T397
    ${Slack}

Start COSMIC Settings
    [Tags]            SP-T429  fmo
    ${COSMIC Settings}

Start Teams
    [Tags]            SP-T391
    ${Teams}

Start GPU Screen Recorder
    [Tags]            SP-T440  -pre-merge
    ${GPU Screen Recorder}

Start Trusted Browser
    [Tags]            SP-T395
    ${Trusted Browser}

Start Fingerprints
    [Tags]            SP-T474
    ${Fingerprints}

Start VPN
    [Tags]            SP-T411
    ${VPN}

Start Sticky Notes
    [Tags]            SP-T413  -pre-merge  fmo
    ${Sticky Notes}

Start Zoom
    [Tags]            SP-T424
    ${Zoom}

Start Volume Control
    [Tags]            SP-T466
    ${Volume Control}
