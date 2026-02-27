# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device booting up.
Test Tags           ssh_boot_test

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource


*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False
${DEVICE_TYPE}           ${EMPTY}


*** Test Cases ***

Verify booting after restart by power
    [Documentation]    Restart device by power and verify init service is running
    [Tags]             boot  plug  orin-agx  orin-agx-64  orin-nx
    Reboot Device
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    IF  not ${IS_LAPTOP}
        Sleep  30
    END
    IF  "${CONNECTION_TYPE}" == "ssh"
        Switch to vm    ${HOST}
        Verify service status   service=init.scope
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Verify init.scope status via serial
    END
    [Teardown]   Teardown

Verify booting laptop
    [Documentation]    Restart laptop by power and verify init service is running
    [Tags]             boot  plug  lenovo-x1  darter-pro  dell-7330
    Reboot Laptop      verify_shutdown=False
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    Switch to vm   ${HOST}
    Verify service status   service=init.scope
    [Teardown]   Teardown

Turn OFF Device
    [Documentation]   Turn off device
    [Tags]            turnoff
    [Setup]     Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    Log To Console    ${\n}Turning device off...
    IF  ${IS_LAPTOP}
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
    IF  ${IS_LAPTOP}
        Press Button      ${SWITCH_BOT}-ON
    ELSE
        Turn Plug On
    END
    Sleep    5
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE
        Log To Console  The device started
    END


*** Keywords ***

Teardown
    IF  ${IS_AVAILABLE}
        IF  "${CONNECTION_TYPE}" == "ssh"
            Run Keyword If Test Failed    ssh_keywords.Save log
        ELSE IF  "${CONNECTION_TYPE}" == "serial"
            Run Keyword If Test Failed    serial_keywords.Save log
        END
    END
    Close All Connections
    Delete All Ports
