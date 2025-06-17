# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for input-related GUI functionality
Force Tags          gui
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/gui_keywords.resource
Test Setup          GUI Input Test Setup

*** Test Cases ***

Change brightness with keyboard shortcuts
    [Documentation]     Change brightness with ydotool by clicking F5/F6 buttons
    [Tags]              lenovo-x1   SP-T140

    ${init_brightness}  Get screen brightness
    Decrease brightness
    ${l_brightness}     Get screen brightness
    Should Be True      ${l_brightness} < ${init_brightness}
    Increase brightness
    ${h_brightness}     Get screen brightness
    Should Be True      ${h_brightness} > ${l_brightness}


*** Keywords ***

GUI Input Test Setup
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Log in, unlock and verify
