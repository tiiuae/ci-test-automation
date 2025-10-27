# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for input-related GUI functionality
Force Tags          gui  gui-input

Library             ../../lib/output_parser.py
Library             Collections
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource

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

Change keyboard layout
    [Documentation]     Change keyboard layout with Alt+Shift shortcut
    [Tags]              SP-T138
    Check cosmic config current layout value
    Launch Cosmic Term
    # Wait until application window has been opened (max ~5s).
    Locate on screen    text  ${USER_LOGIN}@gui-vm:  iterations=5
    Type string and press enter                "echo "  enter=False
    Press Key(s)    APOSTROPHE
    Press test key and switch keyboard layout  repeat=3
    Press Key(s)    APOSTROPHE
    Type string and press enter                " > /tmp/key_check.txt"
    ${key_check}                               Execute Command  cat /tmp/key_check.txt
    Execute Command                            rm /tmp/key_check.txt
    IF  $key_check != ';كö'
        FAIL    Failed to get the expected keyboard input ';كö'\nKeyboard input received: ${key_check}
    END
    [Teardown]   Run Keywords   Kill App in VM    ${GUI_VM}   AND   Stop screen recording    ${TEST_STATUS}   ${TEST_NAME}

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


*** Keywords ***

Press test key and switch keyboard layout
    [Documentation]           Press a key which produces different output depending on the keyboard layout:
    ...                       English ; / Arabic ك / Finnish ö
    [Arguments]               ${repeat}=1
    FOR   ${i}   IN RANGE  ${repeat}
        Press Key(s)   SEMICOLON	
        Switch keyboard layout
    END

Check cosmic config current layout value
    [Documentation]           Check the value of current layout in the xkb_config file.
    ...                       If the current value is not 'us' toggle until it is set to 'us'.
    Log To Console            Checking current keyboard layout
    ${output}  ${rc}=         Execute Command  cat .config/cosmic/com.system76.CosmicComp/v1/xkb_config | grep -w layout  return_rc=True
    # If the keyboard layout has never been toggled the file doesn't exist and command fails with rc 1
    # Then we assume default keyboard layout: 'us'
    IF  $rc != 0
        Log To Console    Keyboard layout has not been changed, assuming us
    ELSE
        ${current_layout}   Parse keyboard layout  ${output}
        Log                 ${current_layout}   console=True
        ${placement}        Get From List   ${current_layout}   1
        FOR   ${i}   IN RANGE  ${placement}
            Sleep   0.5
            Switch keyboard layout
        END
    END
