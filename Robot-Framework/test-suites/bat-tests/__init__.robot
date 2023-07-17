# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
#Documentation
#Force Tags
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
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
    Log                 Ghaf version: ${ghaf_version}
    ${nixos_version}    Execute Command   nixos-version
    Log                 Nixos version: ${nixos_version}
