# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Security tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/connection_keywords.resource
Suite Setup         Initialize Variables And Connect
Suite Teardown      Close All Connections
