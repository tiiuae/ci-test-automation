# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Docker VM (FMO target)
Force Tags          bat  regression  docker-vm  fmo
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Test Setup          Docker Apps Test Setup
Test Teardown       Docker Apps Test Teardown


*** Test Cases ***

Start FMO Onboarding Agent
    [Documentation]   Start FMO Onboarding Agent in docker-vm and verify process started
    [Tags]            onboarding
    Start XDG application   "FMO Onboarding Agent"
    Connect to VM       ${DOCKER_VM}
    Check that the application was started    fmo-onboarding

Start FMO Offboarding
    [Documentation]   Start FMO Offboarding Agent in docker-vm and verify process started
    [Tags]            offboarding
    Start XDG application   "FMO Offboarding"
    Connect to VM       ${DOCKER_VM}
    Check that the application was started    fmo-offboarding


*** Keywords ***

Docker Apps Test Setup
    Connect to netvm
    Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}

Docker Apps Test Teardown
    Kill process       @{APP_PIDS}
    Close All Connections