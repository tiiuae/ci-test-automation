# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Suspension test
Test Tags           regression  suspension

Resource            ../../resources/device_control.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         Suspension test setup
Suite Teardown      Suspension test teardown


*** Keywords ***

Suspension test setup
    [Timeout]    5 minutes
    Prepare Test Environment

Suspension test teardown
    [Timeout]    5 minutes
    Clean Up Test Environment
