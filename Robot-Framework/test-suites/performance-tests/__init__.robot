# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Performance tests

Library             SSHLibrary
Resource            ../../config/variables.robot
Test Timeout        10 minutes

Suite Teardown      Close All Connections
