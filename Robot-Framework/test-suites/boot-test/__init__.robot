# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation      Setup of the boot test
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Setup         Boot test Setup
Suite Teardown      Boot test Teardown


*** Keywords ***

Boot test Setup
    Set Variables   ${DEVICE}

Boot test Teardown
    Close All Connections
