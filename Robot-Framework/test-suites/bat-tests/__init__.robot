# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       BAT tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Suite Setup         BAT tests setup
Suite Teardown      BAT tests teardown


*** Keywords ***

BAT tests setup
    Initialize Variables, Connect And Start Logging

    IF  "Lenovo" in "${DEVICE}"
        Connect to netvm
        Connect to VM         ${GUI_VM}
        Save most common icons and paths to icons
        Create test user
        GUI Log in
    END

BAT tests teardown
    Connect to ghaf host
    Log journctl
    Connect to netvm
    GUI Log out
    Close All Connections