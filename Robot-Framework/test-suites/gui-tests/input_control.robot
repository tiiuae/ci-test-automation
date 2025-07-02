# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for input-related GUI functionality
Force Tags          gui  gui-input
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Library             Collections
Library             ../../lib/output_parser.py


*** Test Cases ***

Change brightness with keyboard shortcuts
    [Documentation]     Change brightness with ydotool by clicking F5/F6 buttons
    [Tags]              lenovo-x1   SP-T140
    ${init_brightness}  Get screen brightness
    Press Key(s)        BRIGHTNESSDOWN
    ${l_brightness}     Get screen brightness
    Should Be True      ${l_brightness} < ${init_brightness}
    Press Key(s)        BRIGHTNESSUP
    ${h_brightness}     Get screen brightness
    Should Be True      ${h_brightness} > ${l_brightness}

Change keyboard layout
    [Documentation]     Change keyboard layout with Alt+Shift shortcut
    [Tags]              lenovo-x1   SP-T138
    Check cosmic config current layout value
    Launch Cosmic Term
    Switch to vm    gui-vm
    Type string and press enter                "echo "  enter=False
    Press Key(s)    APOSTROPHE
    Press test key and switch keyboard layout  repeat=3
    Press Key(s)    APOSTROPHE
    Type string and press enter                " > /tmp/key_check.txt"
    ${key_check}                               Execute Command  cat /tmp/key_check.txt
    Execute Command                            rm /tmp/key_check.txt  sudo=True  sudo_password=${PASSWORD}
    IF  $key_check != ';كö'
        FAIL    Failed to get the expected keyboard input ';كö'\nKeyboard input received: ${key_check}
    END
    [Teardown]  Kill gui-vm apps


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
    Switch to vm    gui-vm  user=${USER_LOGIN}
    ${output}  ${rc}=         Execute Command  cat .config/cosmic/com.system76.CosmicComp/v1/xkb_config | grep -w layout  return_rc=True
    # If the keyboard layout has never been toggled the file doesn't exist and command fails with rc 1
    # Then we assume default keyboard layout: 'us'
    IF  $rc != 0
        Log To Console    Keyboard layout has not been changed, assuming us
    ELSE
        ${current_layout}   Parse keyboard layout  ${output}
        Log                 ${current_layout}   console=True
        ${placement}        Get From List   ${current_layout}   1
        Switch to vm    gui-vm
        FOR   ${i}   IN RANGE  ${placement}
            Sleep   0.5
            Switch keyboard layout
        END
    END
    [Teardown]    Switch to vm    gui-vm  user=${USER_LOGIN}

Kill gui-vm apps
    Switch to vm    gui-vm
    Kill process        @{APP_PIDS}
