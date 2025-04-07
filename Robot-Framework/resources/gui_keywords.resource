
# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Library             ../lib/GuiTesting.py    ${OUTPUT_DIR}/outputs/gui-temp/
Library             Collections


*** Variables ***

${START_MENU}         ./launcher.png
${LOGGED_IN_STATUS}   ${True}
${DISABLE_LOGOUT}     ${EMPTY}
${GUI_TEMP_DIR}       ${OUTPUT_DIR}/outputs/gui-temp/

*** Keywords ***

Log in via GUI
    [Documentation]   Login and verify that task bar is available
    [Arguments]       ${stop_swayidle}=True
    Switch Connection    ${CONNECTION}
    Verify logout
    IF  ${LOGGED_IN_STATUS}
        Log To Console          Already logged in. Skipping login.
    ELSE
        Log To Console          Logged out state detected. Logging in.
        Start ydotoold
        Log To Console          Typing username and password to login
        Type string and press enter  ${USER_LOGIN}
        Type string and press enter  ${USER_PASSWORD}
    END
    Try to reset scaling
    Verify login
    IF  ${stop_swayidle}
        Stop swayidle
    END

Log out
    [Documentation]   Log out and optionally verify that desktop is not available
    # Allow disabling logout in case of running test automation locally from ghaf-host.
    # This prevents terminal from being shutdown and allows test run to finish.
    IF  $DISABLE_LOGOUT == 'true'
        Log To Console    Log out disabled. Skipping log out procedure.
        RETURN
    END
    Start ydotoold
    Get icon           ghaf-artwork  power.svg  crop=0  background=black
    Locate and click   icon.png  0.95  5
    Get icon           ghaf-artwork  logout.svg  crop=0  background=black
    Locate and click   icon.png  0.95  5

Type string and press enter
    [Arguments]   ${string}=${EMPTY}
    Connect to VM           ${GUI_VM}
    Log To Console    Typing
    IF  $string != '${EMPTY}'
        Execute Command   ydotool type ${string}  sudo=True  sudo_password=${PASSWORD}
    END
    Log To Console    Pressing Enter
    Execute Command   ydotool key -d 0 28:1 28:0  sudo=True  sudo_password=${PASSWORD}

Locate image on screen
    [Documentation]    Take a screenshot. Locate given image on the screenshot.
    ...                Return center coordinates of the image in mouse coordinate system
    [Arguments]        ${image_to_be_searched}  ${confidence}=0.999   ${iterations}=5
    ${coordinates}=        Set Variable  ${EMPTY}
    ${pass_status}=        Set Variable  FAIL
    Connect to VM           ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    FOR   ${i}   IN RANGE  ${iterations}
        Log To Console     Taking screenshot
        Execute Command    rm screenshot.png
        ${rc}=             Execute Command  grim screenshot.png  return_stdout=False  return_rc=${true}   timeout=5
        IF  "${rc}" == "0"
            SSHLibrary.Get File  screenshot.png   ${GUI_TEMP_DIR}screenshot.png
            Log To Console    Locating image ${image_to_be_searched} on screenshot
            ${pass_status}  ${coordinates}  Run Keyword And Ignore Error  Locate image  ${GUI_TEMP_DIR}${image_to_be_searched}   ${confidence}
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
    Connect to VM     ${GUI_VM}
    Execute Command   ydotool mousemove --absolute -x ${mouse_x} -y ${mouse_y}  sudo=True  sudo_password=${PASSWORD}
    Execute Command   ydotool click 0xC0  sudo=True  sudo_password=${PASSWORD}

Start ydotoold
    [Documentation]    Start ydotool daemon if it is not already running.
    Connect to VM  ${GUI_VM}
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
    Locate image on screen  ${START_MENU}  0.95  15

Move cursor
    Start ydotoold
    ${x}    Evaluate  random.randint(50, 500)  modules=random
    ${y}    Evaluate  random.randint(50, 500)  modules=random
    Execute Command   ydotool mousemove --absolute -x ${x} -y ${y}  sudo=True  sudo_password=${PASSWORD}

Verify logout
    [Documentation]    Check that dekstop is not available by running 'grim' which should have return code 1 in this case
    [Arguments]        ${iterations}=5
    ${status}=         Set Variable  ${EMPTY}
    Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
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
    [Teardown]         Connect to VM   ${GUI_VM}

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}=0   ${background}=none   ${output_filename}=icon.png
    IF  $path == "app"
        SSHLibrary.Get File  ${APP_ICON_PATH}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
    ELSE IF  $path == "ghaf-artwork"
        SSHLibrary.Get File  ${ARTWORK_PATH}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
    ELSE
        SSHLibrary.Get File  ${path}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
    END
    Convert app icon  ${crop}   ${background}   input_file=${GUI_TEMP_DIR}icon.svg  output_file=${GUI_TEMP_DIR}${output_filename}

Check if locked
    [Documentation]    Check if the screen lock has been activated
    Verify logout      2
    IF  ${LOGGED_IN_STATUS}
        Start ydotoold
        Type string and press enter
        Log To Console     Searching for view-reveal-symbolic.svg
        Get icon           ${ICON_THEME}/symbolic/actions  view-reveal-symbolic.svg  background=black
        ${status}   ${output}      Run Keyword And Ignore Error   Locate image on screen  icon.png  0.95  3
        IF  '${status}' == 'PASS'
            RETURN    ${True}
        END
    END
    RETURN    ${False}

Unlock
    [Documentation]    Unlock the screen be typing password
    Start ydotoold
    Log To Console     Typing password to unlock
    Type string and press enter  ${USER_PASSWORD}

Save most common icons and paths to icons
    [Documentation]         Save those icons by name which will be used in multiple test cases
    ...                     Save paths to icon packs in gui-vm nix store
    ${icons}                Execute Command   find $(echo $XDG_DATA_DIRS | tr ':' ' ') -type d -name "icons" 2>/dev/null
    Set Global Variable     ${ICON_THEME}        ${icons}/Papirus
    Log To Console          Saving path to app icon-pack
    Set Global Variable     ${APP_ICON_PATH}  ${ICON_THEME}/128x128/apps
    Log                     ${APP_ICON_PATH}  console=True
    Log To Console          Saving path to ghaf-artwork icons
    ${ghaf_artwork_path}    Execute Command   echo /nix/store/$(ls /nix/store | grep ghaf-artwork- | grep -v .drv)/icons
    Set Global Variable     ${ARTWORK_PATH}  ${ghaf_artwork_path}
    Log                     ${ARTWORK_PATH}  console=True
    Log To Console          Saving gui icons
    Get icon                ghaf-artwork  launcher.svg  crop=0  background=black  output_filename=launcher.png
    Get icon                ${ICON_THEME}/symbolic/actions  window-close-symbolic.svg  crop=0  output_filename=window-close.png  background=white
    Negate app icon         ${GUI_TEMP_DIR}window-close.png  ${GUI_TEMP_DIR}window-close-neg.png

Try to reset scaling
    [Documentation]    Disable hidpi-auto-scaling
    Log To Console     Trying to reset scaling
    Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    FOR   ${i}   IN RANGE  5
        Execute Command   systemctl --user start hidpi-auto-scaling-reset
        ${output}         Execute Command   journalctl --since "5 seconds ago" --user -u hidpi-auto-scaling-reset
        ${status}=        Run Keyword And Return Status    Should contain    ${output}    Finished
        IF  ${status}
            Execute Command   systemctl --user reload ewwbar
            Log To Console    Auto scaling reset succeeded
            BREAK
        Sleep    1
        END
    END
    IF  not ${status}
        Log To Console   Auto scaling reset failed
    END

Stop swayidle
    [Documentation]    Stop swayidle to prevent automatic suspension
    Log To Console    Disabling automated lock and suspend
    Connect to VM     ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Execute Command   systemctl --user stop swayidle