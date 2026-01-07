# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications via GUI
Force Tags          gui-apps  gui  lenovo-x1  darter-pro

Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Test Cases ***

Start and close Google Chrome via GUI
    [Documentation]   Start Google Chrome via GUI and verify related process started
    ...               Close Google Chrome via GUI and verify related process stopped
    [Tags]            SP-T41-2
    Start app via GUI   ${CHROME_VM}  chrome  display_name=Chrome
    Close app via GUI   ${CHROME_VM}  google-chrome  ./window-close-neg.png   2

Start and close PDF Viewer via GUI
    [Documentation]   Start PDF Viewer via GUI and verify related process started
    ...               Close PDF Viewer via GUI and verify related process stopped
    [Tags]            SP-T70
    Start app via GUI   ${ZATHURA_VM}  zathura   display_name=PDF
    Close app via GUI   ${ZATHURA_VM}  zathura  ./window-close.png

Start and close Sticky Notes via GUI
    [Documentation]   Start Sticky Notes via GUI and verify related process started
    ...               Close Sticky Notes via GUI and verify related process stopped
    [Tags]            SP-T201-2
    Start app via GUI   ${GUI_VM}  sticky-wrapped  display_name=Sticky
    Close app via GUI   ${GUI_VM}  sticky-wrapped  ./window-close-neg.png

Start and close Calculator via GUI
    [Documentation]   Start Calculator via GUI and verify related process started
    ...               Close Calculator via GUI and verify related process stopped
    [Tags]            SP-T202-2
    Start app via GUI   ${GUI_VM}  gnome-calculator  display_name=Calculator
    Close app via GUI   ${GUI_VM}  gnome-calculator  ./window-close-neg.png

Start and close Bluetooth Settings via GUI
    [Documentation]   Start Bluetooth Settings via GUI and verify related process started
    ...               Close Bluetooth Settings via GUI and verify related process stopped
    [Tags]            SP-T204-2
    Start app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  display_name=Bluetooth
    Close app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  ./window-close.png

Start and close Ghaf Control Panel via GUI
    [Documentation]   Start Ghaf Control Panel via GUI and verify related process started
    ...               Close Ghaf Control Panel via GUI and verify related process stopped
    [Tags]            SP-T205-2
    Start app via GUI   ${GUI_VM}  ctrl-panel  display_name=Control
    Close app via GUI   ${GUI_VM}  ctrl-panel  ./window-close-neg.png
    
Start and close COSMIC Files via GUI
    [Documentation]   Start COSMIC Files via GUI and verify related process started
    ...               Close COSMIC Files via GUI and verify related process stopped
    [Tags]            SP-T206-2
    Start app via GUI   ${GUI_VM}  ^cosmic-files$  display_name=Files
    Close app via GUI   ${GUI_VM}  ^cosmic-files$  ./window-close-neg.png