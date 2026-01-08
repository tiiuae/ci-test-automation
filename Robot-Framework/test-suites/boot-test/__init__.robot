# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Boot test

Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Set Variables   ${DEVICE}
Suite Teardown      Close All Connections