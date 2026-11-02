# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Suspension test

Resource            ../../resources/device_control.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         Suspension Tests Setup
Suite Teardown      Clean Up Test Environment

Test Tags           regression  suspension


*** Keywords ***
Suspension Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment
    Save gui icons and icon path
