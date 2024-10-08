# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot


*** Keywords ***

Check that the application was started
    [Arguments]          ${app_name}  ${range}=2
    FOR   ${i}   IN RANGE  ${range}
        @{found_pids}        Find pid by name    ${app_name}
        Set Global Variable  @{app_pids}  @{found_pids}
        ${status}    Run Keyword And Return Status   Should Not Be Empty  ${app_pids}
        IF    ${status}    BREAK
        Sleep   1
    END
    Should Not Be Empty  ${app_pids}  ${app_name} is not started
    Log To Console       ${app_name} is started

Check If Ping Fails
    [Documentation]  Check that ping is not getting response from host
    # ${out}   Run and Return RC   ping ${DEVICE_IP_ADDRESS} -c 1
    ${result}  Run Process  ping  ${DEVICE_IP_ADDRESS}  -c1  timeout=1s
    Should Not Be Equal   ${result.rc}  ${0}

Run journalctl recording
    ${output}     Execute Command    journalctl > jrnl.txt
    ${output}     Execute Command    nohup journalctl -f >> jrnl.txt 2>&1 &

Log journctl
    ${output}     Execute Command    cat jrnl.txt
    Log           ${output}
    @{pid}        Find pid by name   journalctl
    Kill process  @{pid}