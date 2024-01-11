# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       To be executed only for BAT tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    Connect
    Log versions
    Run journalctl recording

Common Teardown
    Connect
    Log journctl
    Close All Connections

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
