# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Tests for input-related GUI functionality

Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/gui_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Test Tags           gui-input  lenovo-x1  darter-pro


*** Variables ***
${OSK_STATE}    /home/${USER_LOGIN}/.local/state/cosmic/com.system76.CosmicOSK/v1


*** Test Cases ***
Check on-screen keyboard when selecting a text field via GUI
    [Documentation]    Enable OSK in Accessibility, type and edit text by clicking its keys, and verify saved content.
    ...                Verify OSK is hidden before opening the editor and after closing it.
    ...                Uses the default US keyboard layout.
    [Tags]             SP-T531
    [Setup]            On-screen keyboard test setup
    Open on-screen keyboard settings
    Toggle on-screen keyboard option    Show on-screen keyboard when selecting a text field
    Close app via GUI    ${COSMIC Settings}
    Verify on-screen keyboard visibility    ${False}
    Start app via GUI    ${COSMIC Text Editor}
    Type and edit text with on-screen keyboard
    Save current document from COSMIC Text Editor to Shares    on_screen_keyboard_test.txt
    ${file_content}      Run Command   cat /Shares/'Unsafe comms-vm share'/on_screen_keyboard_test.txt
    Should Be Equal      ${file_content}    Yky 12
    Close app via GUI    ${COSMIC Text Editor}
    Verify on-screen keyboard visibility    ${False}
    [Teardown]    Run Keywords     Kill App in VM    ${COSMIC Text Editor}    require_exists=False
    ...    AND    Kill App in VM          ${COSMIC Settings}    require_exists=False
    ...    AND    Reset on-screen keyboard setting    ime_activation
    ...    AND    Remove file by name     on_screen_keyboard_test.txt
    ...    AND    Stop screen recording   ${TEST_STATUS}    ${TEST_NAME}

Check always show on-screen keyboard via GUI
    [Documentation]    Show OSK without selecting a text field, then disable the option and verify it disappears.
    [Tags]             SP-T532
    [Setup]            On-screen keyboard test setup
    Open on-screen keyboard settings
    Verify on-screen keyboard visibility    ${False}
    Toggle on-screen keyboard option        Always show on-screen-keyboard
    Verify on-screen keyboard visibility    ${True}
    Toggle on-screen keyboard option        Always show on-screen-keyboard
    Verify on-screen keyboard visibility    ${False}
    Close app via GUI    ${COSMIC Settings}
    [Teardown]    Run Keywords    Kill App in VM     ${COSMIC Settings}    require_exists=False
    ...    AND    Reset on-screen keyboard setting   always_shown
    ...    AND    Stop screen recording              ${TEST_STATUS}    ${TEST_NAME}

Change brightness with keyboard shortcuts
    [Documentation]     Change brightness with ydotool by clicking brightness buttons
    ...                 (Lenovo-X1: F5/F6, Darter-Pro: Fn+F8/Fn+F9)
    [Tags]              SP-T388
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
    [Tags]               SP-T387

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


*** Keywords ***
On-screen keyboard test setup
    Start screen recording
    Reset on-screen keyboard setting    always_shown
    Reset on-screen keyboard setting    ime_activation

Reset on-screen keyboard setting
    [Arguments]    ${setting}
    Run Command    if [ -f ${OSK_STATE}/${setting} ]; then printf false > ${OSK_STATE}/${setting}; fi

Open on-screen keyboard settings
    Start app via GUI    ${COSMIC Settings}
    Locate and click    text    Accessibility    scale=2
    Locate and click    text    On-screen keyboard    scale=2

Toggle on-screen keyboard option
    [Arguments]    ${option}
    # Switches share a column; use the option label to select the correct row.
    ${toggle_x}    ${_}    Locate on screen    image    osk-toggle-off.png    0.95
    ${_}       ${row_y}    Locate on screen    text    ${option}    scale=2
    Run ydotool command    mousemove --absolute -x ${toggle_x} -y ${row_y}
    Click

Verify on-screen keyboard visibility
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    10s    1s    Verify Image On The Screen
    ...    osk-backspace.png    expected=${expected}    confidence=0.90

Type and edit text with on-screen keyboard
    [Documentation]    Type Ykyk, delete the last k with Backspace, then append a space and 12.
    ...                Locate keys once before typing and reuse their coordinates after Shift changes the labels.
    # y and k are distinct labels that OCR recognizes in the US keyboard layout.
    ${keyboard}    Wait Until Keyword Succeeds    10s    1s    Read on-screen keyboard keys
    FOR    ${key}    IN    Shift    y    k    y    k    Backspace    Space    1    2
        Click on-screen keyboard key    ${keyboard}    ${key}
    END

Read on-screen keyboard keys
    [Documentation]    Read text keys with one OCR pass and find Shift/Backspace icons in the same screenshot.
    ${screenshot}      Take Remote Screenshot And Download
    ${keyboard}        Locate on screen keyboard keys    ${screenshot}    ${ICONS_DIR}    y    k    1    2    Space
    RETURN    ${keyboard}

Click on-screen keyboard key
    [Documentation]    Click a key using its previously located ydotool coordinates.
    [Arguments]    ${keyboard}    ${key}
    Log    Clicking OSK key ${key}    console=True
    ${position}    Set Variable    ${keyboard}[${key}]
    Run ydotool command    mousemove --absolute -x ${position}[x] -y ${position}[y]
    Click
