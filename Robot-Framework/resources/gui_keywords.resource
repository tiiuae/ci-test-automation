# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Library             ../lib/gui_testing.py
Library             Collections

*** Variables ***

${start_menu}         ./launcher.png
${LOGGED_IN_STATUS}   ${True}

*** Keywords ***

GUI Log in
    [Documentation]   Login and verify that task bar is available
    Verify logout
    IF  ${LOGGED_IN_STATUS}
        Log To Console          Already logged in. Skipping login.
    ELSE
        Log To Console          Logging in
    END
    Start ydotoold
    Log To Console    Typing username and password to login
    Type string and press enter  ${LOGIN}
    Type string and press enter  ${PASSWORD}

GUI Log out
    [Documentation]   Log out and optionally verify that desktop is not available
    [Arguments]        ${log_out_icon}=./logout.png
    Start ydotoold
    Get icon           ghaf-artwork  power.svg  crop=0  background=black
    Locate and click   ./icon.png  0.95  5
    Get icon           ghaf-artwork  logout.svg  crop=0  background=black
    Locate and click   ./icon.png  0.95  5

Type string and press enter
    [Arguments]   ${string}
    Log To Console    Typing
    Execute Command   ydotool type ${string}  sudo=True  sudo_password=${PASSWORD}
    Log To Console    Pressing Enter
    Execute Command   ydotool key -d 0 28:1 28:0  sudo=True  sudo_password=${PASSWORD}

Locate image on screen
    [Documentation]    Take a screenshot. Locate given image on the screenshot.
    ...                Return center coordinates of the image in mouse coordinate system
    [Arguments]        ${image_to_be_searched}  ${confidence}=0.999   ${iterations}=5
    ${coordinates}=  Set Variable  ${EMPTY}
    ${pass_status}=  Set Variable  FAIL
    FOR   ${i}   IN RANGE  ${iterations}
        Log To Console    Taking screenshot
        Execute Command   rm screenshot.png
        ${rc} =    Execute Command  grim screenshot.png  return_stdout=False  return_rc=${true}
        IF  "${rc}" == "0"
            SSHLibrary.Get File  screenshot.png   screenshot.png
            Log To Console    Locating image ${image_to_be_searched} on screenshot
            ${pass_status}  ${coordinates}  Run Keyword And Ignore Error  Locate image  ${image_to_be_searched}   ${confidence}
        END
        IF    $pass_status=='PASS'    BREAK
        Sleep  0.5
    END
    IF    $pass_status=='FAIL'    FAIL  Image recognition failure: ${image_to_be_searched}
    Log To Console    Coordinates: ${coordinates}
    ${mouse_x}  Get From Dictionary   ${coordinates}  x
    ${mouse_y}  Get From Dictionary   ${coordinates}  y
    RETURN  ${mouse_x}  ${mouse_y}

Locate and click
    [Arguments]   ${image_to_be_searched}  ${confidence}=0.99  ${iterations}=5
    ${mouse_x}  ${mouse_y}  Locate image on screen  ${image_to_be_searched}   ${confidence}
    Execute Command   ydotool mousemove --absolute -x ${mouse_x} -y ${mouse_y}  sudo=True  sudo_password=${PASSWORD}
    Execute Command   ydotool click 0xC0  sudo=True  sudo_password=${PASSWORD}

Start ydotoold
    [Documentation]    Start ydotool daemon if it is not already running.
    ${ydotoold_state}=    Execute Command    sh -c 'ps aux | grep ydotoold | grep -v grep'
    IF  $ydotoold_state == '${EMPTY}'
        Log To Console    Starting ydotool daemon
        Run Keyword And Ignore Error  Execute Command   -b /run/current-system/sw/bin/ydotoold --socket-path /tmp/.ydotool_socket  sudo=True  sudo_password=${PASSWORD}  timeout=3
        ${ydotoold_state}=    Execute Command    sh -c 'ps aux | grep ydotoold | grep -v grep'
        Should Not Be Empty  ${ydotoold_state}  failed to start ydotool daemon
    ELSE
        Log To Console    Check: ydotool daemon running
    END

Stop ydotoold
    [Documentation]    Kill ydotool daemon
    Log To Console    Stopping ydotool daemon
    Execute Command   pkill ydotoold  sudo=True  sudo_password=${PASSWORD}

Move cursor to corner
    [Documentation]    Move the cursor to the upper left corner so that it will not block searching further gui screenshots
    Log To Console    Moving cursor to corner from blocking further image detection
    Start ydotoold
    Execute Command   ydotool mousemove --absolute -x 50 -y 50  sudo=True  sudo_password=${PASSWORD}

Verify login
    [Documentation]    Check that launcher icon is available on desktop
    Log To Console          Verifying login by trying to detect the launcher icon
    Locate image on screen  ${start_menu}  0.95  15

Verify logout
    [Documentation]    Check that dekstop is not available by running 'grim' which should have return code 1 in this case
    [Arguments]        ${iterations}=5
    ${status}=  Set Variable  ${EMPTY}
    FOR   ${i}   IN RANGE  ${iterations}
        ${rc}=    Execute Command  grim check.png  return_stdout=False  return_rc=${true}
        IF  "${rc}" == "1"
            Set Global Variable  ${LOGGED_IN_STATUS}  ${False}
            BREAK
        ELSE
            Set Global Variable  ${LOGGED_IN_STATUS}  ${True}
        END
        Sleep  1
    END

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}   ${background}=none   ${output_filename}=icon.png
    IF  $path == "app"
        SSHLibrary.Get File  ${APP_ICON_PATH}/${icon_name}   icon.svg
    ELSE IF  $path == "ghaf-artwork"
        SSHLibrary.Get File  ${ARTWORK_PATH}/${icon_name}   icon.svg
    ELSE
        SSHLibrary.Get File  ${path}/${icon_name}   icon.svg
    END
    Convert app icon  ${crop}   ${background}   input_file=icon.svg  output_file=${output_filename}
