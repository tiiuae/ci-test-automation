# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
# PlugLibrary Usage:
# * Tapo Plug:
#   -v PLUG_TYPE:TAPOP100 (default, needs SOCKET_IP_ADDRESS, PLUG_USERNAME and
#   			   PLUG_PASSWORD)
# * Kasa Plug:
#   -v PLUG_TYPE:KASAPLUG (needs only SOCKET_IP_ADDRESS)
#
Library             ../lib/PlugLibrary/PlugLibrary.py
Resource            ../resources/serial_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}

*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False

*** Test Cases ***

Verify booting after restart by power
    [Documentation]    Restart device by power and verify systemctl status is running
    [Tags]             boot  plug
    Reboot Device
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    IF  "${CONNECTION_TYPE}" == "ssh"
        Verify Systemctl status
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Verify Systemctl status via serial
    END
    [Teardown]   Teardown


*** Keywords ***

Teardown
    IF  "${CONNECTION_TYPE}" == "ssh"
        Run Keyword If Test Failed    ssh_keywords.Save log
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Run Keyword If Test Failed    serial_keywords.Save log
    END
    Close All Connections
    Delete All Ports

Check If Device Is Up
    [Arguments]    ${range}=20
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}
            Set Global Variable    ${IS_AVAILABLE}       True
            BREAK
        END
    END
    ${diff}=    Evaluate    int(time.time()) - int(${start_time})

    IF  ${IS_AVAILABLE}    Log To Console    Device woke up after ${diff} sec.

    IF    ${ping}==False
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END

Reboot Device
    [Arguments]    ${delay}=5
    [Documentation]    Turn off power of devicee, wait for given amount of seconds and turn on the power
    Log To Console    ${\n}Turning device off...
    Turn Plug Off
    Sleep    ${delay}
    Log To Console    Turning device on...
    Turn Plug On
