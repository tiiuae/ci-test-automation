# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       BAT tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/gui_keywords.resource
Library             OperatingSystem
Test Timeout        10 minutes
Suite Setup         BAT tests setup
Suite Teardown      BAT tests teardown


*** Variables ***
${DISABLE_LOGOUT}     ${EMPTY}


*** Keywords ***

BAT tests setup
    [timeout]    5 minutes
    Initialize Variables, Connect And Start Logging
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Connect to VM         ${GUI_VM}
        Set compositor
        Save most common icons and paths to icons
        Create test user
        Log in, unlock and verify
    END
    Switch Connection    ${CONNECTION}

BAT tests teardown
    [timeout]    5 minutes
    Connect to ghaf host
    Log journalctl
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Log out and verify
    END
    Close All Connections
