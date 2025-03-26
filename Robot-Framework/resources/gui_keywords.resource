
# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Library             ../lib/GuiTesting.py    ${OUTPUT_DIR}/outputs/gui-temp/
Library             Collections


*** Variables ***

${APP_MENU_LAUNCHER}   ./launcher.png
${LOCK_ICON}           ./lock.png
${DISABLE_LOGOUT}      ${EMPTY}
${GUI_TEMP_DIR}        ${OUTPUT_DIR}/outputs/gui-temp/

*** Keywords ***

Log in, unlock and verify
    [Documentation]   Open desktop by logging in or unlocking. Verify that desktop is available.
    Start ydotoold
    ${logout_status}    Check if logged out    1
    IF  ${logout_status}
        Log in via GUI
        # Give desktop time to load, needed especially for Dell and when external monitor is connected.
        Sleep  15
    ELSE
        ${lock}       Check if locked
        IF  ${lock}   Unlock
    END
    Verify login
    Stop swayidle

Log out and verify
    [Documentation]   Log out. Verify that session was logged out.
    Start ydotoold
    ${logout_status}      Check if logged out    1
    IF  not ${logout_status}
        Log out via GUI
        ${logout_status}  Check if logged out
        IF  not ${logout_status} and not $DISABLE_LOGOUT    FAIL  Failed to log out.
    END
    Stop ydotoold

Log in via GUI
    [Documentation]   Log in by typing password.
    Log To Console    Logging in
    # Make sure that password field is active by clicking on screen
    Execute Command   ydotool mousemove --absolute -x 50 -y 50  sudo=True  sudo_password=${PASSWORD}
    Execute Command   ydotool click 0xC0  sudo=True  sudo_password=${PASSWORD}
    Log To Console    Typing username and password to login
    Type string and press enter  ${USER_PASSWORD}

Log out via GUI
    [Documentation]   Log out by using keyboard shortcut.
    # Allow disabling logout in case of running test automation locally from ghaf-host.
    # This prevents terminal from being shutdown and allows test run to finish.
    IF  $DISABLE_LOGOUT == 'true'
        Log To Console    Log out disabled. Skipping log out procedure.
        RETURN
    END
    Log To Console    Logging out by pressing Super+Shift+Escape 
    Execute Command   ydotool key 125:1 42:1 1:1 1:0 42:0 125:0  sudo=True  sudo_password=${PASSWORD}
    Tab and enter     tabs=2

Type string and press enter
    [Arguments]   ${string}=${EMPTY}
    Connect to VM     ${GUI_VM}
    Log To Console    Typing
    IF  $string != '${EMPTY}'
        Execute Command   ydotool type ${string}  sudo=True  sudo_password=${PASSWORD}
    END
    Log To Console    Pressing Enter
    Execute Command   ydotool key 28:1 28:0  sudo=True  sudo_password=${PASSWORD}

Tab and enter
    [Arguments]    ${tabs}=1
    Connect to VM       ${GUI_VM}
    Log To Console      Pressing Tab ${tabs} times and then Enter to select
    ${command}=    Set Variable    ${EMPTY}
    FOR  ${i}  IN RANGE  ${tabs}
        ${command}=    Set Variable  ${command} 15:1 15:0
    END
    ${command}=    Set Variable  ${command} 28:1 28:0
    Execute Command    ydotool key ${command}  sudo=True  sudo_password=${PASSWORD}

Locate image on screen
    [Documentation]    Take a screenshot. Locate given image on the screenshot.
    ...                Return center coordinates of the image in mouse coordinate system
    [Arguments]        ${image_to_be_searched}  ${confidence}=0.999   ${iterations}=5
    ${coordinates}=        Set Variable  ${EMPTY}
    ${pass_status}=        Set Variable  FAIL
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Execute Command        mkdir test-images
    FOR   ${i}   IN RANGE  ${iterations}
        Log To Console     Taking screenshot
        ${result}=         Execute Command  cosmic-screenshot --interactive=false --save-dir ./test-images  return_stdout=True   return_rc=True   timeout=10
        IF  "${result[1]}" == "0"
            SSHLibrary.Get File  ${result[0]}  ${GUI_TEMP_DIR}screenshot.png
            Log To Console    Locating image ${image_to_be_searched} on ${result[0]}
            ${pass_status}  ${coordinates}  Run Keyword And Ignore Error  Locate image  ${GUI_TEMP_DIR}${image_to_be_searched}   ${confidence}
        END
        IF    $pass_status=='PASS'    BREAK
        Sleep  1
    END
    IF    $pass_status=='FAIL'    FAIL  Image recognition failure: ${image_to_be_searched}
    Log To Console    Coordinates: ${coordinates}
    ${mouse_x}  Get From Dictionary   ${coordinates}  x
    ${mouse_y}  Get From Dictionary   ${coordinates}  y
    RETURN  ${mouse_x}  ${mouse_y}

Locate and click
    [Arguments]   ${image_to_be_searched}  ${confidence}=0.99  ${iterations}=5
    ${mouse_x}  ${mouse_y}  Locate image on screen  ${image_to_be_searched}  ${confidence}  ${iterations}
    Connect to VM     ${GUI_VM}
    Execute Command   ydotool mousemove --absolute -x ${mouse_x} -y ${mouse_y}  sudo=True  sudo_password=${PASSWORD}
    Execute Command   ydotool click 0xC0  sudo=True  sudo_password=${PASSWORD}

Start ydotoold
    [Documentation]    Start ydotool daemon if it is not already running.
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Connect to VM    ${GUI_VM}
    ELSE
        Connect
    END
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
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Connect to VM    ${GUI_VM}
    ELSE
        Connect
    END
    Log To Console    Stopping ydotool daemon
    Execute Command   pkill ydotoold  sudo=True  sudo_password=${PASSWORD}

Move cursor to corner
    [Documentation]    Move the cursor to the upper left corner so that it will not block searching further gui screenshots
    Log To Console    Moving cursor to corner from blocking further image detection
    Execute Command   ydotool mousemove --absolute -x 50 -y 50  sudo=True  sudo_password=${PASSWORD}

Verify login
    [Documentation]    Check that launcher icon is available on desktop
    Log To Console          Verifying login by trying to detect the launcher icon
    Locate image on screen  ${APP_MENU_LAUNCHER}  0.95  10

Move cursor
    ${x}    Evaluate  random.randint(50, 500)  modules=random
    ${y}    Evaluate  random.randint(50, 500)  modules=random
    Execute Command   ydotool mousemove --absolute -x ${x} -y ${y}  sudo=True  sudo_password=${PASSWORD}

Check if logged out
    [Documentation]    Check if system is in logged out state
    [Arguments]        ${iterations}=5
    Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    FOR   ${i}   IN RANGE  ${iterations}
        ${activity}=       Execute Command    systemctl --user is-active cosmic-session.target  return_stdout=True
        IF  $activity == "active"
            Log To Console        Cosmic session is ${activity}, user is logged in
        ELSE
            Log To Console        Cosmic session is ${activity}, user is logged out
            RETURN    ${True}
        END
        Sleep  1
    END
    RETURN    ${False}
    [Teardown]         Connect to VM   ${GUI_VM}

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}=0   ${background}=none   ${output_filename}=icon.png
    SSHLibrary.Get File  ${path}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
    Convert app icon  ${crop}   ${background}   input_file=${GUI_TEMP_DIR}icon.svg  output_file=${GUI_TEMP_DIR}${output_filename}

Check if locked
    [Documentation]    Check if the screen lock has been activated
    ${logout_status}   Check if logged out   1
    IF  not ${logout_status}
        Get icon           ${ICONS}/Cosmic/scalable/actions  system-lock-screen-symbolic.svg  background=black
        ${status}   ${output}      Run Keyword And Ignore Error   Locate image on screen  icon.png  0.95  3
        IF  '${status}' == 'PASS'
            Log To Console    Screen is locked
            RETURN    ${True}
        END
    END
    RETURN    ${False}

Unlock
    [Documentation]    Unlock the screen by typing password
    Connect to VM      ${GUI_VM}
    # Make sure that password field is active by clicking it
    Locate and click   ${LOCK_ICON}   0.95  5
    Log To Console     Typing password to unlock
    Type string and press enter  ${USER_PASSWORD}

Save most common icons and paths to icons
    [Documentation]         Save those icons by name which will be used in multiple test cases
    ...                     Save path to icons
    Log To Console          Saving commonly used icons
    ${ICONS}                Execute Command   find $(echo $XDG_DATA_DIRS | tr ':' ' ') -type d -name "icons" 2>/dev/null
    Set Global Variable     ${ICONS}
    Get icon                ${ICONS}/hicolor/scalable/apps  com.system76.CosmicAppLibrary.svg  crop=0  background=black  output_filename=launcher.png
    Get icon                ${ICONS}/Papirus/symbolic/actions  window-close-symbolic.svg  crop=0  background=white  output_filename=window-close.png
    Negate app icon         ${GUI_TEMP_DIR}window-close.png  ${GUI_TEMP_DIR}window-close-neg.png
    Get icon                ${ICONS}/Cosmic/scalable/actions  system-search-symbolic.svg  crop=0  background=white  output_filename=search.png
    Negate app icon         ${GUI_TEMP_DIR}search.png  ${GUI_TEMP_DIR}search-neg.png
    Get icon                ${ICONS}/hicolor/scalable/apps  com.system76.CosmicAppletPower-symbolic.svg  crop=0  background=black  output_filename=power.png
    Get icon                ${ICONS}/Cosmic/scalable/actions  system-lock-screen-symbolic.svg  background=black  output_filename=lock.png

Stop swayidle
    [Documentation]    Stop swayidle to prevent automatic suspension
    Log To Console    Disabling automated lock and suspend
    Connect to VM     ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Execute Command   systemctl --user stop swayidle

Set do not disturb state
    [Documentation]   Set do not disturb to true or false
    [Arguments]    ${state}
    Log To Console    Setting Do Not Disturb to ${state}
    Connect to VM     ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Execute Command   echo ${state} > ~/.config/cosmic/com.system76.CosmicNotifications/v1/do_not_disturb
