*** Settings ***
Documentation       Test for running RF suite.
Force Tags          testi
Library             BuiltIn
Library             String
Library             Collections
# Suite Setup         Open Serial Port
# Suite Teardown      Delete All Ports

*** Variables ***
${DATA}             Testi
${SOME_VAR}         Something


*** Test cases ***
Test Print Data
    [Tags]    logData
    Test Print    ${DATA}

Test Print Variable
    [Tags]    logVariable
    Test Print    ${SOME_VAR}

*** Keywords ***
Test Print
    [Arguments]    ${test_var}
    [Documentation]     Print test variable
    Log To Console    ${test_var}
