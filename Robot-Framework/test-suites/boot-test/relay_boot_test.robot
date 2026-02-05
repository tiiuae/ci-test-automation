# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device booting up.
Test Tags           ssh_boot_test

Library             ../../lib/output_parser.py
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Teardown      Teardown


*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False
${DEVICE_TYPE}           ${EMPTY}


*** Test Cases ***

Verify booting after restart by power
    [Documentation]    Restart device by power and verify init service is running
    [Tags]             relayboot  orin-agx  orin-agx-64  orin-nx
    Reboot Device Via Relay
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
    [Teardown]   Test Teardown

Verify booting laptop
    [Documentation]    Restart the laptop by power and verify init service is running
    [Tags]             SP-T287  SP-T290  relayboot  lenovo-x1  darter-pro  dell-7330
    Reboot Laptop      verify_shutdown=False
    IF    "installer" in "${JOB}"
        Check If Device Is Up    range=240
    ELSE
        Check If Device Is Up
    END
    IF    ${IS_AVAILABLE} == False
        Log To Console    Turning device on again...
        Turn Laptop On
        Check If Device Is Up
    END
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    IF  "${CONNECTION_TYPE}" == "ssh"
        Switch to vm    ${HOST}
        Verify service status   service=init.scope
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Verify init.scope status via serial
    END
    [Teardown]   Test Teardown

Turn OFF Device
    [Documentation]   Turn off device
    [Tags]            relay-turnoff
    [Setup]     Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    Log To Console    ${\n}Turning device off...
    IF  ${IS_LAPTOP}
        Press Button      ${SWITCH_BOT}-OFF
    ELSE
        Turn Relay Off    ${RELAY_NUMBER}
    END
    ${device_not_available}  Run Keyword And Return Status  Wait Until Keyword Succeeds  30s  2s  Check If Ping Fails
    IF  ${device_not_available} == True
        Log To Console    Device is down
    ELSE
        Log To Console    Device is UP after the end of the test.
    END

Turn ON Device
    [Documentation]   Turn on device
    [Tags]            relay-turnon
    Log To Console    ${\n}Turning device on...
    IF  ${IS_LAPTOP}
        Press Button      ${SWITCH_BOT}-ON
    ELSE
        Turn Relay On     ${RELAY_NUMBER}
    END
    Sleep    5
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Log    The device is available only via serial.     level=WARN
    ELSE
        Log To Console  The device started
    END

Run installer
    [Documentation]   Reboot laptop and run installer, will not turn off after test, boot test is required after this
    [Tags]            installer  lenovo-x1  darter-pro
    Reboot Laptop     verify_shutdown=False
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        Log To Console    Turning device on again...
        Turn Laptop On
        Check If Device Is Up
    END
    Run Keyword If    ${IS_AVAILABLE} == False   FAIL    The device did not start

    IF  "${CONNECTION_TYPE}" == "ssh"
        Connect           target=@ghaf-installer
        Run ghaf-installer
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    SSH is not available and running installer via serial is not supported by test.
    END


Wipe installed Ghaf from internal memory
    [Documentation]   Turn on device and wipe internal memory using ghaf-installer
    [Tags]            wiping  lenovo-x1  darter-pro
    Log To Console    ${\n}Turning device on...
    Turn Laptop On
    Check If Device Is Up   range=60
    Run Keyword If    ${IS_AVAILABLE} == False   FAIL    The device did not start

    IF  "${CONNECTION_TYPE}" == "ssh"
        Connect           target=@ghaf-installer
        Wipe system with ghaf-installer    ${device}
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    SSH is not available and running installer via serial is not supported by test.
    END

Break the system
    [Documentation]   Wipe boot partition
    [Tags]            break  darter-pro
    Switch to vm      ${HOST}
    Run Command       dd if=/dev/zero of=/dev/nvme0n1p2 count=100 bs=32M    sudo=True    rc_match=skip


*** Keywords ***

Test Teardown
    IF  ${IS_AVAILABLE}
        IF  "${CONNECTION_TYPE}" == "ssh"
            Run Keyword If Test Failed    ssh_keywords.Save log
        ELSE IF  "${CONNECTION_TYPE}" == "serial"
            Run Keyword If Test Failed    serial_keywords.Save log
        END
    END

Teardown
    Close All Connections
    Delete All Ports
    Close Relay Board Connection

Run ghaf-installer
    Write             sudo ghaf-installer -e
    ${output} 	      SSHLibrary.Read Until 	]:
    Should Contain 	  ${output}    Device name
    ${device}         Extract Device Hint    ${output}
    Write             ${device}
    ${output}  	      SSHLibrary.Read Until    [y/N]
    Should Contain 	  ${output}    Do you want to continue? [y/N]
    Write             y
    Log To Console    Start installation
    FOR    ${i}    IN RANGE    20
        ${output}     SSHLibrary.Read
        ${found}      Run Keyword And Return Status    Should Contain    ${output}    Installation done. Please remove the installation media and reboot
        Run Keyword If    ${found}    Exit For Loop
        Sleep    5s
    END
    Should Contain    ${output}    Installation done.
    Log To Console    Installation done.

Wipe system with ghaf-installer
    [Arguments]       ${device}
    Write             sudo ghaf-installer -w
    ${output} 	      SSHLibrary.Read Until 	]:
    Should Contain 	  ${output}    Device name
    ${device}         Extract Device Hint    ${output}
    Write             ${device}
    ${output}  	      SSHLibrary.Read Until    [y/N]
    Should Contain 	  ${output}    Do you want to continue? [y/N]
    Write             y
    Log To Console    Start wiping
    FOR    ${i}    IN RANGE    20
        ${output}     SSHLibrary.Read
        ${found}      Run Keyword And Return Status    Should Contain    ${output}    Wipe done.
        Run Keyword If    ${found}    Exit For Loop
        Sleep    5s
    END
    Write             echo $?
    ${raw}            Read Until Prompt
    ${rc}             Evaluate    [s for s in """${raw}""".splitlines() if s.strip().isdigit()][-1]
    Should Be Equal As Integers    ${rc}   0    Wiping was not successful
