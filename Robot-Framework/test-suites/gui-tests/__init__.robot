# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Library             ../../lib/gui_testing.py
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables           ${DEVICE}
    Run Keyword If          "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    ${port_22_is_available}     Check if ssh is ready on device   timeout=180
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Verify service status   range=15  service=microvm@gui-vm.service  expected_status=active  expected_state=running
        Connect to netvm
        Connect to VM           ${GUI_VM}
    END
    Run journalctl recording
    Save most common icons and paths to icons
    Log To Console              Check if the screen is in locked state
    ${lock}                     Check if locked
    IF  ${lock}
        Log To Console          Screen lock detected
        GUI Unlock
    ELSE
        Log To Console          Screen lock not active. Checking if logged in...
        GUI Log in
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

Common Teardown
    Close All Connections
