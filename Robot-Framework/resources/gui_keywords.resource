# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Keywords for gui tests. Note: These keywords assume the connection is to the gui-vm
...                 as the non-privileged user.

Library             ../lib/GuiTesting.py
Library             Collections
Library             DateTime
Resource            ../resources/app_keywords.resource
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Variables ***
${APP_MENU_LAUNCHER}   launcher.png
${LOCK_ICON}           lock.png
${DISABLE_LOGOUT}      ${EMPTY}
${GUI_OUTPUT_DIR}      ${OUTPUT_DIR}/outputs/gui
${ICONS_DIR}           ${OUTPUT_DIR}/outputs/icons
${SCREENSHOT_GHAF}     /home/${USER_LOGIN}/test-images/screenshot.jpeg
${SCREENSHOT_LOCAL}    ${GUI_OUTPUT_DIR}/screenshot.jpeg
${YDOTOOL_SOCKET}      /tmp/.ydotool_socket
${SCREEN_SELECTED}     ${False}


*** Keywords ***

Log in, unlock and verify
    [Documentation]   Open desktop by logging in or unlocking. Verify that desktop is available.
    [Arguments]       ${enable_dnd}=False
    ${logout_status}    Check if logged out   1
    IF  ${logout_status}
        Log in via GUI
    ELSE
        ${lock}       Check if locked
        IF  ${lock}   Unlock
    END

    # This is a workaround for a cosmic-greeter bug https://github.com/pop-os/cosmic-greeter/issues/135.
    # If the laptop did not login on the first attempt tries to press Tab to select the password field
    # and then attempts to log in again.
    ${status}   ${output}   Run Keyword And Ignore Error   Verify desktop availability   logging_in=True
    IF   $status == 'FAIL'
        Log To Console    There was maybe a bug with the cosmic-greeter, let's try logging in again
        Log To Console    Pressing Tab to activate the password field
        Press Key(s)      TAB
        Log in via GUI
        Verify desktop availability   logging_in=True
    END

    Disable automatic suspension
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
        ${lock}       Check if locked
        IF  ${lock}   Unlock
        Log out via GUI
        ${logout_status}  Check if logged out
        IF  not ${logout_status}    FAIL  Failed to log out.
    END

Log in via GUI
    [Documentation]   Log in by typing password
    Log To Console    Logging in
    # Make sure that password field is active by clicking on screen
    Run ydotool command   mousemove --absolute -x 50 -y 50   sudo=True
    Run ydotool command   click 0xC0  sudo=True

    IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep  5
    Confidential password write  ${USER_PASSWORD}

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
    IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep  3
    Tab and enter     tabs=2

Type string and press enter
    [Arguments]    ${string}=${EMPTY}  ${enter}=True   ${sudo}=False
    Log To Console    Typing "${string}"
    IF  $string != '${EMPTY}'
        Run ydotool command   type ${string}  ${sudo}
    END
    IF  ${enter}
        Press Key(s)      ENTER   ${sudo}
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

Locate on screen
    [Documentation]    Take a screenshot. Locate given image or text on the screenshot.
    ...                Return center coordinates of the item in mouse coordinate system.
    [Arguments]        ${type}  ${searched_item}  ${confidence}=0.99   ${iterations}=10   ${expected_result}=PASS  ${debug_screenshot}=True   ${timeout}=120   ${scale}=1
    [Timeout]          ${timeout} seconds
    ${coordinates}=        Set Variable  ${EMPTY}
    ${locate_status}=      Set Variable  FAIL
    Run Command            mkdir -p test-images
    FOR   ${i}   IN RANGE  ${iterations}
        ${screenshot_status}  ${result}     Take a screenshot   ${i+1}
        IF  '${screenshot_status}' == 'PASS'
            Log To Console       Done, locating ${type} ${searched_item} on screenshot
            SSHLibrary.Get File  ${SCREENSHOT_GHAF}  ${SCREENSHOT_LOCAL}
            IF  $type=="image"
                ${locate_status}    ${coordinates}  Run Keyword And Ignore Error  Locate image  ${SCREENSHOT_LOCAL}  ${ICONS_DIR}/${searched_item}   ${confidence}
            ELSE IF  $type=="text"
                ${locate_status}    ${coordinates}  Run Keyword And Ignore Error  Locate text  ${SCREENSHOT_LOCAL}  ${searched_item}   scale=${scale}
            ELSE
                FAIL              Wrong type ${type} given for image recognition
            END
            IF    $locate_status=='PASS'   BREAK
        ELSE
            ${error}     Get Regexp Matches   ${result}   (?s)Error:\s*(.+)$
            ${log_msg}   Set Variable If   ${error}   ${error}[0]   ${result}
            Log     FAIL: ${log_msg}   console=True
            Sleep   0.5
        END
    END
    IF  ${debug_screenshot} and ($locate_status != $expected_result)
        Log    Image recognition status ${locate_status} but expected_result=${expected_result}    console=True
        Timestamp last screenshot
    END
    IF  $locate_status=='PASS'
        Log   Found, coordinates: ${coordinates}  console=True
        ${mouse_x}  Get From Dictionary   ${coordinates}  x
        ${mouse_y}  Get From Dictionary   ${coordinates}  y
        RETURN  ${mouse_x}  ${mouse_y}
    ELSE
        Log    Could not find ${type}: ${searched_item}  console=True
        FAIL   Could not find ${type}: ${searched_item}
    END

Take a screenshot
    [Arguments]   ${attempt}=0
    Log To Console           Taking a screenshot (#${attempt})...  no_newline=True
    ${screenshot_status}  ${result}   Run Keyword And Ignore Error  Run Command  WAYLAND_DISPLAY=wayland-1 grim -t jpeg -q 100 ${SCREENSHOT_GHAF}   timeout=5
    ${LAST_SCREENSHOT_TIME}  Evaluate    time.time()
    Set Global Variable      ${LAST_SCREENSHOT_TIME}
    RETURN   ${screenshot_status}  ${result}

Locate and click
    [Arguments]   ${type}  ${searched_item}  ${confidence}=0.99  ${iterations}=10  ${timeout}=120  ${scale}=1  ${wiggle}=True
    ${mouse_x}  ${mouse_y}  Locate on screen  ${type}  ${searched_item}  ${confidence}  ${iterations}  timeout=${timeout}  scale=${scale}
    Run ydotool command   mousemove --absolute -x ${mouse_x} -y ${mouse_y}
    # Wiggle is sometimes needed for the window to recognize the mouse
    IF   ${wiggle}
        Run ydotool command   mousemove 1 1
        Run ydotool command   mousemove -- -1 -1
    END
    Run ydotool command   click 0xC0

Move cursor to corner
    [Documentation]    Move the cursor to the upper left corner so that it will not block searching further gui screenshots
    Log To Console    Moving cursor to corner from blocking further image detection
    Run ydotool command   mousemove --absolute -x 50 -y 50

Verify desktop availability
    [Documentation]    Wait for the login and check that launcher icon is available on desktop
    [Arguments]        ${logging_in}=False

    FOR   ${i}   IN RANGE  60
        ${logout_status}   Check if logged out   1
        IF  not ${logout_status}    BREAK
    END
    IF  ${logout_status}    FAIL    User session did not activate, user is still logged out
    IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep   10

    IF  ${logging_in}   Kill Initial Setup

    Log To Console         Verifying login by trying to detect the launcher icon
    # This is a workaround for launcher icon missing sometimes. If launcher icon can't be found tries to search
    # for the power menu icon. Gui-vm user log is saved to help debugging.
    ${status}   ${output}   Run Keyword And Ignore Error   Locate on screen  image  ${APP_MENU_LAUNCHER}  0.95  100
    IF   $status == 'FAIL'
        Get gui-vm user journalctl log
        Log To Console    Could not find launcher icon, checking for power menu icon
        Locate on screen  image  power.png  0.95  10
    END

Move cursor
    Log To Console    Moving cursor to random location
    ${x}    Evaluate  random.randint(50, 500)  modules=random
    ${y}    Evaluate  random.randint(50, 500)  modules=random
    Run ydotool command   mousemove --absolute -x ${x} -y ${y}

Check if logged out
    [Documentation]    Check if system is in logged out state
    [Arguments]        ${iterations}=10
    FOR   ${i}   IN RANGE  ${iterations}
        ${sessions}       Run Command   loginctl list-sessions | grep seat   rc_match=skip
        IF    $USER_LOGIN in $sessions
            Log      Found active GUI session for ${USER_LOGIN}, user is logged in  console=True
        ELSE
            Log      No active GUI session found for ${USER_LOGIN}, user is logged out  console=True
            RETURN    ${True}
        END
        Sleep  1
    END
    RETURN    ${False}

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}=0   ${background}=none   ${output_filename}=icon.png
    SSHLibrary.Get File  ${path}/${icon_name}   ${ICONS_DIR}/icon.svg
    Convert app icon  ${crop}   ${background}   input_file=${ICONS_DIR}/icon.svg  output_file=${ICONS_DIR}/${output_filename}

Check if locked
    [Documentation]    Check if the screen lock is active
    ${logout_status}   Check if logged out   1
    IF  not ${logout_status}
        ${status}   ${output}      Run Keyword And Ignore Error   Locate on screen  image  ${LOCK_ICON}  0.95  1  debug_screenshot=False
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
    Locate and click   image  ${LOCK_ICON}   0.95  10
    # Can't explain the second click but does not work without
    Locate and click   image  ${LOCK_ICON}   0.95  10
    Confidential password write  ${USER_PASSWORD}
    Sleep   2

Disable automatic suspension
    [Documentation]   Make sure that the device does not turn off during tests
    Log To Console    Disabling automated lock and suspend
    Run Command       echo None > /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicIdle/v1/screen_off_time
    Run Command       echo None > /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time
    Run Command       echo None > /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicIdle/v1/suspend_on_battery_time

Enable automatic suspension
    [Documentation]   Switch back to default suspension times
    Log To Console    Enabling automated lock and suspend
    Remove file       /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicIdle/v1/screen_off_time
    Remove file       /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time
    Remove file       /home/${USER_LOGIN}/.config/cosmic/com.system76.CosmicIdle/v1/suspend_on_battery_time

Set do not disturb state
    [Documentation]   Set do not disturb to true or false
    [Arguments]       ${state}
    Log To Console    Setting Do Not Disturb to ${state}
    Run Command   echo ${state} > ~/.config/cosmic/com.system76.CosmicNotifications/v1/do_not_disturb
    # Make sure that currently shown notifications get closed
    IF   $state == "true"
        Run Command   echo 0 > ~/.config/cosmic/com.system76.CosmicNotifications/v1/max_notifications
    ELSE
        Run Command   echo 3 > ~/.config/cosmic/com.system76.CosmicNotifications/v1/max_notifications
    END

Get gui-vm user journalctl log
    [Arguments]       ${filename}=gui-vm-user.txt
    Run Command   journalctl --user > /tmp/${filename}
    SSHLibrary.Get file   /tmp/${filename}   ${OUTPUT_DIR}/${filename}
    OperatingSystem.File Should Exist   ${OUTPUT_DIR}/${filename}

Timestamp last screenshot
    ${current_time}  DateTime.Get Current Date  result_format=%Y%m%d_%H%M%S
    Run Process      cp  ${SCREENSHOT_LOCAL}  ${GUI_OUTPUT_DIR}/screenshot_${current_time}.jpeg
    Run Process      magick  ${GUI_OUTPUT_DIR}/screenshot_${current_time}.jpeg  ${GUI_OUTPUT_DIR}/screenshot_${current_time}.png

Press Key(s)
    [Arguments]        ${key_combination}   ${sudo}=False
    [Documentation]    Simulates key press(es) using ydotool. If there are multiple keys they must be separated with '+'.
    ...   Check the correct key name from https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
    ${ydotool_command}    Generate Ydotool Key Command   ${key_combination}
    Log                   ${ydotool_command}
    Log To Console        Pressing key(s): ${key_combination}
    Run ydotool command   ${ydotool_command}   ${sudo}

Confidential password write
    [Arguments]      ${pw}
    Switch to vm     ${GUI_VM}
    Log To Console   Typing password secretly
    Set Log Level    NONE
    Write            read -r -s -p 'pw: ' PASSWD
    Sleep            0.5
    ${output} 	     SSHLibrary.Read
    Write            ${pw}
    Sleep            0.5
    ${output} 	     SSHLibrary.Read
    Write            printf '%s' "$PASSWD" | YDOTOOL_SOCKET=${YDOTOOL_SOCKET} ydotool type -f -
    Sleep            3
    ${output} 	     SSHLibrary.Read
    Should Contain 	 ${output}    ${LOGIN}@
    Write            unset PASSWD
    Set Log Level    INFO
    Press Key(s)     ENTER   True
    [Teardown]       Switch to vm   ${GUI_VM}  user=${USER_LOGIN}

Run ydotool command
    [Arguments]    ${command}   ${sudo}=False
    IF   $sudo == "True"
        Switch to vm    ${GUI_VM}
        Log To Console   Running ydotool command with ghaf user
        Run Command   ydotool ${command}  sudo=True
        Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ELSE
        Run Command    YDOTOOL_SOCKET=${YDOTOOL_SOCKET} ydotool ${command}
    END
    Sleep   0.2

Change to gray wallpaper
    Log To Console    Changing to gray wallpaper
    Put File          ../test-files/background.config   .
    Run Command   mv background.config .config/cosmic/com.system76.CosmicBackground/v1/all

Restore default wallpaper
    Log To Console    Changing back to default wallpaper
    Remove file       ~/.config/cosmic/com.system76.CosmicBackground/v1/all

Start screen recording
    [Setup]          Kill App By Name   gpu-screen-recorder
    [Timeout]        1 minute
    Log To Console   Starting screen recording
    ${test_name}     Replace String   ${TEST_NAME}   ${SPACE}   _
    ${cmd}=    Catenate    SEPARATOR=${SPACE}
    ...    systemd-run --user --collect /bin/sh -lc 'exec gpu-screen-recorder
    ...    -w portal -c mkv -k h264 -ac opus -f 60 -cursor yes -restore-portal-session yes
    ...    -cr limited -encoder gpu -q very_high -a device:default_output
    ...    -o /home/${USER_LOGIN}/Videos/${test_name}.mkv
    ...    </dev/null >/tmp/gpu-screen-recorder.log 2>&1'
    Run Command      ${cmd}
    IF   ${SCREEN_SELECTED}==${False}
        # The window to record needs to be selected when recording first time
        # Check if selection window opened
        ${pass_status}  ${output}  Run Keyword And Ignore Error   Locate on screen   text   Share   iterations=5   debug_screenshot=False
        IF  $pass_status=='PASS'
            # Select the display to record
            Tab and enter    tabs=3
            Tab and enter    tabs=2
        END
        Set Global Variable  ${SCREEN_SELECTED}  ${True}
    END
    Check that the application was started   gpu-screen-recorder
    [Teardown]       Run Keyword If   '${KEYWORD_STATUS}' == 'FAIL'   Timestamp last screenshot

Stop screen recording
    [Arguments]      ${test_status}   ${test_name}=""
    ${pass_status}   ${output}    Run Keyword And Ignore Error   Check that the application was started   gpu-screen-recorder
    IF  $pass_status=='PASS'
        Log To Console   Stopping screen recording
        Kill App By Name   gpu-screen-recorder
    ELSE
        Log To Console  Screen recording was not running
    END
    Save screen recording   ${test_status}   ${test_name}

Save screen recording
    [Arguments]    ${test_status}   ${test_name}
    # Get the name of the last recording
    ${video_file}    Run Command   ls /home/${USER_LOGIN}/Videos -Art | tail -n 1
    ${test_name}     Replace String   ${test_name}   ${SPACE}   _
    # Make sure that the last video is from the current test
    IF   $test_name in $video_file
        # Save the video file if the test failed
        IF  $test_status=='FAIL' or $test_status=='SKIP'
            Log To Console        Saving video file
            SSHLibrary.Get File   /home/${USER_LOGIN}/Videos/${video_file}   ${GUI_OUTPUT_DIR}/${test_name}.mp4
        END
        Run Command   rm /home/${USER_LOGIN}/Videos/${video_file}
    END

Kill Initial Setup
    ${status}   ${output}   Run Keyword And Ignore Error   Check file exists   .config/cosmic-initial-setup-done
    IF   $status == 'FAIL'
        # Wait for the initial setup to start and kill the process. Initial setup window can mess with screenshot permission window.
        Run Keyword and Ignore Error     Check that the application was started   cosmic-initial-setup   range=15
        Kill App By Name   cosmic-initial-setup
    END
