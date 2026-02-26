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

Suite Setup         Performance Setup
Suite Teardown      Performance Teardown

*** Keywords ***

Performance Setup
    [Timeout]    5 minutes
    Prepare Test Environment   enable_dnd=True

Performance Teardown
    IF  ${IS_LAPTOP}
        Log out from laptop
    END
    Close All Connections
