# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             BuiltIn
Library             Collections


*** Keywords ***

Create deviation message
    [Arguments]       ${statistics}
    ${word}           Set Variable    improvement
    IF  ${statistics}[flag] < 0
        ${word}       Set Variable    deviation
    END
    ${message}=       Set Variable   Significant ${word} detected\n${statistics}\n
    RETURN            ${message}

Determine Test Status
    [Documentation]         Determine if the test is passed or failed. Mention significant deviation in the test message field.
    ...                     Argument as a dictionary of statistics dictionaries.
    [Arguments]             ${statistics_dict}
    ${keys}                 Get Dictionary Keys          ${statistics_dict}
    ${msg}=                 Set Variable  ${EMPTY}
    FOR   ${i}  IN  @{keys}
        ${statistics}       Get From Dictionary      ${statistics_dict}    ${i}
        IF  ${statistics}[flag] != 0
            ${add_msg}      Create deviation message  ${statistics}
            ${msg}          Set Variable  ${msg}${i}\n${add_msg}\n
        END
    END
    IF  "deviation" in $msg
        FAIL                ${msg}
    END
    IF  "improvement" in $msg
        Pass Execution  ${msg}
    END

Output Dictionary First Value
    [Documentation]         Argument as a dictionary of statistics dictionaries.
    ...                     Outputs the value of the first dictionary key.
    [Arguments]             ${statistics_dict}
    ${keys}                 Get Dictionary Keys          ${statistics_dict}
    ${output}               Get From Dictionary          ${statistics_dict}    ${keys}[0]
    RETURN                  ${output}
