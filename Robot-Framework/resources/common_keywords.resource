# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Resource            ../resources/gui_keywords.resource


*** Keywords ***

Check that the application was started
    [Arguments]          ${app_name}  ${range}=2
    FOR   ${i}   IN RANGE  ${range}
        @{found_pids}        Find pid by name    ${app_name}
        Set Global Variable  @{APP_PIDS}  @{found_pids}
        ${status}    Run Keyword And Return Status   Should Not Be Empty  ${APP_PIDS}
        IF    ${status}    BREAK
        Sleep   1
    END
    Should Not Be Empty  ${APP_PIDS}  ${app_name} is not started
    Log To Console       ${app_name} is started

Check that the application is not running
    [Arguments]          ${app_name}  ${range}=2
    ${pids}=  Set Variable  ${EMPTY}
    FOR   ${i}   IN RANGE  ${range}
        ${keyword_status}  ${pids}  Run Keyword And Ignore Error   Find pid by name    ${app_name}
        Set Global Variable  @{APP_PIDS}  @{pids}
        ${status}    Run Keyword And Return Status   Should Be Empty  ${pids}
        IF    ${status}    BREAK
        Sleep   1
    END
    Should Be Empty   ${pids}   ${app_name} is still running
    Log To Console    ${app_name} not running

Check If Ping Fails
    [Documentation]  Check that ping is not getting response from host
    ${result}  Run Process  ping  ${DEVICE_IP_ADDRESS}  -c1  timeout=1s
    Should Not Be Equal   ${result.rc}  ${0}

Run journalctl recording
    ${output}     Execute Command    nohup journalctl -f >> /tmp/jrnl.txt 2>&1 &

Log journctl
    ${jrnl_size}    Execute Command    ls -lh /tmp/jrnl.txt
    Log           ${jrnl_size}
    ${jrnl}       Execute Command    cat /tmp/jrnl.txt   timeout=10
    Log           ${jrnl}
    @{pid}        Find pid by name   journalctl
    Kill process  @{pid}

Check If Device Is Up
    [Arguments]    ${range}=20
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

    IF  ${IS_AVAILABLE}    Log To Console    Device woke up after ${diff} sec.

    IF  ${IS_AVAILABLE} == False
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END

Log versions
    ${ghaf_version}     Execute Command   ghaf-version
    Log to console      Ghaf version: ${ghaf_version}
    ${nixos_version}    Execute Command   nixos-version
    Log to console      Nixos version: ${nixos_version}
