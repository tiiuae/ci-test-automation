# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps  pre-merge  bat  regression  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource


*** Test Cases ***

Start Bluetooth Settings
    [Documentation]   Start Bluetooth Settings and verify process started
    [Tags]            SP-T204  fmo
    Start application in VM   "Bluetooth Settings"   ${GUI_VM}   blueman-manager-wrapped-wrapped
    [Teardown]        Kill App in VM   ${GUI_VM}

Start COSMIC Files
    [Documentation]   Start Cosmic Files and verify process started
    [Tags]            SP-T206  fmo
    Start application in VM   com.system76.CosmicFiles   ${GUI_VM}   cosmic-files %U   exact_match=true
    [Teardown]        Kill App in VM   ${GUI_VM}

Start COSMIC Media Player
    [Documentation]   Start Cosmic Media Player and verify process started
    [Tags]            SP-T294
    Start application in VM   com.system76.CosmicPlayer   ${GUI_VM}   cosmic-player %U   exact_match=true
    [Teardown]        Kill App in VM   ${GUI_VM}

Start COSMIC Settings
    [Documentation]   Start Cosmic Settings and verify process started
    [Tags]            SP-T254  fmo
    Start application in VM   com.system76.CosmicSettings   ${GUI_VM}   cosmic-settings   exact_match=true
    [Teardown]        Kill App in VM   ${GUI_VM}

Start COSMIC Terminal
    [Documentation]   Start Cosmic Terminal and verify process started
    [Tags]            SP-T263  fmo
    Launch Cosmic Term
    [Teardown]        Kill App in VM   ${GUI_VM}

Start COSMIC Text Editor
    [Documentation]   Start Cosmic Text Editor and verify process started
    [Tags]            SP-T243  fmo
    Start application in VM   com.system76.CosmicEdit   ${GUI_VM}   cosmic-edit %F   exact_match=true
    [Teardown]        Kill App in VM   ${GUI_VM}

Start Calculator
    [Documentation]   Start Calculator and verify process started
    [Tags]            SP-T202  fmo
    Start application in VM   Calculator   ${GUI_VM}   calculator
    [Teardown]        Kill App in VM   ${GUI_VM}

Start Element
    [Documentation]   Start Element and verify process started
    [Tags]            SP-T52
    Start application in VM   Element   ${COMMS_VM}   element
    [Teardown]        Kill App in VM   ${COMMS_VM}

Start GPU Screen Recorder
    [Documentation]   Start GPU Screen Recorder and verify process started
    [Tags]            SP-T293
    Start application in VM   com.dec05eba.gpu_screen_recorder   ${GUI_VM}   gpu-screen-recorder
    [Teardown]        Kill App in VM   ${GUI_VM}

Start Gala
    [Documentation]   Start Gala in Business-vm and verify process started
    [Tags]            SP-T104
    Start application in VM   Gala   ${BUSINESS_VM}   gala
    [Teardown]        Kill App in VM   ${BUSINESS_VM}

Start Ghaf Control Panel
    [Documentation]   Start Ghaf Control Panel and verify process started
    [Tags]            SP-T205  fmo
    Start application in VM   "Ghaf Control Panel"   ${GUI_VM}   ctrl-panel
    [Teardown]        Kill App in VM   ${GUI_VM}

Start Google Chrome
    [Documentation]   Start Google Chrome and verify process started
    [Tags]            SP-T92
    Start application in VM   "Google Chrome"   ${CHROME_VM}   chrome
    [Teardown]        Kill App in VM   ${CHROME_VM}

Start Microsoft 365
    [Documentation]   Start Microsoft 365 and verify process started
    [Tags]            SP-T178
    Start application in VM   "Microsoft 365"   ${BUSINESS_VM}   microsoft365
    [Teardown]        Kill App in VM   ${BUSINESS_VM}

Start Microsoft Outlook
    [Documentation]   Start Microsoft Outlook and verify process started
    [Tags]            SP-T176
    Start application in VM   "Microsoft Outlook"   ${BUSINESS_VM}   outlook
    [Teardown]        Kill App in VM   ${BUSINESS_VM}

Start PDF Viewer
    [Documentation]   Start PDF Viewer and verify process started
    [Tags]            SP-T105
    Start application in VM   "PDF Viewer"   ${ZATHURA_VM}   zathura
    [Teardown]        Kill App in VM   ${ZATHURA_VM}

Start Slack
    [Documentation]   Start Slack and verify process started
    [Tags]            SP-T181
    Start application in VM   Slack   ${COMMS_VM}   slack
    [Teardown]        Kill App in VM   ${COMMS_VM}

Start Sticky Notes
    [Documentation]   Start Sticky Notes and verify process started
    [Tags]            SP-T201-1  fmo
    Start application in VM   "Sticky Notes"   ${GUI_VM}   sticky-wrapped
    [Teardown]        Kill App in VM   ${GUI_VM}

Start Teams
    [Documentation]   Start Teams and verify process started
    [Tags]            SP-T177
    Start application in VM   Teams   ${BUSINESS_VM}   teams
    [Teardown]        Kill App in VM   ${BUSINESS_VM}

Start Trusted Browser
    [Documentation]   Start Trusted Browser and verify process started
    [Tags]            SP-T179
    Start application in VM   "Trusted Browser"  ${BUSINESS_VM}   google-chrome
    [Teardown]        Kill App in VM   ${BUSINESS_VM}

# Does not work, there is also another match for VPN
# Start VPN
#     [Documentation]   Start VPN app and verify process started
#     [Tags]            SP-T200
#     Start application in VM   VPN  ${BUSINESS_VM}   gpclient
#     [Teardown]        Kill App in VM   ${BUSINESS_VM}

Start Video Editor
    [Documentation]   Start Video Editor and verify process started
    [Tags]            SP-T244
    Start application in VM   "Video Editor"  ${BUSINESS_VM}   lossless
    [Teardown]        Kill App in VM   ${BUSINESS_VM}

Start Zoom
    [Documentation]   Start Zoom and verify process started
    [Tags]            SP-T237
    Start application in VM   Zoom  ${COMMS_VM}   zoom
    [Teardown]        Kill App in VM   ${COMMS_VM}