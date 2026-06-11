# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Functional tests
Test Tags           regression

Resource            ../../resources/setup_keywords.resource

Suite Setup         Functional Tests Suite Setup
Suite Teardown      Functional Tests Suite Teardown
Test Timeout        10 minutes


*** Variables ***
${SUITE_SETUP_STATUS}    NOT_RUN


*** Keywords ***

Functional Tests Suite Setup
    ${status}=            Run Keyword And Return Status    Prepare Test Environment
    Set Suite Variable    ${SUITE_SETUP_STATUS}    ${status}
    Run Keyword If        not ${status}    FAIL    Suite setup failed

Functional Tests Suite Teardown
    Clean Up Test Environment
    Run Keyword If    "${DEVICE_TYPE}" == "orin-nx" and not ${SUITE_SETUP_STATUS}    Skip    Known issue: SSRCSP-8585, orin-nx suite setup may fail due to SSH
