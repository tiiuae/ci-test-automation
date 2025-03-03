# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Suite Setup         Run Keywords  Initialize Variables, Connect And Start Logging  AND  GUI Tests Setup
Suite Teardown      Close All Connections


*** Keywords ***

GUI Tests Setup
    IF  "Lenovo" in "${DEVICE}"
        Verify service status   range=15  service=microvm@gui-vm.service  expected_status=active  expected_state=running
        Connect to netvm
        Connect to VM           ${GUI_VM}
        Create test user
    END
    Run journalctl recording
    Save most common icons and paths to icons
    Log To Console              Check if the screen is in locked state
    ${lock}                     Check if locked
    IF  ${lock}
        Log To Console          Screen lock detected
        Unlock
    ELSE
        Log To Console          Screen lock not active. Checking if logged in...
        Log in via GUI
    END
    Verify login
    # Open and close app launcher menu to workaround a bug (icons not visible at first launch of app menu)
    Log To Console    Opening and closing the app menu
    Log To Console    Going to click the app menu icon
    Locate and click  ${start_menu}  0.95  5
    Move cursor to corner
    Log To Console    Going to click the app menu icon
    Locate and click  ${start_menu}  0.95  5
    Move cursor to corner
