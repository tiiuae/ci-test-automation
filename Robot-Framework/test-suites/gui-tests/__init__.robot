# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Test Timeout        10 minutes
Suite Setup         GUI Tests Setup
Suite Teardown      GUI Tests Teardown


*** Keywords ***

GUI Tests Setup
    Initialize Variables, Connect And Start Logging
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Connect to VM       ${GUI_VM}
        Set compositor
        Save most common icons and paths to icons
        Create test user
        Log in, unlock and verify   enable_dnd=True
    END

GUI Tests Teardown
    Connect to ghaf host
    Log journalctl
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Log out and verify   disable_dnd=True
    END
    Close All Connections