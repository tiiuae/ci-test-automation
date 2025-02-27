# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing automatic suspension of Lenovo-X1
Force Tags          gui   suspension
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui_keywords.resource
Library             ../../lib/gui_testing.py
Library             ../../lib/output_parser.py
Library             JSONLibrary


*** Test Cases ***

Automatic suspension
    [Documentation]   Wait and check that
    ...               in the beginning brightness is 96000
    ...               in 4 min - the screen dims (brightness is 24000)
    ...               in 5 min - the screen locks (brightness is 24000)
    ...               in 7,5 min - screen turns off
    ...               in 15 min - the laptop is suspended
    [Tags]            SP-T162   lenovo-x1
    [Setup]           Reboot laptop and log in

    Connect
    ${connection1}    Connect to VM            ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Get mako path
    ${last_id}     Get last notification id
    Move cursor
    Switch Connection    ${connection1}
    ${output}    Execute Command    whoami
    ${output}    Execute Command    host
    Check the screen state   on
    Check screen brightness  96000

    ${time}  Get Time
    Log to console    ${time}: waiting for 4 min
    Sleep          240
    Check screen brightness  24000

    ${time}  Get Time
    Log to console    ${time}: waiting for 10 sec
    Sleep          10
    Check notification       The system will suspend soon due to inactivity.    ${last_id}
    Check the screen state   on

    ${time}  Get Time
    Log to console    ${time}: waiting for 50 sec
    Sleep          50
    # somehow check that screen is locked

    ${time}  Get Time
    Log to console    ${time}: waiting for 2.5 min
    Sleep          150
    Check the screen state   off

    ${time}  Get Time
    Log to console    ${time}: waiting for 7.5 min
    Sleep          450
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console       Device is suspended
    ELSE
        Log To Console       Device is available
        FAIL    Device was not suspended
    END

    ${time}  Get Time
    Log to console    ${time}: waiting for 5 min
    Sleep          300
    Log To Console    Turning device on...
    Press Button      ${SWITCH_BOT}-ON
    Check If Device Is Up    range=120
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE
        Log To Console  The device started
    END



*** Keywords ***

Check screen brightness
    [Arguments]       ${brightness}    ${timeout}=10
    FOR    ${i}    IN RANGE    ${timeout}
        ${output}         Execute Command    ls /nix/store | grep brightnessctl
        ${output}         Execute Command    /nix/store/${output}/bin/brightnessctl get
        ${status} =    Run Keyword And Return Status    Should be Equal   ${output}    ${brightness}
        IF    ${status}
            ${is_started} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    The screen brightness is ${output}, expected ${brightness}

Check notification
    [Arguments]       ${text}  ${last_id}
    [Documentation]   First need to know the number of the last notification to check the new one
    ${output}  ${err}         Execute Command         /nix/store/${mako_path}/bin/makoctl history > notifications.txt    return_stderr=True
    ${output}         Execute Command         cat notifications.txt
    ${json}           Convert String To JSON  ${output}
    ${notifications}  Get Value From Json     ${json}    $.data[0][0]
    ${matching_ids}   Create List

    FOR    ${notification}    IN    @{notifications}
        ${body_text}  Get Value From Json    ${notification}    $.body.data[0]
        ${id}         Get Value From Json    ${notification}    $.id.data[0]
        IF    "${body_text}" == "${text}"
            Append To List    ${matching_ids}    ${id}
        ELSE
            Log    "${body_text}" != "${text}"
        END
    END

    ${list_length}    Get Length    ${matching_ids}
    IF    ${list_length} > 0
        ${last_matching_id}    Get From List    ${matching_ids}    -1
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
    ${output}  ${err}         Execute Command         /nix/store/${mako_path}/bin/makoctl history > notifications.txt    return_stderr=True
    ${output}         Execute Command         cat notifications.txt
    ${json}           Convert String To JSON  ${output}
    ${notifications}  Get Value From Json     ${json}    $.data[0][0]
    ${last_notification}    Get From List     ${notifications}    -1
    ${last_id}        Get Value From Json     ${last_notification}    $.id.data[0]
    Log to console    The last notification in the list has ID: ${last_id}
    RETURN            ${last_id}
    [Teardown]        Execute Command         rm notifications.txt

Get mako path
    ${output}         Execute Command     ls /nix/store | grep mako
    ${result}         Extrect mako path   ${output}
    Set Suite Variable    ${mako_path}    ${result}

Check the screen state
    [Arguments]       ${state}
    ${output}         Execute Command    ls /nix/store | grep wlopm
    ${output}  ${err}        Execute Command    WAYLAND_DISPLAY=wayland-0 /nix/store/${output}/bin/wlopm    return_stderr=True
    Should Contain    ${output}    ${state}

Reboot laptop and log in

#    Reboot LenovoX1
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    Sleep  30
    Connect   iterations=10
    Log in via GUI       stop_swayidle=False
    Verify login