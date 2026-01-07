# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing files sharing among VMs
Force Tags          SP-T198  shares  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Template       File sharing test
Suite Setup         Shares setup


*** Test Cases ***

File sharing from Chrome-VM to Business-VM
    [Tags]          regression
    ${CHROME_VM}    ${BUSINESS_VM}

File sharing from Chrome-VM to Comms-VM
    [Tags]          pre-merge  bat  regression
    ${CHROME_VM}    ${COMMS_VM}

File sharing from Comms-VM to Business-VM
    [Tags]          regression
    ${COMMS_VM}     ${BUSINESS_VM}

File sharing from Comms-VM to Chrome-VM
    [Tags]          regression
    ${COMMS_VM}     ${CHROME_VM}

File sharing from Business-VM to Comms-VM
    [Tags]          regression
    ${BUSINESS_VM}  ${COMMS_VM}

File sharing from Business-VM to Chrome-VM
    [Tags]          regression
    ${BUSINESS_VM}  ${CHROME_VM}

*** Keywords ***

File sharing test
    [Documentation]    Create file in the 'Unsafe share' folder on one VM, copy in GuiVM,
    ...                and check that file is available in the another VM
    [Arguments]        ${vm1}    ${vm2}
    Set Test Variable  ${vm1_in_guivm}    /Shares/'Unsafe ${vm1} share'
    Set Test Variable  ${vm2_in_guivm}    /Shares/'Unsafe ${vm2} share'
    Switch to vm       ${vm1}
    Create file        ${path_in_vm}/${file_name}   sudo=True
    Switch to vm       ${GUI_VM}   ${USER_LOGIN}
    Copy file          ${vm1_in_guivm}/${file_name}    ${vm2_in_guivm}/${file_name}
    Switch to vm       ${vm2}
    Check file exists  ${path_in_vm}/${file_name}   sudo=True
    [Teardown]         Run Keywords
    ...                Remove the file in VM    ${path_in_vm}/${file_name}    ${vm1}    AND
    ...                Remove the file in VM    ${path_in_vm}/${file_name}    ${vm2}

Shares setup
    Set Suite Variable     ${path_in_vm}         /home/appuser/'Unsafe share'
    Set Suite Variable     ${file_name}          test.txt
    Switch to vm           ${NET_VM}

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}
    Switch to vm       ${vm}
    Remove file        ${file_name}    sudo=True