# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/PlugLibrary/PlugLibrary.py  ${PLUG_TYPE}
Library             ../lib/SwitchbotLibrary.py  ${SWITCH_TOKEN}  ${SWITCH_SECRET}


*** Keywords ***

Reboot Device
    [Arguments]       ${delay}=5
    [Documentation]   Turn off power of device, wait for given amount of seconds and turn on the power
    Log To Console    ${\n}Turning device off...
    Turn Plug Off
    Sleep    ${delay}
    Log To Console    Turning device on...
    Turn Plug On

Reboot Device Via Relay
    [Arguments]       ${delay}=5
    [Documentation]   Turn off power of device, wait for given amount of seconds and turn on the power
    # Open Relay Serial Port    ${RELAY_SERIAL_PORT}
    Log To Console    ${\n}Turning device off...
    Turn Relay Off    ${RELAY_NUMBER}
    Sleep    ${delay}
    Log To Console    Turning device on...
    Turn Relay On     ${RELAY_NUMBER}

Reboot Laptop
    [Arguments]       ${delay}=15
    [Documentation]   Turn off the laptop by pressing power button for 10 sec turn on by short pressing power button
    IF  "${DEVICE_TYPE}" == "lenovo-x1" or "${DEVICE_TYPE}" == "darter-pro" or "${DEVICE_TYPE}" == "x1-sec-boot"
        ${delay}      Set variable    20
    END
    Log To Console    ${\n}Turning device off...
    Press Button      ${SWITCH_BOT}-OFF
    Sleep    ${delay}
    Log To Console    Turning device on...
    Press Button      ${SWITCH_BOT}-ON

Turn Laptop On and Connect
    Log To Console    ${\n}Turning device on...
    Press Button      ${SWITCH_BOT}-ON
    Sleep    5
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    The device is available only via serial, but tests require SSH.
    ELSE
        Log To Console  The device started
    END
    Sleep   30
    Connect    iterations=10

Soft Reboot Device
    [Documentation]  Reboot device from ${vm}
    [Arguments]      ${vm}=${HOST}
    ${device_is_available}   Ping Host   ${DEVICE_IP_ADDRESS}
    IF  ${device_is_available}
        Switch to vm   ${vm}
        Run Command  reboot  sudo=True
        Log To Console  Rebooting device from command line
    ELSE
        FAIL    Device expected to be available but not responding.
    END

Verify Reboot and Connect
    [Documentation]   Verify that device rebooted and connect
    Verify Laptop Shutdown
    # Sleep extended from 20 to 30 due to SSRCSP-7512
    Sleep   30
    Check If Device Is Up         range=60
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did shut down but didn't start in reboot.
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    The device is available only via serial, but tests require SSH.
    ELSE
        Log To Console            Device started
    END
    Sleep   30
    Connect    iterations=10

Wake up device
    Log To Console    Pressing the power button...
    Press Button      ${SWITCH_BOT}-ON
    Check If Device Is Up    range=30
    IF    ${IS_AVAILABLE} == False
        FAIL             The device did suspend but failed to wake up
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    The device is available only via serial, but tests require SSH.
    ELSE
        Log To Console   Device successfully woke up after suspend
    END

Verify Laptop Shutdown
    [Arguments]      ${timeout}=30
    ${device_not_available}    Run Keyword And Return Status  Wait Until Keyword Succeeds  ${timeout}s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console            Device is down
    ELSE
        FAIL                      Device didn't shut down
    END