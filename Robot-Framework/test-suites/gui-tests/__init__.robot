# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Test Timeout        5 minutes
Suite Setup         GUI Tests Setup
Suite Teardown      GUI Tests Teardown


*** Keywords ***

GUI Tests Setup
    Prepare Test Environment   enable_dnd=True

    # There's a bug that occasionally causes the app menu to freeze on Cosmic, especially on the first login. 
    # Logging out once before running tests helps reduce the chances of it happening. (SSRCSP-6684)
    IF  $COMPOSITOR == 'cosmic'
        Log out and verify   disable_dnd=True
        Log in, unlock and verify   enable_dnd=True
    END

GUI Tests Teardown
    Clean Up Test Environment   disable_dnd=True