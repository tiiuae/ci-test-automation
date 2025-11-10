# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/output_parser.py
Resource            ../resources/common_keywords.resource
Library             ../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/gui_keywords.resource


*** Variables ***
${APP_OUTPUT_FILE}   /home/${USER_LOGIN}/output.log
@{APP_PIDS}          ${EMPTY}


*** Keywords ***

Start application in VM
    [Arguments]    ${app_name}   ${vm_name}   ${process_name}   ${exact_match}=false
    Check that appVM is running   ${vm_name}
    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    Start application   ${app_name}
    IF   '${vm_name}' != '${GUI_VM}'   Switch to vm   ${vm_name}
    Check that the application was started    ${process_name}   exact_match=${exact_match}

Check that appVM is running
    [Arguments]    ${vm_name}
    Check if ssh is ready on vm   ${vm_name}   timeout=60
    Switch to vm      ${vm_name}
    # Wait until systemctl status is running (ignore error in case the status is degraded)
    ${status}   Run Keyword and Ignore Error    Verify Systemctl status

Start application
    [Arguments]      ${app_name}
    Execute Command  nohup sh -c 'WAYLAND_DISPLAY=wayland-1 ghaf-open ${app_name}' > ${APP_OUTPUT_FILE} 2>&1 &

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
    Start application in VM   com.system76.CosmicTerm   ${GUI_VM}   cosmic-term   exact_match=true

Log and remove app output
    [Documentation]    Specify the VM from which the app was started and the user (the owner of the file)
    [Arguments]   ${file}    ${vm}    ${user}=ghaf
    Switch to vm  ${vm}    ${user}
    ${output}     Execute Command    cat ${file}
    Log           ${output}
    Remove file   ${file}

Log app vm journalctl
    [Documentation]    Specify the VM where the App is actually running
    [Arguments]   ${vm}
    Switch to vm  ${vm}
    ${output}     Execute Command    journalctl -b
    Log           ${output}

Kill App Process And Save Logs
    [Documentation]    Kill all running process and log apps output and journalctl
    ...                app_start_vm - the VM from which the app was started
    ...                user - by what user the app was started
    ...                log_file - the name of the file which was defined in the app's starting command
    ...                app_running_vm - the VM where the App is actually running
    [Arguments]        ${app_start_vm}   ${user}   ${log_file}   ${app_running_vm}=${app_start_vm}
    Switch to vm       ${app_running_vm}
    Kill process       @{APP_PIDS}
    Log and remove app output   ${log_file}  ${app_start_vm}   user=${user}
    IF  '${TEST_STATUS}'=='FAIL'   Log app vm journalctl  ${app_running_vm}

Kill App in VM
    [Arguments]   ${vm}
    Kill App Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    ${APP_OUTPUT_FILE}    ${vm}

Kill App By Name
    [Arguments]     ${proc_name}   ${exact_match}=false   ${sudo}=False
    ${pass_status}   ${output}    Run Keyword And Ignore Error   Check that the application was started   ${proc_name}   1
    IF  $pass_status=='PASS'
        Log To Console   ${proc_name} is running, killing the process
        @{pid}           Find pid by name   ${proc_name}
        Kill process     @{pid}   sudo=${sudo}
    END

Start app via GUI
    [Documentation]    Start Application via GUI and verify related process started
    [Arguments]        ${app-vm}
    ...                ${app}
    ...                ${display_name}=""
    ...                ${exact_match}=false
    Check if ssh is ready on vm    ${app-vm}

    Open app menu
    Type string and press enter  ${display_name}
    Tab and enter   tabs=1
    Save time       ${app}_start

    Switch to vm    ${app-vm}
    Check that the application was started    ${app}  10  ${exact_match}

    [Teardown]    Run Keywords    Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ...           AND             Move cursor to corner

Open app menu
    [Documentation]    Check if app menu is open and if not open it
    # Searches for app menu magnifying glass to identify if app menu is open
    Log To Console     Checking that app menu is not already open
    ${status}   ${output}      Run Keyword And Ignore Error   Locate on screen  image  search-neg.png  0.90  1  fail_expected=True
    IF  '${status}' == 'PASS'
        Log To Console    App menu is already open
    ELSE
        Log To Console    Opening app menu
        Locate and click  image  ${APP_MENU_LAUNCHER}  0.95  10
    END

Close app via GUI
    [Documentation]    Close Application via GUI and verify related process stopped
    [Arguments]        ${app-vm}
    ...                ${app}
    ...                ${close_button}=./window-close.png
    ...                ${windows_to_close}=1
    ...                ${exact_match}=false
    ...                ${verify_is_killed}=true
    Switch to vm       ${app-vm}
    Check that the application was started    ${app}  exact_match=${exact_match}
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Log To Console     Clicking the close button of the application window
    Locate and click   image  ${close_button}  0.8  iterations=15
    Save Time          ${app}_launched    ${LAST_SCREENSHOT_TIME}
    IF  $verify_is_killed=='true'
        Switch to vm       ${app-vm}
        ${status}          Run Keyword And Return Status  Check that the application is not running  ${app}  5  ${exact_match}
        IF  "${windows_to_close}" != "1"
            # At first launch chrome opens window for selecting account.
            # If this window is closed the actual browser window still opens.
            # So need to prepare to close another window in chrome test case.
            IF  '${status}' != 'True'
                Switch to vm        ${GUI_VM}  user=${USER_LOGIN}
                Locate and click    image  ${close_button}  0.8  iterations=10
                Switch to vm        ${app-vm}
                ${status}           Run Keyword And Return Status  Check that the application is not running  ${app}  5  ${exact_match}
            END
        END
        IF  '${status}' != 'True'
            FAIL  Failed to close the application
        END
    END
    # In case closing the app via GUI failed
    [Teardown]     Run Keywords   Switch to vm   ${app-vm}   AND   Kill process   @{APP_PIDS}
    ...            AND   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}   AND   Move cursor to corner
