# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/output_parser.py
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Keywords ***

Start XDG application
    [Arguments]      ${app_name}  ${gui_vm_app}=false
    Log To Console   ${\n}Starting ${app_name}
    ${app_name}      Check application name  ${app_name}
    ${output}        Execute Command    cat /run/current-system/sw/share/applications/${app_name}.desktop
    ${path}          Get App Path From Desktop  ${output}
    IF  $gui_vm_app
        Execute Command  nohup sh -c 'WAYLAND_DISPLAY=wayland-1 ${path}' > output.log 2>&1 &
    ELSE
        Execute Command  nohup sh -c '${path}' > output.log 2>&1 &
    END

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

Launch Cosmic Term
    Start XDG application   com.system76.CosmicTerm  gui_vm_app=true
    Check that the application was started    cosmic-term  exact_match=true

Log and remove app output
    [Documentation]    Specify the VM from which the app was started and the user (the owner of the file)
    [Arguments]   ${file}    ${vm}    ${user}=ghaf
    Switch to vm  ${vm}    ${user}
    ${output}     Execute Command    cat ${file}
    Log           ${output}
    Remove file   ${file}    user=${user}

Log app vm journalctl
    [Documentation]    Specify the VM where the App is actually running
    [Arguments]   ${vm}
    Switch to vm  ${vm}
    ${output}     Execute Command    journalctl
    Log           ${output}

Get Falcon LLM Name
    ${output}            Execute Command     cat '/run/current-system/sw/share/applications/Falcon AI.desktop'
    ${line}              Get Lines Containing String  ${output}  Exec=
    ${path}              Set Variable  ${line[5:]}
    ${llm_name_raw}      Execute Command  cat ${path} | grep LLM_NAME | head -n 1
    # LLM_NAME="falcon3:10b" -> falcon3:10b
    ${tmp}               Fetch From Right  ${llm_name_raw}  =
    ${LLM_NAME}          Set Variable  ${tmp[1:-1]}
    Set Global Variable  ${LLM_NAME}

Check application name
    [Documentation]  Check written format of application
    [Arguments]  ${app_name}
    ${app_name}  Strip String  ${app_name}  characters="'
    ${output}    Execute Command    ls /run/current-system/sw/share/applications/
    ${app}       Get Regexp Matches  ${output}  (?im)${app_name}
    RETURN  '${app}[0]'
