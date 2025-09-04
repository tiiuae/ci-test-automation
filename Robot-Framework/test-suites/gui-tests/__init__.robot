# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests

Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Library             ../../lib/helper_functions.py
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/gui_keywords.resource

Suite Setup         GUI Tests Setup
Suite Teardown      GUI Tests Teardown
Test Timeout        5 minutes


*** Keywords ***

GUI Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment   enable_dnd=True

    # There's a bug that occasionally causes the app menu to freeze on Cosmic, especially on the first login. 
    # Logging out once before running tests helps reduce the chances of it happening. (SSRCSP-6684)
    ${first_login}   Is first graphical login
    IF  ${first_login}
        Log To Console   First login detected. Logging out and back in to go around a Cosmic bug.
        Log out and verify   disable_dnd=True
        Log in, unlock and verify   enable_dnd=True
    END

GUI Tests Teardown
    [Timeout]    5 minutes
    Clean Up Test Environment   disable_dnd=True

Is first graphical login
    [Documentation]   Returns True if there has only been one graphical login and False if there has been more than one
    ${result}   Execute Command    journalctl --user -u graphical-session.target | grep "Reached target Current graphical user session"
    Log         ${result}
    ${lines}    Count lines    ${result}
    IF  ${lines} <= 1   RETURN   True
    RETURN      False