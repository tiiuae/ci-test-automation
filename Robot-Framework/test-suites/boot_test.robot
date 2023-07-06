# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
Library             ../lib/TapoP100/tapo_p100.py
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

Test ghaf version format
    [Documentation]    Test getting Ghaf version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash
    [Tags]             bat   SP-T59
    [Setup]     Connect
    Verify Ghaf Version Format
    [Teardown]  Close All Connections

Test nixos version format
    [Documentation]    Test getting Nixos version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash (name)
    [Tags]             bat   SP-T60
    [Setup]     Connect
    Verify Nixos Version Format
    [Teardown]  Close All Connections


*** Keywords ***

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
