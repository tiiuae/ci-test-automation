# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for GUI session and application state persistence
Test Tags           gui-session  lenovo-x1  darter-pro

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Test Cases ***

Change workspace with app open
    [Documentation]   Open ${COSMIC Text Editor}[display_name], switch to another workspace,
    ...               verify the app window is not visible, then return to the first workspace
    ...               and verify that the app window is still there.
    [Tags]            SP-T248
    Start app via GUI              ${COSMIC Text Editor}
    Verify app window visibility   ${COSMIC Text Editor}    attempts=10x
    Change workspace    2
    Verify app window visibility   ${COSMIC Text Editor}    attempts=2x    expected=${False}
    Change workspace    1
    Verify app window visibility   ${COSMIC Text Editor}    attempts=2x
    [Teardown]    Run Keywords    Kill App in VM        ${COSMIC Text Editor}
    ...           AND             Switch to vm          ${GUI_VM}    user=${USER_LOGIN}
    ...           AND             Stop screen recording    ${TEST_STATUS}    ${TEST_NAME}

*** Keywords ***

Change workspace
    [Documentation]  Switch to the given workspace with a shortcut.
    [Arguments]      ${workspace_number}
    Press Key(s)     LEFTMETA+${workspace_number}

Verify app window visibility
    [Documentation]   Wait until the app window close button visibility matches the expected state.
    [Arguments]       ${app_key}    ${expected}=${True}    ${attempts}=2x
    Wait Until Keyword Succeeds    ${attempts}    1s
    ...                           Verify Image On The Screen    ${app_key}[close_button]    expected=${expected}
