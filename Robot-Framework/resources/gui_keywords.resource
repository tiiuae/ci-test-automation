
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
    [Arguments]       ${stop_swayidle}=True  ${enable_dnd}=False
    Start ydotoold
    ${logout_status}    Check if logged out   1
    IF  ${logout_status}
        Log in via GUI
        Wait for Ghaf session activation
    ELSE
        ${lock}       Check if locked
        IF  ${lock}   Unlock
    END
    Try to reset scaling
    Verify desktop availability
    IF  ${stop_swayidle}   Stop swayidle
    IF  ${enable_dnd}      Set do not disturb state   true

Log out and verify
    [Documentation]   Log out. Verify that session was logged out.
    [Arguments]       ${disable_dnd}=True
    # Allow disabling logout in case of running test automation locally from ghaf-host.
    # This prevents terminal from being shutdown and allows test run to finish.
    IF  $DISABLE_LOGOUT == 'true'
        Log To Console    Log out disabled. Skipping log out procedure.
        RETURN
    END
    IF  ${disable_dnd}   Set do not disturb state   false
    Start ydotoold
    ${logout_status}      Check if logged out    1
    IF  not ${logout_status}
        Log out via GUI
        ${logout_status}  Check if logged out
        IF  not ${logout_status}    FAIL  Failed to log out.
    END
    Stop ydotoold

Log in via GUI
    [Documentation]   Log in by typing username (labwc) and password (labwc&cosmic).
    Log To Console    Logging in
    IF  $COMPOSITOR == 'cosmic'
        # Make sure that password field is active by clicking on screen
        Execute Command   ydotool mousemove --absolute -x 50 -y 50  sudo=True  sudo_password=${PASSWORD}
        Execute Command   ydotool click 0xC0  sudo=True  sudo_password=${PASSWORD}
    ELSE
        IF  "Dell" in "${DEVICE}"    Sleep  15  # waiting for the login gui, slow with Dell.
        Type string and press enter  ${USER_LOGIN}
    END

    IF  "Dell" in "${DEVICE}"    Sleep  5
    Type string and press enter  ${USER_PASSWORD}  confidential=True

Log out via GUI
    [Documentation]   Log out by using keyboard shortcut (cosmic) or by clicking the logout icon.
    # Allow disabling logout in case of running test automation locally from ghaf-host.
    # This prevents terminal from being shutdown and allows test run to finish.
    IF  $DISABLE_LOGOUT == 'true'
        Log To Console    Log out disabled. Skipping log out procedure.
        RETURN
    END
    IF  $COMPOSITOR == 'cosmic'
        Log To Console    Logging out by pressing Super+Shift+Escape 
        Execute Command   ydotool key 125:1 42:1 1:1 1:0 42:0 125:0  sudo=True  sudo_password=${PASSWORD}
        Tab and enter     tabs=2
    ELSE
        Get icon           ghaf-artwork  power.svg  crop=0  background=black
        Locate and click   icon.png  0.95  5
        Get icon           ghaf-artwork  logout.svg  crop=0  background=black
        Locate and click   icon.png  0.95  5
    END

Type string and press enter
    [Arguments]    ${string}=${EMPTY}  ${confidential}=False
    Connect to VM   ${GUI_VM}
    IF  ${confidential} 
        Log To Console    Typing password
    ELSE
        Log To Console    Typing "${string}"
    END
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
    ...                Return center coordinates of the image in mouse coordinate system.
    [Arguments]        ${image_to_be_searched}  ${confidence}=0.999   ${iterations}=5
    ${coordinates}=        Set Variable  ${EMPTY}
    ${pass_status}=        Set Variable  FAIL
    Connect to VM           ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    IF  $COMPOSITOR == 'cosmic'
        Execute Command        mkdir test-images
        FOR   ${i}   IN RANGE  ${iterations}
            Log To Console     Taking cosmic screenshot
            ${result}=         Run Keyword And Ignore Error  Execute Command  cosmic-screenshot --interactive=false --save-dir ./test-images  return_stdout=True   return_rc=True   timeout=5
            Log                ${result}
            IF  "${result}[1][1]" == "0"
                SSHLibrary.Get File  ${result[1][0]}  ${GUI_TEMP_DIR}screenshot.png
                Log To Console    Locating image ${image_to_be_searched} on ${result[1][0]}
                ${pass_status}  ${coordinates}  Run Keyword And Ignore Error  Locate image  ${GUI_TEMP_DIR}${image_to_be_searched}   ${confidence}
            END
            IF    $pass_status=='PASS'    BREAK
            Sleep  1
        END
    ELSE
        FOR   ${i}   IN RANGE  ${iterations}
            Log To Console     Taking grim screenshot
            Execute Command    rm screenshot.png
            ${rc}=             Execute Command  grim screenshot.png  return_stdout=False  return_rc=${true}   timeout=5
            IF  "${rc}" == "0"
                SSHLibrary.Get File  screenshot.png   ${GUI_TEMP_DIR}screenshot.png
                Log To Console    Locating image ${image_to_be_searched} on screenshot
                ${pass_status}  ${coordinates}  Run Keyword And Ignore Error  Locate image  ${GUI_TEMP_DIR}${image_to_be_searched}   ${confidence}
            END
            IF    $pass_status=='PASS'    BREAK
            Sleep  1
        END
    END
    IF    $pass_status=='FAIL'    FAIL  Image recognition failure: ${image_to_be_searched}
    Log To Console    Coordinates: ${coordinates}
    ${mouse_x}  Get From Dictionary   ${coordinates}  x
    ${mouse_y}  Get From Dictionary   ${coordinates}  y
    RETURN  ${mouse_x}  ${mouse_y}
    [Teardown]    Connect to VM   ${GUI_VM}

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

Verify desktop availability
    [Documentation]         Check that launcher icon is available on desktop
    Log To Console          Verifying login by trying to detect the launcher icon
    Locate image on screen  ${APP_MENU_LAUNCHER}  0.95  10

Move cursor
    Log To Console    Moving cursor to random location
    ${x}    Evaluate  random.randint(50, 500)  modules=random
    ${y}    Evaluate  random.randint(50, 500)  modules=random
    Execute Command   ydotool mousemove --absolute -x ${x} -y ${y}  sudo=True  sudo_password=${PASSWORD}

Check if logged out
    [Documentation]    Check if system is in logged out state
    [Arguments]        ${iterations}=10
    Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    FOR   ${i}   IN RANGE  ${iterations}
        IF  $COMPOSITOR == 'cosmic'
            ${activity}=       Execute Command    systemctl --user is-active ghaf-session.target  return_stdout=True
            IF  $activity == "active"
                Log To Console      Ghaf session is ${activity}, user is logged in
            ELSE
                Log To Console      Ghaf session is ${activity}, user is logged out
                RETURN    ${True}
            END
        ELSE
            # In theory checking ghaf-session should also work with labwc, but for some reason it
            # does not always work. Grim returns 1 when desktop is not available.
            ${rc}=    Execute Command  grim check.png  return_stdout=False  return_rc=${true}
            IF  "${rc}" == "1"
                Log To Console       User is logged out
                RETURN    ${True}
            ELSE
                Log To Console       User is logged in
            END
        END
        Sleep  1
    END
    RETURN    ${False}
    [Teardown]    Connect to VM   ${GUI_VM}

Wait for Ghaf session activation
    [Documentation]    Wait until ghaf session is in active state
    Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Log To Console     Waiting for the Ghaf session to start...  no_newline=true 
    FOR   ${i}   IN RANGE  30
        ${activity}=       Execute Command    systemctl --user is-active ghaf-session.target  return_stdout=True
        IF  $activity == "active"
            Log To Console        Success
            Log To Console        Ghaf session is ${activity}, user is logged in
            RETURN
        ELSE
            Log To Console   ${i}.  no_newline=true
        END
        Sleep   0.5
    END
    Log To Console    Failed
    Log To Console    Ghaf session did not activate
    [Teardown]    Connect to VM   ${GUI_VM}

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}=0   ${background}=none   ${output_filename}=icon.png
    IF  $COMPOSITOR == 'cosmic'
        SSHLibrary.Get File  ${path}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
        Convert app icon  ${crop}   ${background}   input_file=${GUI_TEMP_DIR}icon.svg  output_file=${GUI_TEMP_DIR}${output_filename}
    ELSE
        IF  $path == "app"
            SSHLibrary.Get File  ${APP_ICON_PATH}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
        ELSE IF  $path == "ghaf-artwork"
            SSHLibrary.Get File  ${ARTWORK_PATH}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
        ELSE
            SSHLibrary.Get File  ${path}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
        END
        Convert app icon  ${crop}   ${background}   input_file=${GUI_TEMP_DIR}icon.svg  output_file=${GUI_TEMP_DIR}${output_filename}
    END

Check if locked
    [Documentation]    Check if the screen lock is active
    ${logout_status}   Check if logged out   1
    IF  not ${logout_status}
        IF  $COMPOSITOR == 'cosmic'
            Get icon       ${ICONS}/Cosmic/scalable/actions  system-lock-screen-symbolic.svg  background=black
        ELSE
            Get icon           ${ICON_THEME}/symbolic/actions  view-reveal-symbolic.svg  background=black
            Type string and press enter
        END
        ${status}   ${output}      Run Keyword And Ignore Error   Locate image on screen  icon.png  0.95  3
        IF  '${status}' == 'PASS'
            Log To Console    Screen is locked
            RETURN    ${True}
        END
    END
    Log To Console    Screen lock is not active
    RETURN    ${False}

Unlock
    [Documentation]    Unlock the screen be typing password
    Connect to VM      ${GUI_VM}
    IF  $COMPOSITOR == 'cosmic'
        # Make sure that password field is active by clicking it
        Locate and click   ${LOCK_ICON}   0.95  5
    END
    Log To Console     Typing password to unlock
    Type string and press enter  ${USER_PASSWORD}  confidential=True

Save most common icons and paths to icons
    [Documentation]         Save those icons by name which will be used in multiple test cases
    ...                     Save paths to icon packs in gui-vm nix store
    IF  $COMPOSITOR == 'cosmic'
        Log To Console          Saving commonly used icons
        ${ICONS}                Execute Command   find $(echo $XDG_DATA_DIRS | tr ':' ' ') -type d -name "icons" 2>/dev/null
        Set Global Variable     ${ICONS}
        Get icon                ${ICONS}/hicolor/scalable/apps  com.system76.CosmicAppLibrary.svg  crop=0  background=black  output_filename=launcher.png
        Get icon                ${ICONS}/Papirus/24x24/symbolic/actions  window-close-symbolic.svg  crop=0  background=white  output_filename=window-close.png
        Negate app icon         ${GUI_TEMP_DIR}window-close.png  ${GUI_TEMP_DIR}window-close-neg.png
        Get icon                ${ICONS}/Cosmic/scalable/actions  system-search-symbolic.svg  crop=0  background=white  output_filename=search.png
        Negate app icon         ${GUI_TEMP_DIR}search.png  ${GUI_TEMP_DIR}search-neg.png
        Get icon                ${ICONS}/hicolor/scalable/apps  com.system76.CosmicAppletPower-symbolic.svg  crop=0  background=black  output_filename=power.png
        Get icon                ${ICONS}/Cosmic/scalable/actions  system-lock-screen-symbolic.svg  background=black  output_filename=lock.png
    ELSE
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
    END

Try to reset scaling
    [Documentation]    Disable hidpi-auto-scaling (labwc only)
    IF  $COMPOSITOR != 'cosmic'
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
    END
    [Teardown]    Connect to VM   ${GUI_VM}

Stop swayidle
    [Documentation]    Stop swayidle to prevent automatic suspension
    Log To Console    Disabling automated lock and suspend
    Connect to VM     ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Execute Command   systemctl --user stop swayidle
    [Teardown]    Connect to VM   ${GUI_VM}

Set do not disturb state
    [Documentation]   Set do not disturb to true or false (cosmic only)
    [Arguments]       ${state}
    IF  $COMPOSITOR == 'cosmic'
        Log To Console    Setting Do Not Disturb to ${state}
        Connect to VM     ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
        Execute Command   echo ${state} > ~/.config/cosmic/com.system76.CosmicNotifications/v1/do_not_disturb
    END
    [Teardown]    Connect to VM   ${GUI_VM}

Set compositor
    [Documentation]   Set compositor to cosmic if cosmic process is running. By default compositor is set labwc.
    Log To Console    Checking compositor
    ${cosmic_processes}=    Execute Command    sh -c 'ps aux | grep cosmic | grep -v grep'
    Log    ${cosmic_processes}
    IF  $cosmic_processes != '${EMPTY}'
        Log To Console   Compositor: cosmic
        Set Global Variable   ${COMPOSITOR}   cosmic
    ELSE
        Log To Console   Compositor: labwc
    END