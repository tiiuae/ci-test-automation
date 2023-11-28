# SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing for GuiVM
Force Tags          guivm
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Teardown      Close All Connections


*** Test Cases ***

Waypipe SSH Public Key can be used to connect to Chromium VM
    [Documentation]   Connect to GuiVM and try to connect to Chromium AppVM
    ...               from there using Waypipe SSH key.
    [Tags]            bat   SP-T666   lenovoX1
    [Setup]           Run Keywords
    ...               Connect to ghaf host  AND  Connect to netvm  AND  Connect to guivm
    Log To Console   Connecting to Chromium VM
    ${cmd}=    Set Variable    ssh -o StrictHostKeyChecking=no -i /run/waypipe-ssh/id_ed25519 ${CHROMIUM_VM} "exit 0"
    ${stdout}    ${rc}=    Execute Command    ${cmd}    return_rc=True
    Should Be Equal As Integers    0    ${rc}
    [Teardown]    Close All Connections
