# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Setup of Performance tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Turn On Device
    Check If Device Is Up
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address

Common Teardown
    Close All Connections
    Turn off device
