# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Update tests

Library             SSHLibrary
Resource            ../../config/variables.robot

Suite Setup         Set Variables   ${DEVICE}
Suite Teardown      Close All Connections
