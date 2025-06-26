# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Resource            ../resources/gui_keywords.resource
Resource            ../resources/connection_keywords.resource
Library             ../lib/output_parser.py


*** Keywords ***

Prepare Test Environment
    [Arguments]    ${stop_swayidle}=True   ${enable_dnd}=False
    Initialize Variables And Connect
    Log versions
    Run journalctl recording

    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Switch to gui-vm as ghaf
        Set compositor
        Save most common icons and paths to icons
        Create test user
        Start ydotoold
        Log in, unlock and verify   ${stop_swayidle}   ${enable_dnd}
    END

Clean Up Test Environment
    [Arguments]   ${disable_dnd}=False
    Connect to ghaf host
    Log journalctl
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Switch to gui-vm as ghaf
        Start ydotoold
        Log out and verify   ${disable_dnd}
        Stop ydotoold
    END
    Close All Connections

Check that the application was started
    [Arguments]          ${app_name}  ${range}=2  ${exact_match}=false
    FOR   ${i}   IN RANGE  ${range}
        @{found_pids}        Find pid by name    ${app_name}  ${exact_match}
        Set Global Variable  @{APP_PIDS}  @{found_pids}
        ${status}    Run Keyword And Return Status   Should Not Be Empty  ${APP_PIDS}
        IF    ${status}    BREAK
        Sleep   1
    END
    Should Not Be Empty  ${APP_PIDS}  ${app_name} is not started
    Log To Console       ${app_name} is started

Check that the application is not running
    [Arguments]          ${app_name}  ${range}=2  ${exact_match}=false
    ${pids}=  Set Variable  ${EMPTY}
    FOR   ${i}   IN RANGE  ${range}
        ${keyword_status}  ${pids}  Run Keyword And Ignore Error   Find pid by name    ${app_name}  ${exact_match}
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

Log journalctl
    ${jrnl_size}  Execute Command    ls -lh /tmp/jrnl.txt
    Log           ${jrnl_size}
    # Copy journal log file to Robot outputs
    SSHLibrary.Get file   /tmp/jrnl.txt   ${OUTPUT_DIR}/jrnl.txt
    OperatingSystem.File Should Exist     ${OUTPUT_DIR}/jrnl.txt
    @{pid}        Find pid by name   journalctl
    Kill process  @{pid}

Get user journalctl log
    [Arguments]   ${filename}
    Execute Command    journalctl --user > /tmp/${filename}
    SSHLibrary.Get file   /tmp/${filename}   ${OUTPUT_DIR}/${filename}
    OperatingSystem.File Should Exist     ${OUTPUT_DIR}/${filename}

Check If Device Is Up
    [Arguments]    ${range}=20
    Set Global Variable    ${IS_AVAILABLE}       False
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}
            Log To Console    Ping ${DEVICE_IP_ADDRESS} successful
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
    Log To Console      Ghaf version: ${ghaf_version}
    ${nixos_version}    Execute Command   nixos-version
    Log To Console      Nixos version: ${nixos_version}

Get mako path
    ${output}            Execute Command     ls /nix/store | grep mako | grep -v .drv
    ${result}            Extract mako path   ${output}
    Set Global Variable  ${MAKO_PATH}    ${result}

Get Falcon LLM Name
    ${output}            Execute Command     cat '/run/current-system/sw/share/applications/Falcon AI.desktop'
    ${line}              Get Lines Containing String  ${output}  Exec=
    ${path}              Set Variable  ${line[5:]}
    ${llm_name_raw}      Execute Command  cat ${path} | grep LLM_NAME | head -n 1
    # LLM_NAME="falcon3:10b" -> falcon3:10b
    ${tmp}               Fetch From Right  ${llm_name_raw}  =
    ${LLM_NAME}          Set Variable  ${tmp[1:-1]}
    Set Global Variable  ${LLM_NAME}
