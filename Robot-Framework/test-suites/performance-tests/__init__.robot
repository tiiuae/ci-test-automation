# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Setup of Performance tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Suite Setup         Performance tests Setup
Suite Teardown      Performance tests Teardown


*** Keywords ***

Performance tests Setup
    Set Variables   ${DEVICE}
    Turn On Device
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    Check If Device Is Up
    Verify service status   service=init.scope

Performance tests Teardown
    Close All Connections
    Turn off device
