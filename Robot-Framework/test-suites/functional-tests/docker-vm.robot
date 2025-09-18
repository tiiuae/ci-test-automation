# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Docker VM (FMO target)
Force Tags          bat  regression  docker-vm  fmo

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Teardown       Docker Apps Test Teardown


*** Test Cases ***

Start FMO Onboarding Agent
    [Documentation]   Start FMO Onboarding Agent in docker-vm and verify process started
    [Tags]            onboarding
    Start application in VM   "FMO Onboarding Agent"   ${DOCKER_VM}   fmo-onboarding

Start FMO Offboarding
    [Documentation]   Start FMO Offboarding Agent in docker-vm and verify process started
    [Tags]            offboarding
    Start application in VM   "FMO Offboarding"   ${DOCKER_VM}   fmo-offboarding


*** Keywords ***

Docker Apps Test Teardown
    Kill process       @{APP_PIDS}
    Log and remove app output   output.log   ${GUI_VM}   ${USER_LOGIN}
    Run Keyword If Test Failed   Log app vm journalctl   ${DOCKER_VM}