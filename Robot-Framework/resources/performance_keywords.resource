# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             BuiltIn
Library             Collections


*** Keywords ***

Create deviation message
    [Arguments]       ${statistics}     ${inverted}
    ${word}           Set Variable    improvement
    IF  ${inverted} < 1
        IF  ${statistics}[flag] < 0
            ${word}       Set Variable    deviation
        END
    ELSE
        IF  ${statistics}[flag] > 0
            ${word}       Set Variable    deviation
        END
    END
    ${message}=       Set Variable   Significant ${word} detected\n${statistics}\n
    RETURN            ${message}

Determine Test Status
    [Documentation]         Determine if the test is passed or failed. Add notification of significant deviation or improvement to the test message field.
    ...                     Give statistics argument as a dictionary of statistics dictionaries.
    ...                     Inverted argument can be set to 1 for notifying significant decrease of result value as improvement
    ...                     and significant increase of result value as deviation/FAIL.
    [Arguments]             ${statistics_dict}  ${inverted}=0
    ${keys}                 Get Dictionary Keys          ${statistics_dict}
    ${msg}=                 Set Variable  ${EMPTY}
    FOR   ${i}  IN  @{keys}
        ${statistics}       Get From Dictionary      ${statistics_dict}    ${i}
        IF  ${statistics}[flag] != 0
            ${add_msg}      Create deviation message  ${statistics}     ${inverted}
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
