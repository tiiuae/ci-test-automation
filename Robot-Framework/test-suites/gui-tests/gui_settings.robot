# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing settings options
Force Tags          gui-settings  lenovo-x1  darter-pro

Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/gui_keywords.resource


*** Test Cases ***

Change timezone in settings
    [Documentation]   Open COSMIC Settings app and change timezone
    [Tags]            SP-T136
    [Setup]           Run Keywords   Start screen recording   AND  Save original timezone
    Set timezone      UTC
    Search in Cosmic Settings   zone
    Tab and enter     tabs=5
    Tab and enter     tabs=9
    Type string and press enter   Dubai
    Tab and enter     tabs=1
    Wait Until Keyword Succeeds  10s  1s   Verify timezone   Asia/Dubai

    [Teardown]   Run Keywords   Set timezone   ${ORIGINAL_TIMEZONE}
    ...          AND   Move cursor to corner
    ...          AND   Kill process by name    cosmic-settings-wrapped   sudo=False
    ...          AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

*** Keywords ***

Search in Cosmic Settings
    [Arguments]     ${search_term}
    Get icon        ${ICONS}/hicolor/48x48/apps  com.system76.CosmicSettings.svg  background=black  output_filename=settings.png
    Move cursor to corner
    Locate and click  image  settings.png  0.95
    # Wait for settings to open
    Locate on screen  text   Network
    Tab and enter     tabs=1
    Tab and enter     tabs=1
    Type string and press enter   ${search_term}

Save original timezone
    ${timezone}           Get timezone
    Set Suite Variable    ${ORIGINAL_TIMEZONE}   ${timezone}