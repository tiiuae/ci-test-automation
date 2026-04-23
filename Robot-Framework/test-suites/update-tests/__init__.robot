# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Update tests
Test Tags           update  lenovo-x1  darter-pro  excl-storeDisk  excl-secboot

Resource            ../../resources/setup_keywords.resource

Suite Setup         Update tests setup
Suite Teardown      Update tests teardown


*** Keywords ***

Update tests setup
    [Timeout]    5 minutes
    Prepare Test Environment

Update tests teardown
    [Timeout]    5 minutes
    Clean Up Test Environment
