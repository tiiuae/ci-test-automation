# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Functional tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/gui_keywords.resource
Library             OperatingSystem
Test Timeout        10 minutes
Suite Setup         Functional tests setup
Suite Teardown      Functional tests teardown


*** Variables ***
${DISABLE_LOGOUT}     ${EMPTY}


*** Keywords ***

Functional tests setup
    [timeout]    5 minutes
    Prepare Test Environment
    Switch Connection    ${CONNECTION}

Functional tests teardown
    [timeout]    5 minutes
    Clean Up Test Environment