# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test

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
    [Tags]             relayboot  plug  nuc  orin-agx  orin-agx-64  orin-nx
    Reboot Device Via Relay
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    IF  "NX" in "${DEVICE}" or "AGX" in "${DEVICE}"
        Sleep  30
    END
    IF  "${CONNECTION_TYPE}" == "ssh"
        Connect   iterations=10
        Verify service status   service=init.scope
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        Verify init.scope status via serial
    END
    [Teardown]   Test Teardown

Verify booting laptop
    [Documentation]    Restart the laptop by power and verify init service is running
    [Tags]             relayboot  plug  lenovo-x1  darter-pro  dell-7330
    Reboot Laptop
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        Log To Console    Turning device on again...
        Press Button      ${SWITCH_BOT}-ON
        Check If Device Is Up
    END
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END
    Sleep  30
    Connect   iterations=10
    Verify service status   service=init.scope
    [Teardown]   Test Teardown

Turn OFF Device
    [Documentation]   Turn off device
    [Tags]            relay-turnoff
    [Setup]     Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    Log To Console    ${\n}Turning device off...
    IF  "${DEVICE_TYPE}" == "lenovo-x1" or "${DEVICE_TYPE}" == "dell-7330" or "${DEVICE_TYPE}" == "darter-pro"
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
    IF  "${DEVICE_TYPE}" == "lenovo-x1" or "${DEVICE_TYPE}" == "dell-7330" or "${DEVICE_TYPE}" == "darter-pro"
        Press Button      ${SWITCH_BOT}-ON
    ELSE
        Turn Relay On     ${RELAY_NUMBER}
    END
    Sleep    5
    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL  The device did not start
    ELSE
        Log To Console  The device started
    END

Run installer
    [Documentation]   Turn on device and run installer, will not turn off after test, boot test is required after this
    [Tags]            installer  lenovo-x1
    Log To Console    ${\n}Turning device on...
    Press Button      ${SWITCH_BOT}-ON
    Check If Device Is Up
    Run Keyword If    ${IS_AVAILABLE} == False   FAIL    The device did not start
    Connect           target_output=@ghaf-installer
    Run ghaf-installer

Wipe installed Ghaf from internal memory
    [Documentation]   Turn on device and wipe internal memory using ghaf-installer or dd if installer fails
    [Tags]            wiping  lenovo-x1
    Log To Console    ${\n}Turning device on...
    Press Button      ${SWITCH_BOT}-ON
    Check If Device Is Up   range=60
    Run Keyword If    ${IS_AVAILABLE} == False   FAIL    The device did not start
    Connect           target_output=@ghaf-installer

    ${status}         Wipe system with ghaf-installer    ${device}
    IF  '${status}' != 'True'
        Log To Console         Wiping with ghaf-installer wasn't successful, trying wipe the system with 'dd'
        Wipe system with dd    ${device}
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

Run ghaf-installer
    Write             sudo ghaf-installer
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
    ${status}         Run Keyword And Return Status    Should Be Equal As Integers    ${rc}   0    Wiping was not successful
    RETURN    ${status}

Wipe system with dd
    [Arguments]           ${device}
    ${sector}             Set Variable    512     # Set sector size to 512 bytes
    ${mib_to_sectors}     Set Variable    20480   # 10 MiB in 512-byte sectors
    ${sectors}  ${err}  ${rc}     Execute Command    sudo blockdev --getsz ${device}   return_stderr=True   return_rc=True    # Disk size in 512-byte sectors
    Should Be Equal As Integers    ${rc}    0    ${err}
    # Wipe first 10MiB of disk
    ${out}  ${err}  ${rc}         Execute Command    sudo dd if=/dev/zero of=${device} bs=${sector} count=${mib_to_sectors} conv=fsync status=none   return_stderr=True   return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${err}
    # Wipe last 10MiB of disk
    ${last_offset}        Evaluate    int(${sectors}) - int(${mib_to_sectors})
    ${out}  ${err}  ${rc}         Execute Command    sudo dd if=/dev/zero of=${device} bs=${sector} count=${mib_to_sectors} seek=${last_offset}   return_stderr=True conv=fsync status=none   return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${err}
