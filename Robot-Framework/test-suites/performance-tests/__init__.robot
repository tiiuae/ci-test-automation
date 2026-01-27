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
Suite Teardown      Close All Connections


*** Keywords ***
Performance Setup
    Check If Device Is Up    range=5
    IF    ${IS_AVAILABLE} == False
        FAIL    The device is not available via SSH or serial.
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    The device is available only via serial, but tests require SSH.
    END
    Switch to vm    ${HOST}
    Log versions and device unique data
