# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Setup of BAT tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Suite Setup         Bat Tests Setup
Suite Teardown      Bat Tests Teardown

*** Variables ***

${DEVICE}         ${EMPTY}
#${SWITCH_TOKEN}   ${EMPTY}
#${SWITCH_SECRET}  ${EMPTY}
#${DEVICE_TYPE}    ${EMPTY}

*** Keywords ***

Bat Tests Setup
    Set Variables   ${DEVICE}
    Turn On Device
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    Check If Device Is Up
    Connect
    Verify service status   service=init.scope
    Log versions
    Run journalctl recording

Bat Tests Teardown
    Connect
    Log journctl
    Close All Connections
    Turn off device

Run journalctl recording
    ${output}     Execute Command    journalctl > jrnl.txt
    ${output}     Execute Command    nohup journalctl -f >> jrnl.txt 2>&1 &

Log journctl
    ${output}     Execute Command    cat jrnl.txt
    Log           ${output}
    @{pid}        Find pid by name   journalctl
    Kill process  @{pid}

Log versions
    ${ghaf_version}     Execute Command   ghaf-version
    Log to console      Ghaf version: ${ghaf_version}
    ${nixos_version}    Execute Command   nixos-version
    Log to console      Nixos version: ${nixos_version}
