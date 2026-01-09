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
    Sleep             ${delay}    # needed because Pressing OFF button takes up to 15 sec
    Wait Until Device Is Down
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
    Switch to vm    ${NET_VM}

Soft Reboot Device
    [Documentation]  Reboot device from ${vm}
    [Arguments]      ${vm}=${HOST}
    ${device_is_available}   Ping Host   ${DEVICE_IP_ADDRESS}
    IF  ${device_is_available}
        Switch to vm   ${vm}
        Run Command  reboot  sudo=True   rc_match=skip
        Log To Console  Rebooting device from command line
    ELSE
        FAIL    Device expected to be available but not responding.
    END

Connect After Reboot
    [Documentation]   Verify that device rebooted and connect
    # Sleep extended from 20 to 30 due to SSRCSP-7512
    Sleep   30
    Check If Device Is Up         range=60
    IF    ${IS_AVAILABLE} == False
        FAIL                      The device did shut down but didn't start in reboot.
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    The device is available only via serial, but tests require SSH.
    ELSE
        Log To Console            Device started
        Switch to vm    ${NET_VM}
    END

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

Wait Until Device Is Down
    [Documentation]    Check ping and port 22 until device stops responding both.
    ...                "Connection refused" is NOT considered as powered off.
    [Arguments]       ${timeout}=60
    FOR    ${i}    IN RANGE    ${timeout}
        ${nc}     Run Process    nc    -zvw1    ${DEVICE_IP_ADDRESS}    22    stderr=STDOUT    shell=False
        Log       rc ${nc.rc} \n${nc.stdout}
        ${ping}    Run Process  ping  ${DEVICE_IP_ADDRESS}  -c1  -W  1  timeout=1s
        Log       rc ${ping.rc} \n${ping.stdout}

        IF    ${ping.rc} != 0 and 'Connection timed out' in '''${nc.stdout}'''
            Log    Device at ${DEVICE_IP_ADDRESS} powered off
            RETURN
        END
        Sleep    1s
    END
    Fail    Device at ${DEVICE_IP_ADDRESS} still responds after 60 seconds.

Check that device is suspended
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console  Device is suspended
    ELSE
        Log To Console  Device is available
        FAIL    Device failed to suspend.
    END
