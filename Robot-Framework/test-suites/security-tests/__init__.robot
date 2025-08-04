# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Security tests

Resource            ../../resources/setup_keywords.resource

Suite Setup         Connect to device
Suite Teardown      Close All Connections
