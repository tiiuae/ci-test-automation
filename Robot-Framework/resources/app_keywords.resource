# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
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
@{RUNNING_VMS}


*** Keywords ***

Start application in VM
    [Documentation]    Do not use this keyword outside functional tests!
    ...                After calling for this keyword use "Kill App in VM" in the test teardown
    [Arguments]    ${app_name}   ${app-vm}   ${process_name}
    Set Test Variable    ${TEST_APP-VM}         ${app-vm}
    Set Test Variable    ${TEST_PROCESS_NAME}   ${process_name}

    IF    '${app-vm}' not in ${RUNNING_VMS}   Check that appVM is running   ${app-vm}
    Switch to vm   ${app-vm}
    Check that the application is not running   ${process_name}  1
    
    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    Start application   ${app_name}
    IF   '${app-vm}' != '${GUI_VM}'   Switch to vm   ${app-vm}
    Check that the application was started    ${process_name}  5

Check that appVM is running
    [Arguments]    ${app-vm}
    Check if ssh is ready on vm   ${app-vm}   timeout=60
    Switch to vm      ${app-vm}
    # Wait until systemctl status is running (ignore error in case the status is degraded)
    ${status}     ${failed_units}     Verify Systemctl status

    Append To List   ${RUNNING_VMS}   ${app-vm}
    Log    ${RUNNING_VMS}

Start application
    [Arguments]      ${app_name}
    Log    Starting ${app_name}   console=True
    Run Command  nohup sh -c 'WAYLAND_DISPLAY=wayland-1 ghaf-open ${app_name}' > ${APP_OUTPUT_FILE} 2>&1 &

Check that the application was started
    [Arguments]    ${process_name}  ${range}=2
    FOR   ${i}   IN RANGE  ${range}
        ${status}  Check if process is running   ${process_name}
        IF    ${status}
            Log    ${process_name} is running    console=True
            RETURN
        END
        Sleep   1
    END
    FAIL   ${process_name} is not running after ${range} seconds

Check that the application is not running
    [Arguments]    ${process_name}  ${range}=2
    FOR   ${i}   IN RANGE  ${range}
        ${status}  Check if process is running   ${process_name}
        IF    not ${status}
            Log    ${process_name} is not running    console=True
            RETURN
        END
        Sleep   1
    END
    FAIL   ${process_name} is still running after ${range} seconds

Log and remove app output
    [Documentation]    Specify the VM from which the app was started and the user (the owner of the file)
    [Arguments]   ${file}    ${app-vm}    ${user}=ghaf
    Switch to vm  ${app-vm}    ${user}
    Run Command   cat ${file}
    Remove file   ${file}

Log app vm journalctl
    [Documentation]    Specify the VM where the App is actually running
    [Arguments]   ${app-vm}
    Switch to vm  ${app-vm}
    Run Command   journalctl -b

Kill App Process And Save Logs
    [Documentation]    Kill all running process and log apps output and journalctl
    ...                app_start_vm - the VM from which the app was started
    ...                user - by what user the app was started
    ...                log_file - the name of the file which was defined in the app's starting command
    ...                process_name - the name of the app process that will be killed
    ...                app_running_vm - the VM where the App is actually running
    ...                status - the status of the test executed
    [Arguments]        ${app_start_vm}   ${user}   ${log_file}  ${process_name}  ${app_running_vm}  ${status}=${TEST_STATUS}
    IF   '${app_running_vm}' == '${GUI_VM}'
        Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
        Kill process by name    ${process_name}   sudo=False
    ELSE
        Switch to vm            ${app_running_vm}
        Kill process by name    ${process_name}
    END
    Log and remove app output   ${log_file}  ${app_start_vm}   user=${user}
    IF  '${status}'=='FAIL'   Log app vm journalctl  ${app_running_vm}

Kill App in VM
    [Documentation]   Use after "Start application in VM", call this keyword from the test teardown.
    [Arguments]   ${app-vm}   ${process_name}   ${status}=${TEST_STATUS}
    Kill App Process And Save Logs    ${GUI_VM}  ${USER_LOGIN}  ${APP_OUTPUT_FILE}  ${process_name}  ${app-vm}  ${status}

Kill App By Name
    [Arguments]     ${process_name}   ${sudo}=False
    ${pass_status}   ${output}    Run Keyword And Ignore Error   Check that the application was started   ${process_name}   1
    IF  $pass_status=='PASS'      Kill process by name   ${process_name}   ${sudo}

Start app via GUI
    [Documentation]    Start Application via GUI and verify related process started
    [Arguments]        ${app-vm}
    ...                ${process_name}
    ...                ${display_name}=""
    Check that appVM is running   ${app-vm}
    Check that the application is not running   ${process_name}  1
    Switch to vm                   ${GUI_VM}  user=${USER_LOGIN}

    Open app menu
    Type string and press enter  ${display_name}
    Save time       ${process_name}_start

    Switch to vm    ${app-vm}
    Check that the application was started    ${process_name}  10

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
        Locate on screen  image  search-neg.png  0.90  5
    END

Close app via GUI
    [Documentation]    Close Application via GUI and verify related process stopped
    [Arguments]        ${app-vm}
    ...                ${process_name}
    ...                ${close_button}=./window-close.png
    ...                ${windows_to_close}=1
    ...                ${verify_is_killed}=true
    Switch to vm       ${app-vm}
    Check that the application was started    ${process_name}
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Log To Console     Clicking the close button of the application window
    Locate and click   image  ${close_button}  0.9  iterations=15
    Save Time          ${process_name}_launched    ${LAST_SCREENSHOT_TIME}
    IF  $verify_is_killed=='true'
        Switch to vm       ${app-vm}
        ${status}          Run Keyword And Return Status  Check that the application is not running  ${process_name}  5
        IF  "${windows_to_close}" != "1"
            # At first launch chrome opens window for selecting account.
            # If this window is closed the actual browser window still opens.
            # So need to prepare to close another window in chrome test case.
            IF  '${status}' != 'True'
                Switch to vm        ${GUI_VM}  user=${USER_LOGIN}
                Locate and click    image  ${close_button}  0.9  iterations=10
                Switch to vm        ${app-vm}
                ${status}           Run Keyword And Return Status  Check that the application is not running  ${process_name}  5
            END
        END
        IF  '${status}' != 'True'
            FAIL  Failed to close the application
        END
    END
    # In case closing the app via GUI failed
    [Teardown]     Run Keywords   Switch to vm   ${app-vm}   AND   Kill App By Name   ${process_name}  sudo=True
    ...            AND   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}   AND   Move cursor to corner
