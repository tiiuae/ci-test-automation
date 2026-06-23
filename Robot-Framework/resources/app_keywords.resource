# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/output_parser.py
Resource            ../resources/common_keywords.resource
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/gui_keywords.resource
Resource            ../resources/service_keywords.resource


*** Variables ***
${APP_OUTPUT_FILE}   /home/${USER_LOGIN}/output.log
@{RUNNING_VMS}


*** Keywords ***

Start application in VM
    [Documentation]    Use always_check_vm=True if calling from tests other than functional
    ...                After calling for this keyword use "Kill App in VM" in the test teardown
    [Arguments]    ${app_name}   ${app-vm}   ${process_name}   ${always_check_vm}=False    ${params_string}=${EMPTY}
    Set Test Variable    ${TEST_APP-VM}         ${app-vm}
    Set Test Variable    ${TEST_PROCESS_NAME}   ${process_name}

    IF    '${app-vm}' not in ${RUNNING_VMS} or ${always_check_vm}   Check that appVM is running   ${app-vm}
    Check that App is not running in VM    ${app-vm}   ${process_name}   range=1   before_launch_check=True

    Start application   ${app_name}    params_string=${params_string}
    Check that App is running in VM    ${app-vm}   ${process_name}   range=5

Check that appVM is running
    [Arguments]    ${app-vm}
    Check if ssh is ready on vm   ${app-vm}   timeout=60
    Switch to vm      ${app-vm}
    # Wait until systemctl status is running (ignore error in case the status is degraded)
    ${status}     ${failed_units}     Verify Systemctl status

    Append To List   ${RUNNING_VMS}   ${app-vm}
    Log    ${RUNNING_VMS}

Start application
    [Arguments]      ${app_name}    ${params_string}=${EMPTY}
    [Setup]    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    Log    Starting ${app_name}   console=True
    Run Command  nohup sh -c 'ghaf-open ${app_name} ${params_string}' > ${APP_OUTPUT_FILE} 2>&1 &

Check that App is running in VM
    [Arguments]    ${app-vm}   ${process_name}   ${range}=2
    ${user}        Set Variable If   '${app-vm}' == '${GUI_VM}'   ${USER_LOGIN}   ghaf
    Switch to vm   ${app-vm}   user=${user}
    Wait Until Keyword Succeeds    ${range}x    1s   Check that process is running   ${process_name}

Check that App is not running in VM
    [Arguments]   ${app-vm}   ${process_name}   ${range}=2   ${before_launch_check}=False
    ${user}              Set Variable If   '${app-vm}' == '${GUI_VM}'   ${USER_LOGIN}   ghaf
    Switch to vm         ${app-vm}   user=${user}
    ${error_message}     Set Variable If      ${before_launch_check}   already running    still running
    Wait Until Keyword Succeeds    ${range}x    1s    Check that process is not running    ${process_name}    ${error_message}

Log and remove app output
    [Documentation]    Save app output from ${GUI_VM} and remove the output file.
    [Arguments]   ${file}
    Switch to vm  ${GUI_VM}  user=${USER_LOGIN}
    Run Command   cat ${file}
    Remove file   ${file}

Log app vm journalctl
    [Documentation]    Log journalctl from ${app-vm}, specify the VM where the App is actually running.
    [Arguments]   ${app-vm}
    Switch to vm  ${app-vm}
    Run Command   journalctl -b

Kill App in VM
    [Documentation]   Connects to ${app-vm} and kills process ${process_name}.
    ...    Use after "Start application in VM", call this keyword from the test teardown.
    [Arguments]   ${app-vm}   ${process_name}   ${log_file}=None   ${status}=${TEST_STATUS}   ${require_exists}=True
    ${user}      Set Variable If      '${app-vm}' == '${GUI_VM}'     ${USER_LOGIN}   ghaf
    ${sudo}      Set Variable If      '${user}' == '${USER_LOGIN}'   False           True

    Switch to vm            ${app-vm}         user=${user}
    Kill process by name    ${process_name}   sudo=${sudo}   require_exists=${require_exists}

    IF  '${log_file}' != 'None'   Log and remove app output   ${log_file}
    IF  '${status}'=='FAIL'       Log app vm journalctl       ${app-vm}

Start app via GUI
    [Documentation]    Start Application via GUI and verify related process started
    [Arguments]        ${app-vm}   ${process_name}   ${display_name}
    Check that appVM is running           ${app-vm}
    Check that App is not running in VM   ${app-vm}   ${process_name}   range=1   before_launch_check=True

    Open app menu
    Type string     ${display_name}  enter_at_end=True
    Save time       ${process_name}_start

    Check that App is running in VM   ${app-vm}   ${process_name}   range=10

    [Teardown]    Run Keywords    Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ...           AND             Move cursor to corner

Open app menu
    [Documentation]   Open app menu from the app menu icon
    [Setup]           Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    Log To Console    Opening app menu
    Locate and click  image  ${APP_MENU_LAUNCHER}  0.95  10
    TRY
        # Search for app menu magnifying glass to identify that the app menu is open
        Wait Until Keyword Succeeds    5x    1s    Verify Image On The Screen   search-neg.png  confidence=0.90
    EXCEPT
        Log To Console    App menu did not open, trying again (it might have already been open)
        Locate and click  image  ${APP_MENU_LAUNCHER}  0.95  10
        Wait Until Keyword Succeeds    5x    1s    Verify Image On The Screen   search-neg.png  confidence=0.90
    END

Close app via GUI
    [Documentation]    Close Application via GUI and verify related process stopped
    [Arguments]        ${app-vm}   ${process_name}   ${close_button}   ${verify_is_killed}=True
    Check that App is running in VM    ${app-vm}   ${process_name}   range=5
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Log To Console     Clicking the close button of the application window
    Locate and click   image  ${close_button}  0.9  iterations=25  wiggle=True
    Save Time          ${process_name}_launched    ${LAST_SCREENSHOT_TIME}
    IF  ${verify_is_killed}
        ${status}          Run Keyword And Return Status  Check that App is not running in VM    ${app-vm}   ${process_name}   range=5
        Should Be True     ${status}   Failed to close the application
    END
    # In case closing the app via GUI failed
    [Teardown]     Run Keywords   Kill App in VM   ${app-vm}   ${process_name}   status=${KEYWORD_STATUS}   require_exists=False
    ...            AND   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}   AND   Move cursor to corner
