# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing setup
Test Tags           gui-setup  lenovo-x1  darter-pro

Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/setup_keywords.resource

*** Variables ***
${KEYBOARD_CONFIG}      /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicComp/v1/xkb_config
${ORIGINAL_KEYBOARD}    /tmp/xkb_config_${USER_LOGIN}.bak


*** Test Cases ***

Complete Initial Setup
    [Documentation]   Complete ${Cosmic Initial Setup}[display_name]
    [Setup]      Run Keywords   Start screen recording
    ...                   AND   Open Initial Setup
    ...                   AND   Save original values

    Check page and open next   Accessibility setup
    Check page and open next   Get connected

    Select setup option and continue   Select a language        English (Canada)    en_CA.utf8   Verify language
    Select setup option and continue   Select keyboard layout   Finnish (classic)   fi           Verify keyboard language
    Select setup option and continue   Timezone and location    Dubai               Asia/Dubai   Verify timezone

    Switch theme and verify
    Switch layout and verify

    Check page and open next   Workspaces for your workflow
    Check page and open next   New keyboard shortcuts
    Check page and open next   Fast and efficient   click_where_cursor_is=True   # Last button says Finish instead of Next

    Verify that Ghaf intro is running and kill it

    [Teardown]   Run Keywords   Move cursor to corner
    ...                   AND   Kill Initial Setup
    ...                   AND   Restore original values
    ...                   AND   Restore original cosmic config if test failed
    ...                   AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

*** Keywords ***

Open Initial Setup
    [Documentation]   Reset and launch ${Cosmic Initial Setup}[display_name].
    Remove file     /home/${USER_LOGIN}/.config/cosmic-initial-setup-done   rc_match=skip
    Run Keyword And Ignore Error   Verify that Ghaf intro is running and kill it
    Run Command     WAYLAND_DISPLAY=wayland-1 nohup sh -c '${Cosmic Initial Setup}[process_name]' > /tmp/out.log 2>&1 &
    Check that App is running in VM   ${Cosmic Initial Setup}   range=5
    [Teardown]      Run Command   cat /tmp/out.log

Verify that Ghaf intro is running and kill it
    [Documentation]     Verify that ${Getting Started}[display_name] is running and kill it.
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Accept Chrome Terms Of Service If Shown
    Switch to vm    ${Getting Started}[VM]
    Check that App is running in VM   ${Getting Started}  range=10
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}
    Wait Until Keyword Succeeds   15x   1s   Verify Text Is On The Screen   GHAF SECURE LAPTOP
    [Teardown]   Run Keywords   Run Command    journalctl --since "1 minute ago"   # For debugging
    ...                   AND   Kill App in VM   ${Getting Started}   status=${KEYWORD_STATUS}
    ...                   AND   Switch to vm     ${GUI_VM}   user=${USER_LOGIN}

Save original values
    [Documentation]      Save language, keyboard config and timezone before tests
    ${language}          Get language
    Set Suite Variable   ${ORIGINAL_LANGUAGE}   ${language}

    Copy file            ${KEYBOARD_CONFIG}     ${ORIGINAL_KEYBOARD}

    ${timezone}          Get timezone
    Set Suite Variable   ${ORIGINAL_TIMEZONE}   ${timezone}

Restore original values
    [Documentation]   Restore language, keyboard config and timezone to original values
    Set language      ${ORIGINAL_LANGUAGE} 
    Copy file         ${ORIGINAL_KEYBOARD}   ${KEYBOARD_CONFIG}
    Set timezone      ${ORIGINAL_TIMEZONE}
    [Teardown]        Run Command    rm -f ${ORIGINAL_KEYBOARD}

Restore original cosmic config if test failed
    [Documentation]   Remove cosmic config to reset it in case test failed.
    IF  $test_status=='FAIL'
        Log out with loginctl
        Remove file     /home/${USER_LOGIN}/.config/cosmic-initial-setup-done   rc_match=skip
        # First removal can sometimes fail if a file is edited at the same time
        Wait Until Keyword Succeeds  3x  1s   Run Command     rm -rf /home/${USER_LOGIN}/.config/cosmic
        Log in, unlock and verify
    END

Check page and open next
    [Documentation]    Verify that correct page is open and then open next page
    [Arguments]   ${page_name}   ${click_where_cursor_is}=False
    Check that page is correct   ${page_name}
    IF  ${click_where_cursor_is}
        Click    wiggle=True
    ELSE
        Move to next page
    END

Check that page is correct
    [Documentation]    Verify that correct page is open
    [Arguments]   ${page_name}
    Wait Until Keyword Succeeds   5x   1s   Verify Text Is On The Screen   ${page_name}

Move to next page
    [Documentation]   Use Next button to open next page
    Locate and click  image   ghaf-next.png   0.95   wiggle=True

Select setup option and continue
    [Documentation]   Verify correct page, search and select ${search_term} 
    ...               and then confirm ${expected_value} with ${verify_keyword}.
    [Arguments]   ${page_name}   ${search_term}   ${expected_value}   ${verify_keyword}
    Check that page is correct   ${page_name}
    Log               Selecting ${search_term}   console=True
    Locate and click  image  search-neg.png  confidence=0.90   wiggle=True
    Type string       ${search_term}    enter_at_end=True
    Tab and enter     tabs=1
    Wait Until Keyword Succeeds  10x  1s   Run Keyword   ${verify_keyword}   ${expected_value}
    Move to next page

Switch theme and verify
    [Documentation]    Switch to light theme and then back to dark theme.
    ${page_name}   Set Variable   Personalize appearance
    Check that page is correct   ${page_name}

    # Switch to light
    Locate and click  text   Light   scale=3
    Run ydotool command   mousemove -x 0 -y -40
    Click
    Wait Until Keyword Succeeds  10x  1s   Verify theme   light

    # Switch to dark
    Locate and click  text   Dark   scale=3
    Run ydotool command   mousemove -x 0 -y -40
    Click
    Wait Until Keyword Succeeds  10x  1s   Verify theme   dark
    Move to next page

Switch layout and verify
    [Documentation]    Switch to bottom panel layout and then back to top panel
    ${page_name}   Set Variable   Layout configuration
    Check that page is correct   ${page_name}

    # Switch to bottom panel, confirm by checking that keyboard layout is shown at the bottom middle of the screen
    Locate and click  text   configuration
    Run ydotool command   mousemove -x 30 -y 50
    Click
    Wait Until Keyword Succeeds  3x  1s
    ...  Verify item is near expected coordinates   555   585   searched_type=text   searched_item=classic   tolerance=50

    # Switch to top panel, confirm by checking that app launcher is at the bottom middle of the screen
    Run ydotool command   mousemove -x -150 -y 0
    Click
    Wait Until Keyword Succeeds  3x  1s
    ...  Verify item is near expected coordinates   440   585   searched_type=image   searched_item=${APP_MENU_LAUNCHER}   tolerance=50   confidence=0.90
    Move to next page

Verify language
    [Documentation]   Verify that current language matches ${expected_language}.
    [Arguments]       ${expected_language}
    ${language}         Get language
    Should Be Equal   ${expected_language}  ${language}   System language is ${language}, expected ${expected_language}

Get language
    [Documentation]   Returns current language
    ${language}       Run Command    localectl status | awk -F= '/System Locale/{print $2}'
    RETURN            ${language}

Set language
    [Documentation]   Set language with givc-cli
    [Arguments]       ${language}
    Run Command       givc-cli set-locale ${language}
    Wait Until Keyword Succeeds  10x  1s   Verify language   ${language}

Verify keyboard language
    [Documentation]   Verify that current keyboard layout matches ${expected_language}.
    [Arguments]       ${expected_language}
    ${output}         Run Command    cat ${KEYBOARD_CONFIG}
    ${matches}        Get Regexp Matches    ${output}    layout:\\s*\"([^\"]+)\"    1
    Should Be Equal   ${expected_language}  ${matches}[0]   Keyboard language is ${matches}[0], expected ${expected_language}

Verify theme
    [Documentation]   Verify that current theme matches ${expected_theme}.
    [Arguments]       ${expected_theme}
    ${is_dark}        Run Command   cat /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark
    ${theme}          Set Variable If   $is_dark == 'true'   dark   light
    Should Be Equal   ${expected_theme}   ${theme}   Theme is ${theme}, expected ${expected_theme}
