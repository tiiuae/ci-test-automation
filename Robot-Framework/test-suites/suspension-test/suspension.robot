# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing automatic suspension of Lenovo-X1
Force Tags          regression   suspension

Resource            ../../resources/device_control.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/power_meas_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Library             ../../lib/output_parser.py
Library             JSONLibrary


*** Test Cases ***

Automatic suspension
    [Documentation]   Wait and check that
    ...               in the beginning brightness is 100 %
    ...               in 4 min - the screen dims (brightness is 25 %)
    ...               in 5 min - the screen locks (brightness is 25 %)
    ...               in 15 min - the laptop is suspended
    ...               in 20 min press the button and check that laptop woke up
    [Tags]            SP-T162    lenovo-x1   lab-only
    [Setup]           Test setup
    [Teardown]        Test teardown

    Check the screen state   on
    Check screen brightness  ${max_brightness}

    Start power measurement  ${BUILD_ID}   timeout=1500
    Connect
    Switch to vm    ${GUI_VM}   user=${USER_LOGIN}

    Wait                     60
    Set timestamp            before_suspend_start
    Wait                     60
    Set timestamp            before_suspend_end
    Wait                     120
    Check screen brightness  ${dimmed_brightness}

    Wait                     10

    Check the screen state   on
    Wait                     50
    ${locked}                Check if locked
    Should Be True           ${locked}

    Wait                     610

    Check that device is suspended

    Wait                     60
    Set timestamp            suspend_start
    Wait                     240
    Set timestamp            suspend_end

    Wake up device

    Connect
    Generate power plot      ${BUILD_ID}   ${TEST NAME}
    Stop recording power
    Check power during suspension          ${BUILD_ID}
    Switch to vm             ${GUI_VM}   user=${USER_LOGIN}
    Check the screen state   off
    # Screen wakeup requires a mouse move
    Move Cursor
    Check the screen state   on
    ${locked}                Check if locked
    Should Be True           ${locked}    Lock screen didn't appear

    # Power level comparison in the same login gui state as in the beginning
    # Applied only if power measurement agent is available in the setup
    IF  $SSH_MEASUREMENT!='${EMPTY}'
        Unlock
        Verify desktop availability
        Wait                     120
        Set timestamp            after_suspend_start
        Wait                     60
        Set timestamp            after_suspend_end

        Generate power plot      ${BUILD_ID}   ${TEST NAME}
        Stop recording power

        ${suspended_power}       Check power during suspension   ${BUILD_ID}   2500
        ${power_changed}         Measure power level change  ${BUILD_ID}  25  ${before_suspend_start}  ${before_suspend_end}  ${after_suspend_start}  ${after_suspend_end}
        IF  ${suspended_power}!=${False} or ${power_changed}!=${False}
            FAIL  Average suspended power ${suspended_power}mW (test limit 2500mW)\nPower consumption level increased ${power_changed}% over suspension and wake up (test limit 25%)
        END
    END

Automatic lock (Darter Pro)
    [Documentation]   Suspension is disabled on Darter Pro but automatic lock works
    ...               Wait and check that
    ...               in the beginning brightness is 100 %
    ...               in 4 min - the screen dims (brightness is 25 %)
    ...               in 5 min - the screen locks (brightness is 25 %)
    [Tags]            SP-T269    darter-pro
    [Setup]           Test setup

    Check the screen state   on
    Check screen brightness  ${max_brightness}

    Wait     240
    Check screen brightness  ${dimmed_brightness}

    Wait     10

    Check the screen state   on
    Wait    50
    ${locked}         Check if locked
    Should Be True    ${locked}

*** Keywords ***

Test setup
    Start swayidle
    Get expected brightness values
    Set display to max brightness
    Move cursor

Test teardown
    Run Keyword If Test Failed    Reboot Laptop

Wait
    [Arguments]     ${sec}
    ${time}         Get Time
    Log             ${time}: waiting for ${sec} sec  console=True
    Sleep           ${sec}

Get expected brightness values
    ${device}     Execute Command    ls /sys/class/backlight/
    ${max}        Execute Command    cat /sys/class/backlight/${device}/max_brightness
    Set Test Variable  ${max_brightness}     ${max}
    Log                Max brightness value is ${max}  console=True
    ${int_max}         Convert To Integer    ${max}
    ${dimmed}          Evaluate   __import__('math').ceil(${int_max} / 4)
    Log                Dimmed brightness is expected to be ~${dimmed}  console=True
    Set Test Variable  ${dimmed_brightness}  ${dimmed}

Set display to max brightness
    [Setup]   Switch to vm    ${GUI_VM}
    ${current_brightness}    Get screen brightness   log_brightness=False
    IF   ${current_brightness} != ${max_brightness}
        Log           Brightness is ${current_brightness}, setting it to the maximum  console=True
        ${output}     Execute Command    ls /nix/store | grep brightnessctl | grep -v .drv
        ${output}     Execute Command    /nix/store/${output}/bin/brightnessctl set 100%   sudo=True  sudo_password=${PASSWORD}
        ${current_brightness}    Get screen brightness
        Should be Equal As Numbers    ${current_brightness}   ${max_brightness}
    END
    [Teardown]   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}

Check screen brightness
    [Arguments]       ${brightness}    ${timeout}=60
    # 10 second timeout should be enough, but for some reason sometimes dimming the screen takes longer.
    # To prevent unnecessary fails timeout has been increased.
    FOR  ${i}  IN RANGE  ${timeout}
        ${output}     Get screen brightness  log_brightness=False
        Log           Check ${i}: Brightness is ${output}  console=True
        ${status}     Run Keyword And Return Status  Should be Equal As Numbers   ${output}  ${brightness}
        IF  ${status}
            BREAK
        ELSE
            Sleep    1
        END
    END
    IF  ${status} == False    FAIL    The screen brightness is ${output}, expected ${brightness}

Check the screen state
    [Arguments]         ${state}
    ${output}           Execute Command    ls /nix/store | grep wlopm | grep -v .drv
    ${output}  ${err}   Execute Command    WAYLAND_DISPLAY=wayland-1 /nix/store/${output}/bin/wlopm    return_stderr=True
    Log                 Screen state: ${output}  console=True
    Should Contain      ${output}    ${state}

Check that device is suspended
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  2x  ${PING_SPACING}s  Check If Ping Fails
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
