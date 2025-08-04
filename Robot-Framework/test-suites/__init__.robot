# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Suite Setup         Global Setup

*** Keywords ***
Global Setup
    Log To Console  Global setup: Initialize Variables
    Set Variables   ${DEVICE}
