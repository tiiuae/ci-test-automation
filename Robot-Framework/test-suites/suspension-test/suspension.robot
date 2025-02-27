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


*** Test Cases ***

Automatic suspension
    [Documentation]   Wait and check that
    ...               in the beginning brightness is 96000
    ...               in 4 min - the screen dims (brightness is 24000)
    ...               in 5 min - the screen locks (brightness is 24000)
    ...               in 7,5 min - screen turns off
    ...               in 15 min - the laptop is suspended
    [Tags]            SP-T162   lenovo-x1

    Log To Console           Check if the screen is in locked state
    ${lock}                  Check if locked
    IF  ${lock}
        Log To Console       Screen lock detected
        Unlock
    ELSE
        Log To Console       Screen lock not active. Checking if logged in...
        Log in via GUI       stop_swayidle=False
    END
    Verify login

    Connect
    Connect to VM            ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Get mako path
    ${last_id}     Get last notification id
    Move cursor
    Check screen brightness  96000

    ${start_time}  Get Time	 epoch
    Sleep          240
    Check screen brightness  24000
    Check notification       The system will suspend soon due to inactivity.    ${last_id}
    Check the screen state   on
    Sleep          60
    # somehow check that screen is locked
    Sleep          150
    Check the screen state   off
    Sleep          450
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console       Device is suspended
    ELSE
        Log To Console       Device is available
        FAIL    Device was not suspended
    END


*** Keywords ***

Check screen brightness
    [Arguments]       ${brightness}
    ${output}         Execute Command    ls /nix/store | grep brightnessctl
    ${output}         Execute Command    /nix/store/${output}/bin/brightnessctl get
    Should be Equal   ${output}    ${brightness}

Check notification
    [Arguments]       ${text}  ${last_id}
    [Documentation]   First need to know the number of the last notification to check the new one
    ${output}         Execute Command         /nix/store/${mako_path}/bin/makoctl history | cat
    ${json}           Convert String To JSON  ${output}
    ${notifications}  Get Value From Json     ${json}    $.data[0]
    ${matching_ids}   Create List

    FOR    ${notification}    IN    @{notifications}
        ${body_text}  Get Value From Json    ${notification}    $.body.data
        ${id}         Get Value From Json    ${notification}    $.id.data
        IF    "${body_text}" == "${text}"
            Append To List    ${matching_ids}    ${id}
        END
    END

    ${last_matching_id}   Get From List    ${matching_ids}    -1
    Log    Last matching ID: ${last_matching_id}

    IF    ${last_matching_id} > ${last_id}
          Log    The new ID (${last_matching_id}) is greater than the previous one (${last_id}).
    ELSE
          FAIL   The new ID (${last_matching_id}) is NOT greater than the previous one (${last_id}).
    END

Get last notification id
    ${output}         Execute Command         /nix/store/${mako_path}/bin/makoctl history | cat
    ${json}           Convert String To JSON  ${output}
    ${notifications}  Get Value From Json     ${json}    $.data[0]
    ${last_notification}    Get From List     ${notifications}    -1
    ${last_id}        Get Value From Json     ${last_notification}    $.id.data
    [Return]          ${last_id}

Get mako path
    ${output}         Execute Command     ls /nix/store | grep mako
    ${matches}        Get Regexp Matches  ${output}    (?m)^[a-z0-9-]+-mako-[\d.]+$
    Set Suite Variable    ${mako_path}   ${matches}[0]

Check the screen state
    [Arguments]       ${state}
    ${output}         Execute Command    ls /nix/store | grep wlopm
    ${output}         Execute Command    WAYLAND_DISPLAY=wayland-0 /nix/store/${output}/bin/wlopm
    Should Contain    ${output}    ${state}
