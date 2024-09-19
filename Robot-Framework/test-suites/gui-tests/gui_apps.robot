# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications via GUI
Force Tags          gui
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui_keywords.resource
Library             ../../lib/gui_testing.py
Suite Teardown      Close All Connections


*** Variables ***
@{app_pids}         ${EMPTY}
@{start_menu}       ../gui-ref-images/ewwbar_start_menu.png


*** Test Cases ***

Start and close chromium via GUI on LenovoX1
    [Documentation]   Start Chromium via GUI test automation and verify related process started
    ...               Close Chromium via GUI test automation and verify related process stopped
    [Tags]            bat   SP-T97-1   lenovo-x1
    Start app via GUI on LenovoX1   chromium-vm  chromium
    Close app via GUI on LenovoX1   chromium-vm  chromium

Start and close Firefox via GUI on Orin AGX
    [Documentation]   Passing this test requires that display is connected to the target device
    ...               Start Firefox via GUI test automation and verify related process started
    ...               Close Firefox via GUI test automation and verify related process stopped
    [Tags]            SP-T45-1
    Start app via GUI on Orin AGX   firefox
    Close app via GUI on Orin AGX   firefox

*** Keywords ***

Start app via GUI on LenovoX1
    [Documentation]    Start Application via GUI test automation and verify related process started
    [Arguments]        ${app-vm}=chromium-vm
    ...                ${app}=chromium
    ...                ${launch_icon}=../gui-ref-images/${app}/launch_icon.png

    Connect
    Verify service status  range=15  service=microvm@${app-vm}.service  expected_status=active  expected_state=running
    Connect to netvm
    Connect to VM       ${GUI_VM}

    # Select start menu image according to taskbar type
    ${start_menu}=  Set Variable  ${EMPTY}
    ${ewwbar}   Execute Command   journalctl | grep ewwbar
    ${waybar}   Execute Command   journalctl | grep waybar
    IF  $ewwbar != '${EMPTY}'
        ${start_menu}=     Set Variable   ../gui-ref-images/ewwbar_start_menu.png
    END
    IF  $waybar != '${EMPTY}'
        ${start_menu}=     Set Variable   ../gui-ref-images/waybar_start_menu.png
    END
    IF  $start_menu == '${EMPTY}'
        FAIL  Unknown taskbar type or taskbar not launched
    END

    Check if ssh is ready on vm    ${app-vm}

    Start ydotoold

    Log To Console    Going to click the app menu icon
    Locate and click  ${start_menu}  0.95  5
    Log To Console    Going to click the application launch icon
    Locate and click  ${launch_icon}  0.95  5

    Connect to VM       ${app-vm}
    Check that the application was started    ${app}  10

    [Teardown]    Run Keywords    Connect to VM     ${GUI_VM}
    ...           AND             Move cursor to corner

Close app via GUI on LenovoX1
    [Documentation]    Close Application via GUI test automation and verify related process stopped
    [Arguments]        ${app-vm}=chromium-vm
    ...                ${app}=chromium
    ...                ${close_button}=../gui-ref-images/${app}/close_button.png

    Connect to netvm
    Connect to VM       ${app-vm}
    Check that the application was started    ${app}
    Connect to VM       ${GUI_VM}
    Start ydotoold

    Log To Console    Going to click the close button of the application window
    Locate and click  ${close_button}  0.95  5

    Connect to VM       ${app-vm}
    Check that the application is not running    ${app}   5

    # In case closing the app via GUI failed
    [Teardown]    Run Keywords    Kill process  @{app_pids}
    ...           AND             Connect to VM     ${GUI_VM}
    ...           AND             Move cursor to corner
    ...           AND             Stop ydotoold

Start app via GUI on Orin AGX
    [Documentation]    Start Application via GUI test automation and verify related process started
    ...                Only for ghaf builds where desktop is running on ghaf-host
    [Arguments]        ${app}=firefox
    ...                ${launch_icon}=../gui-ref-images/${app}/launch_icon.png

    Connect

    # Select start menu image according to taskbar type
    ${start_menu}=  Set Variable  ${EMPTY}
    ${ewwbar}   Execute Command   journalctl | grep ewwbar
    ${waybar}   Execute Command   journalctl | grep waybar
    IF  $ewwbar != '${EMPTY}'
        ${start_menu}=     Set Variable   ../gui-ref-images/ewwbar_start_menu.png
    END
    IF  $waybar != '${EMPTY}'
        ${start_menu}=     Set Variable   ../gui-ref-images/waybar_start_menu.png
    END
    IF  $start_menu == '${EMPTY}'
        FAIL  Unknown taskbar type or taskbar not launched
    END

    Start ydotoold

    Log To Console    Going to click the app menu icon
    Locate and click  ${start_menu}  0.95  5
    Log To Console    Going to click the application launch icon
    Locate and click  ${launch_icon}  0.95  5

    Check that the application was started    ${app}  10

    [Teardown]    Run Keywords    Move cursor to corner

Close app via GUI on Orin AGX
    [Documentation]    Close Application via GUI test automation and verify related process stopped
    ...                Only for ghaf builds where desktop is running on ghaf-host
    [Arguments]        ${app}=firefox
    ...                ${close_button}=../gui-ref-images/${app}/close_button.png

    Connect
    Check that the application was started    ${app}
    Start ydotoold

    Log To Console    Going to click the close button of the application window
    Locate and click  ${close_button}  0.999  5

    Check that the application is not running    ${app}   5

    # In case closing the app via GUI failed
    [Teardown]    Run Keywords    Kill process  @{app_pids}
    ...           AND             Move cursor to corner
    ...           AND             Stop ydotoold
