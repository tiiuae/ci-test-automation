# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Suspension test
Test Tags           regression  suspension

Resource            ../../resources/device_control.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         Prepare Test Environment
Suite Teardown      Clean Up Test Environment
