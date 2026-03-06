# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Performance tests
Test Tags           performance

Library             SSHLibrary
Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         Prepare Test Environment
Suite Teardown      Performance Teardown

*** Keywords ***

Performance Teardown
    IF  ${IS_LAPTOP}
        Log out from laptop
    END
    Close All Connections
