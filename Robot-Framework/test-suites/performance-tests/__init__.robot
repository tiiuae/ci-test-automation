# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Performance tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}

Common Teardown
    Close All Connections
