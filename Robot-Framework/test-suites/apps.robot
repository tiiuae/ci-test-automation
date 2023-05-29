*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
Library             ../lib/TapoP100/tapo_p100.py
Resource            ../resources/serial_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}

*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False

*** Test Cases ***

Start Chromium
    [Documentation]   Start Chromium and verify process started
    Start Chromium
    ${pid}=     Is Process Started    chromium
    [Teardown]  Kill process  ${pid}
