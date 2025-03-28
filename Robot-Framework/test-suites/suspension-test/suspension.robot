# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing automatic suspension of Lenovo-X1
Force Tags          gui   suspension
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/connection_keywords.resource
Library             ../../lib/output_parser.py
Library             JSONLibrary
Suite Setup         Suspension setup

*** Test Cases ***

Automatic suspension
    [Documentation]   Wait and check that
    ...               in the beginning brightness is 96000
    ...               in 4 min - the screen dims (brightness is 24000)
    ...               in 5 min - the screen locks (brightness is 24000)
    ...               in 7,5 min - screen turns off
    ...               in 15 min - the laptop is suspended
    ...               in 5 min press the button and check that laptop woke up
    [Tags]            SP-T162   lenovo-x1
    [Setup]           Test setup

    Check the screen state   on
    Check screen brightness  96000

    Wait     240
    Check screen brightness  24000

    Wait     10
    Check notification       The system will suspend soon due to inactivity.    ${last_id}
    Check the screen state   on

    Wait     50

    # to do: check that screen is locked

    Wait     150
    Check the screen state   off

    Wait     450
    Check if device was suspended

    Wait     300
    Wake up device

*** Keywords ***

Test setup
#    Connect
    ${guivm_connection}  Connect to VM    ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Get mako path
    ${last_id}           Get last notification id
    Set Suite Variable   ${last_id}    ${last_id}
    Move cursor
    Switch Connection    ${guivm_connection}

Wait
    [Arguments]     ${sec}
    ${time}         Get Time
    Log to console  ${time}: waiting for ${sec} sec
    Sleep           ${sec}

Check screen brightness
    [Arguments]       ${brightness}    ${timeout}=10
    FOR  ${i}  IN RANGE  ${timeout}
        ${output}     Execute Command    ls /nix/store | grep brightnessctl
        ${output}     Execute Command    /nix/store/${output}/bin/brightnessctl get
        ${status}     Run Keyword And Return Status    Should be Equal   ${output}    ${brightness}
        IF  ${status}
            ${is_started}  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF  ${status} == False    FAIL    The screen brightness is ${output}, expected ${brightness}

Check notification
    [Arguments]       ${text}  ${last_id}
    [Documentation]   First need to know the number of the last notification to check the new one
    ${output}         Execute Command  /nix/store/${mako_path}/bin/makoctl history > notifications.txt
    ${output}         Execute Command         cat notifications.txt
    ${json}           Convert String To JSON  ${output}
    ${notifications}  Get Value From Json     ${json}    $.data[0][0]
    Log               ${notifications}
    ${matching_ids}   Create List

    FOR    ${notification}    IN    @{notifications}
        ${body_text}  Get Value From Json    ${notification}    $.body.data
        Log           ${body_text}
        ${id}         Get Value From Json    ${notification}    $.id.data
        IF    "${body_text}[0]" == "${text}"
            Append To List    ${matching_ids}    ${id}
        ELSE
            Log    "${body_text}" != "${text}"
        END
    END
    Log    ${matching_ids}
    ${list_length}    Get Length    ${matching_ids}
    IF    ${list_length} > 0
        ${last_matching_id}    Get From List    ${matching_ids}    -1
        ${last_matching_id}    Set Variable     ${last_matching_id}[0]
        Log to console    The last notification about suspension has ID: ${last_matching_id}
    ELSE
        FAIL    No matching notifications found!
    END

    IF    ${last_matching_id} > ${last_id}
        Log to console    The new ID (${last_matching_id}) is greater than the previous one (${last_id}).
    ELSE
        FAIL   The new ID (${last_matching_id}) is NOT greater than the previous one (${last_id}).
    END
    [Teardown]    Execute Command         rm notifications.txt

Get last notification id
    ${output}         Execute Command         /nix/store/${mako_path}/bin/makoctl history > notifications.txt    return_stderr=True
    ${output}         Execute Command         cat notifications.txt
    ${json}           Convert String To JSON  ${output}
    ${notifications}  Get Value From Json     ${json}    $.data[0][0]
    ${length}         Get Length              ${notifications}
    IF    ${length} == 0
        ${last_id}              Set Variable    0
    ELSE
        ${last_notification}    Get From List   ${notifications}    -1
        ${last_id}        Get Value From Json   ${last_notification}    $.id.data
    END
    Log to console    The last notification in the list has ID: ${last_id}
    RETURN            ${last_id}
    [Teardown]        Execute Command         rm notifications.txt

Get mako path
    ${output}         Execute Command     ls /nix/store | grep mako
    ${result}         Extract mako path   ${output}
    Set Suite Variable    ${mako_path}    ${result}

Check the screen state
    [Arguments]       ${state}
    ${output}         Execute Command    ls /nix/store | grep wlopm
    ${output}  ${err}        Execute Command    WAYLAND_DISPLAY=wayland-0 /nix/store/${output}/bin/wlopm    return_stderr=True
    Should Contain    ${output}    ${state}

Check if device was suspended
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console       Device is suspended
    ELSE
        Log To Console       Device is available
        FAIL    Device was not suspended
    END

Wake up device
    Log To Console    Pressing the power button...
    Press Button      ${SWITCH_BOT}-ON
    Check If Device Is Up    range=120
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE
        Log To Console  The device started
    END

Suspension setup

    Reboot LenovoX1
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    Sleep  30
    Connect   iterations=10

    Initialize Variables, Connect And Start Logging
    Connect to VM        ${GUI_VM}
    Save most common icons and paths to icons
    Create test user
    Log in via GUI       stop_swayidle=False

    Verify login