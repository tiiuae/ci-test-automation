# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing files sharing among VMs
Force Tags          shares  bat  SP-T198  lenovo-x1  dell-7330
Resource            ../../resources/ssh_keywords.resource
Test Template       File sharing test
Suite Setup         Shares setup
Suite Teardown      Close All Connections

*** Test Cases ***

File sharing from Chrome-VM to Business-VM
    ${CHROME_VM}    ${BUSINESS_VM}

File sharing from Chrome-VM to Comms-VM
    ${CHROME_VM}    ${COMMS_VM}

File sharing from Comms-VM to Business-VM
    ${COMMS_VM}     ${BUSINESS_VM}

File sharing from Comms-VM to Chrome-VM
    ${COMMS_VM}     ${CHROME_VM}

File sharing from Business-VM to Comms-VM
    ${BUSINESS_VM}  ${COMMS_VM}

File sharing from Business-VM to Chrome-VM
    ${BUSINESS_VM}  ${CHROME_VM}

*** Keywords ***

File sharing test
    [Documentation]
    [Arguments]    ${vm1}    ${vm2}
    Set Test Variable  ${vm1_in_guivm}    /Shares/'Unsafe ${vm1} share'
    Set Test Variable  ${vm2_in_guivm}    /Shares/'Unsafe ${vm2} share'
    Connect to VM      ${vm1}
    Create file        ${path_in_vm}/${file_name}
    Connect to VM      ${GUI_VM}
    Copy file          ${vm1_in_guivm}/${file_name}    ${vm2_in_guivm}/${file_name}
    Connect to VM      ${vm2}
    Check file exists  ${path_in_vm}/${file_name}
    [Teardown]         Run Keywords
    ...                Remove the file in VM    ${path_in_vm}/${file_name}    ${vm1}    AND
    ...                Remove the file in VM    ${path_in_vm}/${file_name}    ${vm2}

Shares setup
    Set Suite Variable     ${path_in_vm}         /home/appuser/'Unsafe share'
    Set Suite Variable     ${file_name}          test.txt
    Connect

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}
    Connect to VM      ${vm}
    Remove file        ${file_name}
    Check file doesn't exist    ${file_name}