*** Settings ***
Documentation       Test for running RF suite.
Force Tags          testi2
Library             BuiltIn
Library             String
Library             Collections
# Suite Setup         Open Serial Port
# Suite Teardown      Delete All Ports

*** Variables ***
${DATA}             Testi
${SOME_VAR}         Something


*** Test cases ***
Test Data
    [Tags]    Data
    Test Print    ${DATA}

Test Variable
    [Tags]    Variable
    Test Print    ${SOME_VAR}

*** Keywords ***
Test Print
    [Arguments]    ${test_var}
    [Documentation]     Print test variable
    Log To Console    ${test_var}
