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
Suite Teardown      Teardown


*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False
${DEVICE_TYPE}           ${EMPTY}


*** Test Cases ***

Verify booting after restart by power
    [Documentation]    Restart device by power and verify init service is running
    [Tags]             relayboot  plug  nuc  orin-agx  orin-nx
    Reboot Device Via Relay
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
    [Teardown]   Test Teardown

Verify booting LenovoX1
    [Documentation]    Restart LenovoX1 by power and verify init service is running
    [Tags]             relayboot  plug  lenovo-x1
    Reboot LenovoX1
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END

    Connect
    Verify service status   service=init.scope
    [Teardown]   Test Teardown

Verify booting RiscV Polarfire
    [Documentation]    Restart RiscV by power and verify init service is running using serial connection
    [Tags]             relayboot  plug  riscv
    Reboot Device Via Relay
    Sleep   60    # immediate attempt to connect via the serial port may interrupt the normal startup of the Ghaf system
    Check Serial Connection
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    Verify init.scope status via serial
    [Teardown]   Test Teardown

Turn OFF Device
    [Documentation]   Turn off device
    [Tags]            relay-turnoff
    [Setup]     Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    Log To Console    ${\n}Turning device off...
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        Press Button      ${SWITCH_BOT}-OFF
    ELSE
        Turn Relay Off    ${RELAY_NUMBER}
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
    [Tags]            relay-turnon
    Log To Console    ${\n}Turning device on...
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        Press Button      ${SWITCH_BOT}-ON
    ELSE
        Turn Relay On     ${RELAY_NUMBER}
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

Test Teardown
    IF  "${CONNECTION_TYPE}" == "ssh"
        Run Keyword If Test Failed    ssh_keywords.Save log
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Run Keyword If Test Failed    serial_keywords.Save log
    END

Teardown
    Close All Connections
    Delete All Ports
    Close Relay Board Connection
