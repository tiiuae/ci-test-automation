# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/output_parser.py
Resource            ../resources/common_keywords.resource
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/gui_keywords.resource
Resource            ../resources/service_keywords.resource
Variables           ../config/apps.json

*** Variables ***
${APP_OUTPUT_FILE}   /home/${USER_LOGIN}/output.log
@{RUNNING_VMS}


*** Keywords ***

App Launch Test Template
    [Arguments]   ${app_key}
    Set Test Documentation   Start ${app_key}[display_name] and verify process started
    Start App in VM          ${app_key}
    [Teardown]    Kill App in VM   ${app_key}   ${APP_OUTPUT_FILE}   status=${KEYWORD_STATUS} 

Start App in VM
    [Documentation]    Use always_check_vm=True if calling from tests other than functional
    ...                After calling for this keyword use "Kill App in VM" in the test teardown
    [Arguments]    ${app_key}   ${always_check_vm}=False    ${params_string}=${EMPTY}

    IF    '${app_key}[VM]' not in ${RUNNING_VMS} or ${always_check_vm}   Check that appVM is running   ${app_key}
    Check that App is not running in VM    ${app_key}   range=1   before_launch_check=True

    Start application   ${app_key}[display_name]    params_string=${params_string}
    Check that App is running in VM    ${app_key}   range=5

Check that appVM is running
    [Arguments]    ${app_key}
    Check if ssh is ready on vm   ${app_key}[VM]   timeout=60
    Switch to vm      ${app_key}[VM]
    # Wait until VM systemctl status is not at starting
    Verify Systemctl status

    Append To List   ${RUNNING_VMS}   ${app_key}[VM]
    Log    ${RUNNING_VMS}

Start application
    [Arguments]      ${app_name}    ${params_string}=${EMPTY}
    [Setup]    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    Log    Starting ${app_name}   console=True
    Run Command  nohup sh -c 'ghaf-open "${app_name}" ${params_string}' > ${APP_OUTPUT_FILE} 2>&1 &

Check that App is running in VM
    [Arguments]    ${app_key}   ${range}=2
    ${user}        Set Variable If   '${app_key}[VM]' == '${GUI_VM}'   ${USER_LOGIN}   ghaf
    Switch to vm   ${app_key}[VM]   user=${user}
    Wait Until Keyword Succeeds    ${range}x    1s   Check that process is running   ${app_key}[process_name]

Check that App is not running in VM
    [Arguments]   ${app_key}   ${range}=2   ${before_launch_check}=False
    ${user}              Set Variable If   '${app_key}[VM]' == '${GUI_VM}'   ${USER_LOGIN}   ghaf
    Switch to vm         ${app_key}[VM]   user=${user}
    ${error_message}     Set Variable If      ${before_launch_check}   already running    still running
    Wait Until Keyword Succeeds    ${range}x    1s    Check that process is not running    ${app_key}[process_name]    ${error_message}

Log and remove app output
    [Documentation]    Save app output from ${GUI_VM} and remove the output file.
    [Arguments]   ${file}
    Switch to vm  ${GUI_VM}  user=${USER_LOGIN}
    Run Command   cat ${file}
    Remove file   ${file}

Log app vm journalctl
    [Documentation]    Log journalctl from ${app_key}[VM]
    [Arguments]   ${app_key}
    ${user}       Set Variable If   '${app_key}[VM]' == '${GUI_VM}'   ${USER_LOGIN}   ghaf
    Switch to vm  ${app_key}[VM]  user=${user}
    Run Command   journalctl -b

Kill App in VM
    [Documentation]   Connects to app-vm and kills app ${app_key}.
    ...    Use after "Start application in VM", call this keyword from the test teardown.
    [Arguments]   ${app_key}   ${log_file}=None   ${status}=${TEST_STATUS}   ${require_exists}=True
    ${user}      Set Variable If      '${app_key}[VM]' == '${GUI_VM}'     ${USER_LOGIN}   ghaf
    ${sudo}      Set Variable If      '${app_key}[VM]' == '${GUI_VM}'     False           True

    Switch to vm            ${app_key}[VM]             user=${user}
    Kill process by name    ${app_key}[process_name]   sudo=${sudo}   require_exists=${require_exists}

    IF  '${log_file}' != 'None'   Log and remove app output   ${log_file}
    IF  '${status}'=='FAIL'       Log app vm journalctl       ${app_key}

Start app via GUI
    [Documentation]    Start Application via GUI and verify related process started
    [Arguments]        ${app_key}
    Check that appVM is running          ${app_key}
    Check that App is not running in VM   ${app_key}   range=1   before_launch_check=True

    Open app menu
    Type string     ${app_key}[display_name]  enter_at_end=True
    Save time       ${app_key}[process_name]_start

    Check that App is running in VM   ${app_key}   range=10

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
    [Arguments]        ${app_key}   ${verify_is_killed}=True
    Check that App is running in VM    ${app_key}   range=5
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Log To Console     Clicking the close button of the application window
    Locate and click   image  ${app_key}[close_button]  0.9  iterations=25  wiggle=True
    Save Time          ${app_key}[process_name]_launched    ${LAST_SCREENSHOT_TIME}
    IF  ${verify_is_killed}
        ${status}          Run Keyword And Return Status  Check that App is not running in VM    ${app_key}   range=5
        Should Be True     ${status}   Failed to close the application
    END
    # In case closing the app via GUI failed
    [Teardown]     Run Keywords   Kill App in VM   ${app_key}   status=${KEYWORD_STATUS}  require_exists=${False}
    ...            AND   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}   AND   Move cursor to corner
