# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Test Tags           apps  pre-merge  bat  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource

Test Template       App Launch Test Template


*** Test Cases ***

Start Advanced Network Configuration
    [Tags]            SP-T336  SP-T336-1
    ${Advanced Network Configuration}

Start App Store
    [Tags]            SP-T334  SP-T334-1
    ${App Store}

Start Bluetooth Settings
    [Tags]            SP-T204  SP-T204-1  fmo
    ${Bluetooth Settings}

Start COSMIC Document Reader
    [Tags]            SP-T105  SP-T105-1
    ${COSMIC Document Reader}

Start COSMIC Files
    [Tags]            SP-T206  SP-T206-1  fmo
    ${COSMIC Files}

Start COSMIC Media Player
    [Tags]            SP-T294  SP-T294-1
    ${COSMIC Media Player}

Start COSMIC Settings
    [Tags]            SP-T254  SP-T254-1  fmo
    ${COSMIC Settings}

Start COSMIC System Monitor
    [Tags]            SP-T372  SP-T372-1
    ${COSMIC System Monitor}

Start COSMIC Terminal
    [Tags]            SP-T263  SP-T263-1  fmo
    ${COSMIC Terminal}

Start COSMIC Text Editor
    [Tags]            SP-T243  SP-T243-1  fmo
    ${COSMIC Text Editor}

Start Calculator
    [Tags]            SP-T202  SP-T202-1  fmo
    ${Calculator}

Start Element
    [Tags]            SP-T52  SP-T52-1
    ${Element}

Start Fingerprints
    [Tags]            SP-T364  SP-T364-1
    ${Fingerprints}

Start Gala
    [Tags]            SP-T104  SP-T104-1
    ${Gala}

Start Getting Started
    [Tags]            SP-T354  SP-T354-1
    ${Getting Started}

Start Ghaf Control Panel
    [Tags]            SP-T205  SP-T205-1  fmo
    ${Ghaf Control Panel}

Start Google Chrome
    [Tags]            SP-T92  SP-T92-1
    ${Google Chrome}

Start GPU Screen Recorder
    [Tags]            SP-T293  SP-T293-1
    ${GPU Screen Recorder}

Start Microsoft 365
    [Tags]            SP-T178  SP-T178-1
    ${Microsoft 365}

Start Outlook
    [Tags]            SP-T176  SP-T176-1
    ${Outlook}

Start Slack
    [Tags]            SP-T181  SP-T181-1
    ${Slack}

Start Sticky Notes
    [Tags]            SP-T201  SP-T201-1  fmo
    ${Sticky Notes}

Start Teams
    [Tags]            SP-T177  SP-T177-1
    ${Teams}

Start Trusted Browser
    [Tags]            SP-T179  SP-T179-1
    ${Trusted Browser}

Start Volume Control
    [Tags]            SP-T349  SP-T349-1
    ${Volume Control}

Start VPN
    [Tags]            SP-T200  SP-T200-1
    ${VPN}

Start Zoom
    [Tags]            SP-T237  SP-T237-1
    ${Zoom}
