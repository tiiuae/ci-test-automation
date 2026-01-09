# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Security tests
Test Tags           regression  security

Resource            ../../resources/setup_keywords.resource

Suite Setup         Security tests setup
Suite Teardown      Security tests teardown


*** Keywords ***

Security tests setup
    [Timeout]    5 minutes
    Prepare Test Environment

Security tests teardown
    [Timeout]    5 minutes
    Clean Up Test Environment
