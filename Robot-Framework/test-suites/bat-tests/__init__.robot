# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       BAT tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Suite Setup         Common Setup
Suite Teardown      Common Teardown

*** Variables ***

${connection}       ${NONE}

*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    ${port_22_is_available}     Check if ssh is ready on device   timeout=60
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    ${connection}       Connect
    Set Suite Variable  ${connection}
    Log versions
    Run journalctl recording

Common Teardown
    IF  ${connection}
        Connect
        Log journctl
    END
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
