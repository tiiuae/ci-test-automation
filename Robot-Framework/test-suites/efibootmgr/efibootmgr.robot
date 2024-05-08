# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Removing Linux Boot Manager entries from UEFI boot order.
Force Tags          efiboot-mod
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../config/variables.robot


*** Variables ***
${CONNECTION_TYPE}       ssh
${IS_AVAILABLE}          False
${DEVICE_TYPE}           ${EMPTY}
${ENTRIES}

*** Test Cases ***

Remove Linux Boot Manager entries
    [Documentation]    Remove all Linux Boot Manager entries from UEFI boot order list
    [Tags]             lenovo-x1  efiboot-mod

    Check If Device Is Up
    IF    ${IS_AVAILABLE} == False
        FAIL    Cannot modify the UEFI boot order
    ELSE
        Log To Console  Connecting to ghaf-host
    END

    Connect
    Put File           efibootmgr/efiboot_mod_script    /home/ghaf
    Execute Command    chmod 777 efiboot_mod_script sudo=True  sudo_password=${PASSWORD}
    Log To Console  Deleting all 'Linux' entries from UEFI boot order with efibootmgr
    Execute Command    ./efiboot_mod_script  sudo=True  sudo_password=${PASSWORD}
    ${ENTRIES}            Execute Command    efibootmgr | grep Linux
    Log To Console    efibootmgr check after removing Linux Boot Manager entries: \n${ENTRIES}
    IF    "${ENTRIES}" != ""
        FAIL    Failed in removing all Linux Boot Manager entries
    ELSE
        Log To Console  All Linux Boot Manager entries cleared
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
    [Arguments]    ${range}=5
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

    IF  ${IS_AVAILABLE}    Log To Console    Device ssh port available.

    IF  ${IS_AVAILABLE} == False
        Log To Console    Device is not available!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END
