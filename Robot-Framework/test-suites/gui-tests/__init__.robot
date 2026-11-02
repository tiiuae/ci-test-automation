# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       GUI tests

Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         GUI Tests Setup
Suite Teardown      GUI Tests Teardown
Test Timeout        5 minutes

Test Tags           regression  gui


*** Keywords ***
GUI Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment
    Save gui icons and icon path

GUI Tests Teardown
    [Timeout]    5 minutes
    # In case the screen recording was not stopped
    Stop screen recording service
    Clean Up Test Environment
