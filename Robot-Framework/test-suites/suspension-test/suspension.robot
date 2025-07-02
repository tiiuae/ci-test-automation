# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing automatic suspension of Lenovo-X1
Force Tags          regression   suspension
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/power_meas_keywords.resource
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
    Check screen brightness  ${max_brightness}

    Start power measurement       ${BUILD_ID}   timeout=1500
    Connect
    Connect to VM    ${GUI_VM}  ${USER_LOGIN}  ${USER_PASSWORD}
    Set start timestamp

    Wait     240
    Check screen brightness  ${dimmed_brightness}

    Wait     10

    Check the screen state   on
    Wait    50
    ${locked}         Check if locked
    Should Be True    ${locked}
    Wait     630

    Check if device was suspended
    Wait     300
    Wake up device
    Generate power plot           ${BUILD_ID}   ${TEST NAME}
    Stop recording power

*** Keywords ***

Test setup
    Get mako path
    ${last_id}           Get last notification id
    Set Suite Variable   ${last_id}    ${last_id}
    Move cursor
    Connect to VM    ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Get expected brightness values

Wait
    [Arguments]     ${sec}
    ${time}         Get Time
    Log To Console  ${time}: waiting for ${sec} sec
    Sleep           ${sec}

Get expected brightness values
    ${device}     Execute Command    ls /sys/class/backlight/
    ${max}        Execute Command    cat /sys/class/backlight/${device}/max_brightness
    Set Test Variable  ${max_brightness}     ${max}
    Log To Console     Max brightness value is ${max}
    ${int_max}         Convert To Integer    ${max}
    ${dimmed}          Evaluate   __import__('math').ceil(${int_max} / 4)
    Log To Console     Dimmed brightness is expected to be ~${dimmed}
    Set Test Variable  ${dimmed_brightness}  ${dimmed}

Check screen brightness
    [Arguments]       ${brightness}    ${timeout}=60
    # 10 second timeout should be enough, but for some reason sometimes dimming the screen takes longer.
    # To prevent unnecessary fails timeout has been increased.
    FOR  ${i}  IN RANGE  ${timeout}
        ${output}     Execute Command    ls /nix/store | grep brightnessctl | grep -v .drv
        ${output}     Execute Command    /nix/store/${output}/bin/brightnessctl get
        Log To Console    Check ${i}: Brightness is ${output}
        ${status}     Run Keyword And Return Status  Should be Equal As Numbers   ${output}  ${brightness}
        IF  ${status}
            BREAK
        ELSE
            Sleep    1
        END
    END
    IF  ${status} == False    FAIL    The screen brightness is ${output}, expected ${brightness}

Check notification
    [Arguments]       ${text}  ${last_id}
    [Documentation]   First need to know the number of the last notification to check the new one
    ${notifications}  Execute Command  /nix/store/${MAKO_PATH}/bin/makoctl history
    Log               ${notifications}
    ${notifications}  Parse notifications    ${notifications}

    ${last_matching_id}    Set Variable    None
    FOR    ${key}     ${value}    IN    &{notifications}
        ${status}     Run Keyword And Return Status    Should Be Equal    ${value}    Automatic suspend
        IF    ${status}
            ${last_matching_id}    Set Variable    ${key}
            BREAK
        END
    END

    Run Keyword If    "$last_matching_id" == "None"    Fail    No matching notifications found!
    Log    The last notification "Automatic suspend" has ID: ${last_matching_id}

    IF    ${last_matching_id} > ${last_id}
        Log To Console    The new ID (${last_matching_id}) is greater than the previous one (${last_id}).
    ELSE
        FAIL   The new ID (${last_matching_id}) is NOT greater than the previous one (${last_id}).
    END

Get last notification id
    ${notifications}    Execute Command   /nix/store/${MAKO_PATH}/bin/makoctl history
    IF  "${notifications}" == ""
        ${last_id}      Set Variable    0
    ELSE
        ${last_id}      Get last mako notification id   ${notifications}
    END
    Log To Console      The last notification in the list has ID: ${last_id}
    RETURN              ${last_id}

Check the screen state
    [Arguments]         ${state}
    ${output}           Execute Command    ls /nix/store | grep wlopm | grep -v .drv
    ${output}  ${err}   Execute Command    WAYLAND_DISPLAY=wayland-1 /nix/store/${output}/bin/wlopm    return_stderr=True
    Log To Console      Screen state: ${output}
    Should Contain      ${output}    ${state}

Check if device was suspended
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console  Device is suspended
    ELSE
        Log To Console  Device is available
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

    Prepare Test Environment   stop_swayidle=False