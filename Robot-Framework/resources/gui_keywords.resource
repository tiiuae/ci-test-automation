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
        Wait Until Keyword Succeeds    60s    1s    Verify user login session
    ELSE
        ${lock}       Check if locked
        IF  ${lock}   Unlock
    END

    Verify desktop availability   iterations=100

    Kill Initial Setup
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
        Log out with loginctl
        ${logout_status}  Check if logged out
        IF  not ${logout_status}    FAIL  Failed to log out.
    END

Log in via GUI
    [Documentation]   Log in by typing password
    Log To Console    Logging in
    # Make sure that password field is active by clicking on screen
    Run ydotool command   mousemove --absolute -x 50 -y 50   sudo=True
    Click   sudo=True

    IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep  5
    Confidential password write  ${USER_PASSWORD}

Log out with loginctl
    [Documentation]   Log out from the laptop
    # Allow disabling logout in case of running test automation locally from ghaf-host.
    # This prevents terminal from being shutdown and allows test run to finish.
    IF  $DISABLE_LOGOUT == 'true'
        Log To Console    Log out disabled. Skipping log out procedure.
        RETURN
    END
    Switch to vm   ${GUI_VM}
    Run Command    loginctl terminate-user ${USER_LOGIN}   sudo=True
    [Teardown]   Switch to vm   ${GUI_VM}  user=${USER_LOGIN}

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

Take Remote Screenshot And Download
    [Arguments]    ${from}=${SCREENSHOT_GHAF}     ${to}=${SCREENSHOT_LOCAL}
    Run Command             mkdir -p test-images
    ${_}  ${screenshot}     Take a screenshot
    SSHLibrary.Get File     ${from}  ${to}

    RETURN    ${to}

Verify Text Is On The Screen
    [Arguments]    ${text}
    ${screenshot_path}=     Take Remote Screenshot And Download
    ${is_visible}=          Is Text On The Screen   ${screenshot_path}   ${text}
    Should Be True          ${is_visible}           msg=Text '${text}' was not found on the screen

Locate on screen
    [Documentation]    Take a screenshot. Locate given image or text on the screenshot.
    ...                Return center coordinates of the item in mouse coordinate system.
    [Arguments]        ${type}  ${searched_item}  ${confidence}=0.99   ${iterations}=10   ${expected_result}=PASS  ${debug_screenshot}=True   ${timeout}=120   ${scale}=1
    [Timeout]          ${timeout} seconds
    ${coordinates}=        Set Variable  ${EMPTY}
    ${locate_status}=      Set Variable  FAIL
    Run Command            mkdir -p test-images
    FOR   ${i}   IN RANGE  ${iterations}
        Log To Console           Taking a screenshot (#${i+1})...  no_newline=True
        ${screenshot_status}  ${result}     Take a screenshot
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
    ${screenshot_status}  ${result}   Run Keyword And Ignore Error  Run Command  WAYLAND_DISPLAY=wayland-1 grim -t jpeg -q 100 ${SCREENSHOT_GHAF}   timeout=5
    ${LAST_SCREENSHOT_TIME}  Evaluate    time.time()
    Set Global Variable      ${LAST_SCREENSHOT_TIME}
    RETURN   ${screenshot_status}  ${result}

Locate and click
    [Arguments]   ${type}  ${searched_item}  ${confidence}=0.99  ${iterations}=10  ${timeout}=120  ${scale}=1  ${wiggle}=False
    ${mouse_x}  ${mouse_y}  Locate on screen  ${type}  ${searched_item}  ${confidence}  ${iterations}  timeout=${timeout}  scale=${scale}
    Run ydotool command   mousemove --absolute -x ${mouse_x} -y ${mouse_y}
    # Wiggle is sometimes needed for the window to recognize the mouse
    IF   ${wiggle}   Wiggle cursor
    Click

Click
    [Arguments]   ${double_click}=False  ${sudo}=False
    IF  ${double_click}
        Log   Double-clicking
        Run ydotool command   click 0xC0 0xC0   sudo=${sudo}
    ELSE
        Log   Clicking
        Run ydotool command   click 0xC0   sudo=${sudo}
    END

Move cursor to corner
    [Documentation]    Move the cursor to the upper left corner so that it will not block searching further gui screenshots
    Log To Console    Moving cursor to corner from blocking further image detection
    Run ydotool command   mousemove --absolute -x 50 -y 50

Wiggle cursor
    Log To Console    Moving the mouse a bit
    Run ydotool command   mousemove 1 1
    Run ydotool command   mousemove -- -1 -1

Verify desktop availability
    [Documentation]   Check that launcher icon is available on desktop
    [Arguments]       ${iterations}=30
    Log To Console    Verifying login by trying to detect the launcher icon
    Locate on screen  image  ${APP_MENU_LAUNCHER}  0.95  ${iterations}

Verify user login session
    [Documentation]   Confirm that the user has an active login session on a seat
    ${sessions}       Run Command   loginctl list-sessions | grep seat   rc_match=skip
    IF    $USER_LOGIN in $sessions
        Log   Found active GUI session for ${USER_LOGIN}   console=True
        RETURN
    END
    Log     No active GUI session found for ${USER_LOGIN}   console=True
    FAIL    User is logged out

Check if logged out
    [Documentation]    Check if system is in logged out state
    [Arguments]        ${iterations}=10
    FOR   ${i}   IN RANGE  ${iterations}
        ${status}    ${output}    Run Keyword And Ignore Error    Verify user login session
        IF    '${status}' == 'PASS'
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
    ${status}   ${output}      Run Keyword And Ignore Error   Locate on screen  image  ${LOCK_ICON}  0.95  1  debug_screenshot=False
    IF  '${status}' == 'PASS'
        Log To Console    Screen is locked
        RETURN    ${True}
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

Timestamp last screenshot
    ${current_time}  DateTime.Get Current Date  result_format=%Y%m%d_%H%M%S
    Log              Saving debug screenshot screenshot_${current_time}.jpeg   console=True
    Run Process      cp  ${SCREENSHOT_LOCAL}  ${GUI_OUTPUT_DIR}/screenshot_${current_time}.jpeg

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
            Run ydotool command   mousemove --absolute -x 500 -y 300
            Run ydotool command   click 0xC0
            Press Key(s)          ENTER
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
        # Stop the recorder gracefully so it can flush buffered frames and finalize the video file
        Kill process by name   gpu-screen-recorder   sudo=False   signal=INT
        ${stopped}    Run Keyword And Return Status   Check that the application is not running   gpu-screen-recorder   10
        IF  not ${stopped}
            Log To Console   Screen recording did not stop gracefully, force killing it
            Kill process by name   gpu-screen-recorder   sudo=False
        END
    ELSE
        Log To Console  Screen recording was not running
    END
    Save screen recording   ${test_status}   ${test_name}
    [Teardown]   Kill process by name   gpu-screen-recorder   sudo=False   require_exists=False

Save screen recording
    [Arguments]    ${test_status}   ${test_name}
    # Get the name of the last recording
    ${video_file}    Run Command   ls /home/${USER_LOGIN}/Videos -Art | tail -n 1
    # For debugging
    Run Command      ls -la /home/${USER_LOGIN}/Videos

    ${test_name}     Replace String   ${test_name}   ${SPACE}   _
    # Make sure that the last video is from the current test
    IF   $test_name in $video_file
        # Save the video file if the test failed
        IF  $test_status=='FAIL' or $test_status=='SKIP'
            Log To Console        Saving video file
            SSHLibrary.Get File   /home/${USER_LOGIN}/Videos/${video_file}   ${GUI_OUTPUT_DIR}/${video_file}
        END
        Run Command   rm /home/${USER_LOGIN}/Videos/${video_file}
    END

Kill Initial Setup
    ${status}   ${output}   Run Keyword And Ignore Error   Check file exists   .config/cosmic-initial-setup-done
    IF   $status == 'FAIL'
        # Wait for the initial setup to start
        Run Keyword and Ignore Error     Check that the application was started   cosmic-initial-setup   range=15
        # Wait until Ghaf theme is applied, this does not happen if initial setup is killed too fast
        Wait Until Keyword Succeeds   10s   0.5s   Check file exists   .config/cosmic/com.system76.CosmicTheme*
        Sleep    1
        # Kill the initial setup so that it does not interfere with tests
        Kill App By Name   cosmic-initial-setup
    END