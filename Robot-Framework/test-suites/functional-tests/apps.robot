# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Test Tags           apps  pre-merge  bat  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource

Test Teardown       Kill App in VM   ${TEST_APP-VM}   ${TEST_PROCESS_NAME}


*** Test Cases ***

Start App Store
    [Documentation]   Start App Store and verify process started
    [Tags]            SP-T334
    Start application in VM   "App Store"   ${FLATPAK_VM}   cosmic-store

Start Bluetooth Settings
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            SP-T204  SP-T204-1  fmo
    Start application in VM   "Bluetooth Settings"   ${GUI_VM}   blueman-manager-wrapped-wrapped

Start COSMIC Files
    [Documentation]   Start Cosmic Files and verify process started
    [Tags]            SP-T206  SP-T206-1  fmo
    Start application in VM   com.system76.CosmicFiles   ${GUI_VM}   cosmic-files %U

Start COSMIC Media Player
    [Documentation]   Start Cosmic Media Player and verify process started
    [Tags]            SP-T294
    Start application in VM   com.system76.CosmicPlayer   ${GUI_VM}   cosmic-player %U

Start COSMIC Settings
    [Documentation]   Start Cosmic Settings and verify process started
    [Tags]            SP-T254  fmo
    Start application in VM   com.system76.CosmicSettings   ${GUI_VM}   cosmic-settings-wrapped

Start COSMIC Terminal
    [Documentation]   Start Cosmic Terminal and verify process started
    [Tags]            SP-T263  fmo
    Start application in VM   com.system76.CosmicTerm   ${GUI_VM}   cosmic-term

Start COSMIC Text Editor
    [Documentation]   Start Cosmic Text Editor and verify process started
    [Tags]            SP-T243  fmo
    Start application in VM   com.system76.CosmicEdit   ${GUI_VM}   cosmic-edit %F

Start Calculator
    [Documentation]   Start Calculator and verify process started
    [Tags]            SP-T202  SP-T202-1  fmo
    Start application in VM   Calculator   ${GUI_VM}   calculator

Start Element
    [Documentation]   Start Element and verify process started
    [Tags]            SP-T52
    Start application in VM   Element   ${COMMS_VM}   element

Start GPU Screen Recorder
    [Documentation]   Start GPU Screen Recorder and verify process started
    [Tags]            SP-T293
    Start application in VM   com.dec05eba.gpu_screen_recorder   ${GUI_VM}   gpu-screen-recorder

Start Gala
    [Documentation]   Start Gala in Business-vm and verify process started
    [Tags]            SP-T104
    Start application in VM   Gala   ${BUSINESS_VM}   gala

Start Ghaf Control Panel
    [Documentation]   Start Ghaf Control Panel and verify process started
    [Tags]            SP-T205  SP-T205-1  fmo
    Start application in VM   "Ghaf Control Panel"   ${GUI_VM}   ctrl-panel

Start Google Chrome
    [Documentation]   Start Google Chrome and verify process started
    [Tags]            SP-T92
    Start application in VM   "Google Chrome"   ${CHROME_VM}   chrome

Start Microsoft 365
    [Documentation]   Start Microsoft 365 and verify process started
    [Tags]            SP-T178
    Start application in VM   "Microsoft 365"   ${BUSINESS_VM}   microsoft365

Start Microsoft Outlook
    [Documentation]   Start Microsoft Outlook and verify process started
    [Tags]            SP-T176
    Start application in VM   "Microsoft Outlook"   ${BUSINESS_VM}   outlook

Start PDF Viewer
    [Documentation]   Start PDF Viewer and verify process started
    [Tags]            SP-T105
    Start application in VM   "PDF Viewer"   ${ZATHURA_VM}   zathura

Start Slack
    [Documentation]   Start Slack and verify process started
    [Tags]            SP-T181
    Start application in VM   Slack   ${COMMS_VM}   slack

Start Sticky Notes
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            SP-T201  SP-T201-1  fmo
    Start application in VM   "Sticky Notes"   ${GUI_VM}   sticky-wrapped

Start Teams
    [Documentation]   Start Teams and verify process started
    [Tags]            SP-T177
    Start application in VM   Teams   ${BUSINESS_VM}   teams

Start Trusted Browser
    [Documentation]   Start Trusted Browser and verify process started
    [Tags]            SP-T179
    Start application in VM   "Trusted Browser"  ${BUSINESS_VM}   google-chrome

Start VPN
    [Documentation]   Start VPN app and verify process started
    [Tags]            SP-T200
    Start application in VM   VPN  ${BUSINESS_VM}   gpclient

Start Zoom
    [Documentation]   Start Zoom and verify process started
    [Tags]            SP-T237
    Start application in VM   Zoom  ${COMMS_VM}   zoom
