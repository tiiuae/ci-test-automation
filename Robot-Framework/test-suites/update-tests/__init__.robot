# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Update tests
Test Tags           regression  update  lenovo-x1  darter-pro  excl-storeDisk  excl-secboot

Library             SSHLibrary
Resource            ../../config/variables.robot

Suite Setup         Update tests setup
Suite Teardown      Close All Connections


*** Keywords ***

Update tests setup
    Set Variables   ${DEVICE}
