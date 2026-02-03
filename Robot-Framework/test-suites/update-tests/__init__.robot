# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Update tests
Test Tags           regression  update  lenovo-x1  darter-pro

Library             SSHLibrary
Resource            ../../config/variables.robot

Suite Setup         Update tests setup
Suite Teardown      Close All Connections


*** Keywords ***

Update tests setup
    Set Variables   ${DEVICE}
    IF    "storeDisk" in "${JOB}"   SKIP    Update tests can't be executed for storeDisk image.
    IF    "${DEVICE_TYPE}" == "x1-sec-boot"   SKIP   Updating is not supported by signed images.
