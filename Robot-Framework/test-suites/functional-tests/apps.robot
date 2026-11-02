# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Testing launching applications

Resource            ../../resources/app_keywords.resource

Test Template       App Launch Test Template

Test Tags           apps  pre-merge  bat  lenovo-x1  darter-pro  dell-7330


*** Test Cases ***
Start Advanced Network Configuration
    [Tags]            SP-T462
    ${Advanced Network Configuration}
Start App Store
    [Tags]            SP-T461
    ${App Store}
Start Calculator
    [Tags]            SP-T415  fmo
    ${Calculator}
Start COSMIC Document Reader
    [Tags]            SP-T380
    ${COSMIC Document Reader}
Start COSMIC Files
    [Tags]            SP-T422  fmo
    ${COSMIC Files}
Start COSMIC Media Player
    [Tags]            SP-T441
    ${COSMIC Media Player}
Start COSMIC Settings
    [Tags]            SP-T429  fmo
    ${COSMIC Settings}
Start COSMIC System Monitor
    [Tags]            SP-T480
    ${COSMIC System Monitor}
Start COSMIC Terminal
    [Tags]            SP-T431  fmo
    ${COSMIC Terminal}
Start COSMIC Text Editor
    [Tags]            SP-T427  fmo
    ${COSMIC Text Editor}
Start Element
    [Tags]            SP-T500
    ${Element}
Start Fingerprints
    [Tags]            SP-T474
    ${Fingerprints}
Start Gala
    [Tags]            SP-T378
    ${Gala}
Start Getting Started
    [Tags]            SP-T470
    ${Getting Started}
Start Ghaf Control Panel
    [Tags]            SP-T419  fmo
    ${Ghaf Control Panel}
Start Google Chrome
    [Tags]            SP-T498
    ${Google Chrome}
Start GPU Screen Recorder
    [Tags]            SP-T440
    ${GPU Screen Recorder}
Start Microsoft 365
    [Tags]            SP-T393
    ${Microsoft 365}
Start Outlook
    [Tags]            SP-T389
    ${Outlook}
Start Slack
    [Tags]            SP-T397
    ${Slack}
Start Sticky Notes
    [Tags]            SP-T413  fmo
    ${Sticky Notes}
Start Teams
    [Tags]            SP-T391
    ${Teams}
Start Trusted Browser
    [Tags]            SP-T395
    ${Trusted Browser}
Start Volume Control
    [Tags]            SP-T466
    ${Volume Control}
Start VPN
    [Tags]            SP-T411
    ${VPN}
Start Zoom
    [Tags]            SP-T424
    ${Zoom}
