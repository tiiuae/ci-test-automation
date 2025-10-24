# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Security tests

Resource            ../../resources/setup_keywords.resource

Suite Setup         Security tests setup
Suite Teardown      Security tests teardown


*** Variables ***
${DISABLE_LOGOUT}     ${EMPTY}

*** Keywords ***

Security tests setup
    [Timeout]    5 minutes
    Prepare Test Environment

Security tests teardown
    [Timeout]    5 minutes
    Clean Up Test Environment
