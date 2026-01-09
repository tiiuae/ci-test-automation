# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Functional tests
Test Tags           regression

Resource            ../../resources/setup_keywords.resource

Suite Setup         Functional tests setup
Suite Teardown      Functional tests teardown
Test Timeout        10 minutes


*** Keywords ***

Functional tests setup
    [Timeout]    5 minutes
    Prepare Test Environment

Functional tests teardown
    [Timeout]    5 minutes
    Clean Up Test Environment