# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource


*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False
${DEVICE_TYPE}           ${EMPTY}


*** Test Cases ***

Verify booting after restart by power
    [Documentation]    Restart device by power and verify init service is running
    [Tags]             boot  plug  nuc  orin-agx  orin-nx
    Reboot Device
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    IF  "${CONNECTION_TYPE}" == "ssh"
        Connect
        Verify service status   service=init.scope
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Verify init.scope status via serial
    END
    [Teardown]   Teardown

Verify booting LenovoX1
    [Documentation]    Restart LenovoX1 by power and verify init service is running
    [Tags]             boot  plug  lenovo-x1
    Reboot LenovoX1
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END

    Connect
    Verify service status   service=init.scope

    [Teardown]   Teardown

Verify booting RiscV Polarfire
    [Documentation]    Restart RiscV by power and verify init service is running using serial connection
    [Tags]             boot  plug  riscv
    Reboot Device
    Sleep   60    # immediate attempt to connect via the serial port may interrupt the normal startup of the Ghaf system
    Check Serial Connection
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    Verify init.scope status via serial
    [Teardown]   Teardown

Turn OFF Device
    [Documentation]   Turn off device
    [Tags]            turnoff
    [Setup]     Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    Log To Console    ${\n}Turning device off...
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        Press Button      ${SWITCH_BOT}-OFF
    ELSE
        Turn Plug Off
    END
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console    Device is down
    ELSE
        Log To Console    Device is UP after the end of the test.
        FAIL    Device is UP after the end of the test
    END

Turn ON Device
    [Documentation]   Turn on device
    [Tags]            turnon
    Log To Console    ${\n}Turning device on...
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        Press Button      ${SWITCH_BOT}-ON
    ELSE
        Turn Plug On
    END
    Sleep    5
    IF  "${DEVICE_TYPE}" == "riscv"
        Sleep   60    # immediate attempt to connect via the serial port may interrupt the normal startup of the Ghaf system
        Check Serial Connection
    ELSE
        Check If Device Is Up
    END
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE
        Log To Console  The device started
    END


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
    Set Global Variable    ${IS_AVAILABLE}       False
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}
            Log To Console    Ping ${DEVICE_IP_ADDRESS} successfull
            BREAK
        END
        Sleep  1
    END

    IF    ${ping}
        ${port_22_is_available}     Check if ssh is ready on device
        IF  ${port_22_is_available}
            Set Global Variable    ${IS_AVAILABLE}       True
        ELSE
            Set Global Variable    ${IS_AVAILABLE}       False
        END
    END

    ${diff}=    Evaluate    int(time.time()) - int(${start_time})

    IF  ${IS_AVAILABLE}    Log To Console    Device woke up after ${diff} sec.

    IF  ${IS_AVAILABLE} == False
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END



