# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../resources/ssh_keywords.resource
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}
Suite Teardown      Close All Connections

*** Test Cases ***

Start Chromium
    [Documentation]   Start Chromium and verify process started
    [Tags]            bat   SP-T45
    Start Chromium
    ${pid}=     Is Process Started    chromium
    IF    ${pid} == None
        FAIL    Chromium is not started
    END
    [Teardown]  Kill process  ${pid}
