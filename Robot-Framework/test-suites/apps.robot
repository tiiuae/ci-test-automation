*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../resources/ssh_keywords.resource
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}

*** Test Cases ***

Start Chromium
    [Documentation]   Start Chromium and verify process started
    [Tags]            bat   SP-T44
    Start Chromium
    ${pid}=     Is Process Started    chromium
    [Teardown]  Kill process  ${pid}
