# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for input-related GUI functionality
Force Tags          gui-input  gui

Library             ../../lib/output_parser.py
Library             Collections
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Test Cases ***

Change brightness with keyboard shortcuts
    [Documentation]     Change brightness with ydotool by clicking brightness buttons
    ...                 (Lenovo-X1: F5/F6, Darter-Pro: Fn+F8/Fn+F9)
    [Tags]              SP-T140  lenovo-x1  darter-pro
    ${init_brightness}  Get screen brightness
    Press Key(s)        BRIGHTNESSDOWN
    ${l_brightness}     Get screen brightness
    Should Be True      ${l_brightness} < ${init_brightness}
    Press Key(s)        BRIGHTNESSUP
    ${h_brightness}     Get screen brightness
    Should Be True      ${h_brightness} > ${l_brightness}

Control audio volume with keyboard shortcuts
    [Documentation]      Check that volume level is increased by pressing F3 (Lenovo-X1) or Fn+F6 (Darter-Pro),
    ...                  decreased - by pressing F2 (Lenovo-X1) or Fn+F5 (Darter-Pro),
    ...                  mute status is changed by pressing F1 (Lenovo-X1) or Fn+F3 (Darter-Pro),
    ...                  mute status is changed back by pressing F1 (Lenovo-X1) or Fn+F3 (Darter-Pro),
    ...                  volume level after mute/unmute is the same
    [Tags]               SP-T134  lenovo-x1  darter-pro

    ${init_volume}       Get volume level
    Press Key(s)         VOLUMEUP
    ${volume_up}         Get volume level
    Run Keyword And Continue On Failure 	Should Be True
    ...                  ${volume_up} > ${init_volume}    Volume level was not increased

    Press Key(s)         VOLUMEDOWN
    ${volume_down}       Get volume level
    Run Keyword And Continue On Failure 	Should Be True
    ...                  ${volume_down} < ${volume_up}    Volume level was not decreased

    ${mute_1}            Get mute status
    Press Key(s)         MUTE
    ${mute_2}            Get mute status
    Run Keyword And Continue On Failure 	Should Not Be Equal
    ...                  ${mute_1}  ${mute_2}    Mute status hasn't changed

    Press Key(s)         MUTE
    ${mute_3}            Get mute status
    Run Keyword And Continue On Failure 	Should Not Be Equal
    ...                  ${mute_2}  ${mute_3}    Mute status hasn't changed

    ${vol_after_mute}    Get volume level
    Should Be Equal      ${vol_after_mute}    ${volume_down}    Volume level after mute status changing is different
