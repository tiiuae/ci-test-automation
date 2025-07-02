
# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Keywords for gui tests. Note: These keywords assume the connection is to the gui-vm,
...                 as the ghaf user. If a keyword requires the user account, it will handle switching to
...                 the user and switch back to the ghaf user during teardown.
Resource            ../config/variables.robot
Library             ../lib/GuiTesting.py    ${OUTPUT_DIR}/outputs/gui-temp/
Library             Collections
Library             DateTime
Library             OperatingSystem


*** Variables ***

${APP_MENU_LAUNCHER}   ./launcher.png
${LOCK_ICON}           ./lock.png
${DISABLE_LOGOUT}      ${EMPTY}
${GUI_TEMP_DIR}        ${OUTPUT_DIR}/outputs/gui-temp/

*** Keywords ***

Log in, unlock and verify
    [Documentation]   Open desktop by logging in or unlocking. Verify that desktop is available.
    [Arguments]       ${stop_swayidle}=True  ${enable_dnd}=False
    ${logout_status}    Check if logged out   1
    IF  ${logout_status}
        Log in via GUI
        Wait for Ghaf session activation
    ELSE
        ${lock}       Check if locked
        IF  ${lock}   Unlock
    END

    # This is a workaround for a cosmic-greeter bug https://github.com/pop-os/cosmic-greeter/issues/135.
    # If the laptop did not login on the first attempt tries to press Tab to select the password field
    # and then attempts to log in again.
    ${status}   ${output}   Run Keyword And Ignore Error   Verify desktop availability
    IF   $status == 'FAIL'
        Log To Console    There was maybe a bug with the cosmic-greeter, let's try logging in again
        Log To Console    Pressing Tab to activate the password field
        Press Key(s)      TAB
        Log in via GUI
        Wait for Ghaf session activation
        Verify desktop availability
    END

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
    ${logout_status}      Check if logged out    1
    IF  not ${logout_status}
        Log out via GUI
        ${logout_status}  Check if logged out
        IF  not ${logout_status}    FAIL  Failed to log out.
    END

Log in via GUI
    [Documentation]   Log in by typing password
    Log To Console    Logging in
    # Make sure that password field is active by clicking on screen
    Execute Command   ydotool mousemove --absolute -x 50 -y 50  sudo=True  sudo_password=${PASSWORD}
    Execute Command   ydotool click 0xC0  sudo=True  sudo_password=${PASSWORD}

    IF  "Dell" in "${DEVICE}"    Sleep  5
    Type string and press enter  ${USER_PASSWORD}  confidential=True

Log out via GUI
    [Documentation]   Log out by using keyboard shortcut
    # Allow disabling logout in case of running test automation locally from ghaf-host.
    # This prevents terminal from being shutdown and allows test run to finish.
    IF  $DISABLE_LOGOUT == 'true'
        Log To Console    Log out disabled. Skipping log out procedure.
        RETURN
    END
    Log To Console    Logging out by pressing Super+Shift+Escape 
    Press Key(s)      LEFTMETA+LEFTSHIFT+ESC
    Tab and enter     tabs=2

Type string and press enter
    [Arguments]    ${string}=${EMPTY}  ${confidential}=False  ${enter}=True
    IF  ${confidential} 
        Log To Console    Typing password
    ELSE
        Log To Console    Typing "${string}"
    END
    IF  $string != '${EMPTY}'
        Execute Command   ydotool type ${string}  sudo=True  sudo_password=${PASSWORD}
    END
    IF  ${enter}
        Press Key(s)      ENTER
    ELSE
        Log To Console    Skipping Enter
    END

Tab and enter
    [Arguments]    ${tabs}=1
    Log To Console      Pressing Tab ${tabs} times and then Enter to select
    FOR  ${i}  IN RANGE  ${tabs}
        Press Key(s)   TAB
    END
    Press Key(s)       ENTER

Locate image on screen
    [Documentation]    Take a screenshot. Locate given image on the screenshot.
    ...                Return center coordinates of the image in mouse coordinate system.
    [Arguments]        ${image_to_be_searched}  ${confidence}=0.999   ${iterations}=5   ${fail_expected}=False  ${debug_screenshot}=True
    ${coordinates}=        Set Variable  ${EMPTY}
    ${pass_status}=        Set Variable  FAIL
    Switch to vm    gui-vm  user=${USER_LOGIN}
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
        IF    $pass_status=='PASS'
            IF  ${fail_expected} and ${debug_screenshot}
                Timestamp screenshot
                Log     Image recognition succeeded but fail_expected=${fail_expected}    console=True
            END
            BREAK
        END
        Sleep  1
    END
    IF  $pass_status=='FAIL' and ${debug_screenshot} and not ${fail_expected}
        Timestamp screenshot
        FAIL  Image recognition failure: ${image_to_be_searched}
    END
    Log To Console    Coordinates: ${coordinates}
    ${mouse_x}  Get From Dictionary   ${coordinates}  x
    ${mouse_y}  Get From Dictionary   ${coordinates}  y
    RETURN  ${mouse_x}  ${mouse_y}
    [Teardown]    Switch to vm    gui-vm

Locate and click
    [Arguments]   ${image_to_be_searched}  ${confidence}=0.99  ${iterations}=5
    ${mouse_x}  ${mouse_y}  Locate image on screen  ${image_to_be_searched}  ${confidence}  ${iterations}
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
    Execute Command   ydotool mousemove --absolute -x 50 -y 50  sudo=True  sudo_password=${PASSWORD}

Verify desktop availability
    [Documentation]         Check that launcher icon is available on desktop
    Log To Console          Verifying login by trying to detect the launcher icon
    #Locate image on screen  ${APP_MENU_LAUNCHER}  0.95  10

    # This is a workaround for launcher icon missing sometimes. If launcher icon can't be found tries to search
    # for the power menu icon. Gui-vm user log is saved to help debugging.
    ${status}   ${output}   Run Keyword And Ignore Error   Locate image on screen  ${APP_MENU_LAUNCHER}  0.95  10
    IF   $status == 'FAIL'
        Get gui-vm user journalctl log
        Log To Console    Could not find launcher icon, checking for power menu icon
        Locate image on screen   ./power.png  0.55  5
    END

Move cursor
    Log To Console    Moving cursor to random location
    ${x}    Evaluate  random.randint(50, 500)  modules=random
    ${y}    Evaluate  random.randint(50, 500)  modules=random
    Execute Command   ydotool mousemove --absolute -x ${x} -y ${y}  sudo=True  sudo_password=${PASSWORD}

Check if logged out
    [Documentation]    Check if system is in logged out state
    [Arguments]        ${iterations}=10
    Switch to vm    gui-vm  user=${USER_LOGIN}
    FOR   ${i}   IN RANGE  ${iterations}
        ${activity}=       Execute Command    systemctl --user is-active ghaf-session.target  return_stdout=True
        IF  $activity == "active"
            Log To Console      Ghaf session is ${activity}, user is logged in
        ELSE
            Log To Console      Ghaf session is ${activity}, user is logged out
            RETURN    ${True}
        END
        Sleep  1
    END
    RETURN    ${False}
    [Teardown]    Switch to vm    gui-vm

Wait for Ghaf session activation
    [Documentation]    Wait until ghaf session is in active state
    Switch to vm    gui-vm  user=${USER_LOGIN}
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
    [Teardown]    Switch to vm    gui-vm

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}=0   ${background}=none   ${output_filename}=icon.png
    SSHLibrary.Get File  ${path}/${icon_name}   ${GUI_TEMP_DIR}icon.svg
    Convert app icon  ${crop}   ${background}   input_file=${GUI_TEMP_DIR}icon.svg  output_file=${GUI_TEMP_DIR}${output_filename}

Check if locked
    [Documentation]    Check if the screen lock is active
    ${logout_status}   Check if logged out   1
    IF  not ${logout_status}
        ${status}   ${output}      Run Keyword And Ignore Error   Locate image on screen  ${LOCK_ICON}  0.95  1  debug_screenshot=False
        IF  '${status}' == 'PASS'
            Log To Console    Screen is locked
            RETURN    ${True}
        END
    END
    Log To Console    Screen lock is not active
    RETURN    ${False}

Unlock
    [Documentation]    Unlock the screen be typing password
    # Make sure that password field is active by clicking it
    Locate and click   ${LOCK_ICON}   0.95  5
    Log To Console     Typing password to unlock
    Type string and press enter  ${USER_PASSWORD}  confidential=True

Save most common icons and paths to icons
    [Documentation]         Save those icons by name which will be used in multiple test cases
    ...                     Save paths to icon packs in gui-vm nix store
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

Stop swayidle
    [Documentation]    Stop swayidle to prevent automatic suspension
    Log To Console    Disabling automated lock and suspend
    Switch to vm    gui-vm  user=${USER_LOGIN}
    Execute Command   systemctl --user stop swayidle
    [Teardown]    Switch to vm    gui-vm

Set do not disturb state
    [Documentation]   Set do not disturb to true or false
    [Arguments]       ${state}
    Log To Console    Setting Do Not Disturb to ${state}
    Switch to vm    gui-vm  user=${USER_LOGIN}
    Execute Command   echo ${state} > ~/.config/cosmic/com.system76.CosmicNotifications/v1/do_not_disturb
    [Teardown]    Switch to vm    gui-vm

Get screen brightness
    [Documentation]   Get and return current brightness value
    ${output}         Execute Command    ls /nix/store | grep brightnessctl | grep -v .drv
    ${brightness}     Execute Command    /nix/store/${output}/bin/brightnessctl get
    Log To Console    Brightness is ${brightness}
    RETURN            ${brightness}

Get gui-vm user journalctl log
    [Setup]      Switch to vm    gui-vm  user=${USER_LOGIN}
    Get user journalctl log   gui-vm-user.log
    [Teardown]   Switch to vm    gui-vm

Switch keyboard layout
    [Documentation]   Toggle layout between English, Arabic and Finnish
    Log To Console    Pressing Alt+Shift, shortcut for switching keyboard layout
    Press Key(s)      LEFTALT+LEFTSHIFT

Timestamp screenshot
    ${current_time}  DateTime.Get Current Date  result_format=%Y%m%d_%H%M%S
    Run Process      sh  -c  cp ${GUI_TEMP_DIR}screenshot.png ${GUI_TEMP_DIR}screenshot_${current_time}.png  shell=true

Press Key(s)
    [Arguments]        ${key_combination}
    [Documentation]    Simulates key press(es) using ydotool. If there are multiple keys they must be separated with '+'.
    ...   Check the correct key name from https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
    ${ydotool_command}    Generate Ydotool Key Command   ${key_combination}
    Log               ${ydotool_command}
    Log To Console    Pressing key(s): ${key_combination}
    ${output}    ${rc}    Execute Command   ${ydotool_command}  sudo=True  sudo_password=${PASSWORD}    return_rc=True
    Should Be Equal As Integers     ${rc}   0
