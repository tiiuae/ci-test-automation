# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests

Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Library             ../../lib/helper_functions.py
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         GUI Tests Setup
Suite Teardown      GUI Tests Teardown
Test Timeout        5 minutes


*** Keywords ***

GUI Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment   enable_dnd=True

GUI Tests Teardown
    [Timeout]    5 minutes
    # In case the screen recording was not stopped
    Kill App By Name        gpu-screen-recorder
    Clean Up Test Environment   disable_dnd=True
