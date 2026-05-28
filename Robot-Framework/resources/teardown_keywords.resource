# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Run Teardown Safely
    [Documentation]    Wrapper to prevent teardown from failing and causing test cases getting failed status.
    ...                Log only ERROR message if the keyword fails.
    [Arguments]    ${keyword}
    ${status}    ${message} =    Run Keyword And Ignore Error    ${keyword}

    Run Keyword If    '${status}' == 'FAIL'
    ...    Log    [TEARDOWN ERROR] ${keyword} failed after ${PREV_TEST_NAME}: ${message}    level=ERROR

    RETURN    ${status}    ${message}
