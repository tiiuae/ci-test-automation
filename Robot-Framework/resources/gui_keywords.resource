# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Keywords for gui tests. Note: These keywords assume the connection is to the gui-vm
...                 as the non-privileged user.

Library             ../lib/GuiTesting.py    ${OUTPUT_DIR}/outputs/gui-temp/
Library             Collections
Library             DateTime
Resource            ../resources/app_keywords.resource
Resource            ../resources/file_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Variables ***
${APP_MENU_LAUNCHER}   ./launcher.png
${LOCK_ICON}           ./lock.png
${DISABLE_LOGOUT}      ${EMPTY}
${GUI_TEMP_DIR}        ${OUTPUT_DIR}/outputs/gui-temp
${YDOTOOL_SOCKET}      /tmp/.ydotool_socket
${SCREEN_SELECTED}     ${False}
${FIRST_SCREENSHOT}    ${True}


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

    Stop swayidle
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
    [Arguments]        ${type}  ${searched_item}  ${confidence}=0.999   ${iterations}=10   ${fail_expected}=False  ${debug_screenshot}=True
    [Timeout]          2 minutes
    ${coordinates}=        Set Variable  ${EMPTY}
    ${pass_status}=        Set Variable  FAIL
    Execute Command        mkdir test-images
    ${screenshot_cmd}=     Set Variable  cosmic-screenshot --interactive=false --save-dir ./test-images
    IF   ${FIRST_SCREENSHOT}==${True}   Allow first screenshot
    FOR   ${i}   IN RANGE  ${iterations}
        Log To Console     Taking cosmic screenshot
        ${result}=         Run Keyword And Ignore Error  Execute Command  ${screenshot_cmd}  return_stdout=True  return_rc=True  timeout=5
        ${LAST_SCREENSHOT_TIME}  Evaluate    time.time()
        Set Global Variable      ${LAST_SCREENSHOT_TIME}
        Log                ${result}
        IF  "${result}[1][1]" == "0"
            SSHLibrary.Get File  ${result[1][0]}  ${GUI_TEMP_DIR}/screenshot.png
            IF  $type=="image"
                Log To Console    Locating image ${searched_item} on ${result[1][0]}
                ${pass_status}    ${coordinates}  Run Keyword And Ignore Error  Locate image  ${GUI_TEMP_DIR}/${searched_item}   ${confidence}
            ELSE IF  $type=="text"
                Log To Console    Locating text ${searched_item} on ${result[1][0]}
                ${pass_status}    ${coordinates}  Run Keyword And Ignore Error  Locate text  ${searched_item}
            ELSE
                FAIL              Wrong type given for image recognition
            END
        END
        IF    $pass_status=='PASS'
            IF  ${fail_expected} and ${debug_screenshot}
                Timestamp screenshot
                Log     Image recognition succeeded but fail_expected=${fail_expected}    console=True
            END
            BREAK
        END
        Sleep  0.5
    END
    IF  $pass_status=='FAIL' and ${debug_screenshot} and not ${fail_expected}
        Timestamp screenshot
        FAIL  Image recognition failure: ${searched_item}
    END
    IF  $pass_status=='PASS'
        Log   Coordinates: ${coordinates}  console=True
    ELSE
        Log   Could not find ${type}: ${searched_item}  console=True
    END
    ${mouse_x}  Get From Dictionary   ${coordinates}  x
    ${mouse_y}  Get From Dictionary   ${coordinates}  y
    RETURN  ${mouse_x}  ${mouse_y}

Allow first screenshot
    [Documentation]   Allow screenshot tool take screenshots. Permission must be given on first use.
    # Launch a background process that tries to take a screenshot.
    Execute Command    nohup sh -c 'cosmic-screenshot --interactive=false --save-dir ./test-images' > screenshot.log 2>&1 &
    Sleep   2
    ${output}    Execute Command   cat screenshot.log
    ${screenshot_passed}     Run Keyword And Return Status    Should Contain    ${output}   Screenshot
    # If taking a screenshot did not work select "Allow" in the permission window.
    IF    not ${screenshot_passed}
        Sleep  5
        IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep  10
        # Click the permission window to make sure it is active
        Run ydotool command   mousemove --absolute -x 500 -y 200
        Run ydotool command   click 0xC0
        Move cursor to corner
        Tab and enter   tabs=2
    END
    # For a Dell bug, try the same again
    IF  "${DEVICE_TYPE}" == "dell-7330"
        # Launch a background process that tries to take a screenshot.
        Execute Command    nohup sh -c 'cosmic-screenshot --interactive=false --save-dir ./test-images' > screenshot.log 2>&1 &
        Sleep   2
        ${output}    Execute Command   cat screenshot.log
        ${screenshot_passed}     Run Keyword And Return Status    Should Contain    ${output}   Screenshot
        # If taking a screenshot did not work select "Allow" in the permission window.
        IF    not ${screenshot_passed}
            Log To Console    BUG with screenshot tool, allowing screenshot again
            Sleep  5
            IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep  10
            # Click the permission window to make sure it is active
            Run ydotool command   mousemove --absolute -x 500 -y 200
            Run ydotool command   click 0xC0
            Move cursor to corner
            Tab and enter   tabs=2
        END
    END
    Set Global Variable  ${FIRST_SCREENSHOT}  ${False}

Locate and click
    [Arguments]   ${type}  ${searched_item}  ${confidence}=0.99  ${iterations}=10
    ${mouse_x}  ${mouse_y}  Locate on screen  ${type}  ${searched_item}  ${confidence}  ${iterations}
    Run ydotool command   mousemove --absolute -x ${mouse_x} -y ${mouse_y}
    Run ydotool command   click 0xC0

Move cursor to corner
    [Documentation]    Move the cursor to the upper left corner so that it will not block searching further gui screenshots
    Log To Console    Moving cursor to corner from blocking further image detection
    Run ydotool command   mousemove --absolute -x 50 -y 50

Verify desktop availability
    [Documentation]    Wait for the login and check that launcher icon is available on desktop
    [Arguments]        ${logging_in}=False

    ${activity}        Wait for user session to be active

    # Give extra time if the service is still activating
    IF  $activity == "activating"
        Log To Console     User-session is ${activity}, login in process
        ${activity}        Wait for user session to be active   iterations=60
    END

    IF  $activity != "active"    FAIL    User-session did not activate, it is ${activity}
    IF  "${DEVICE_TYPE}" == "dell-7330"    Sleep   10

    # For debugging, check gui-vm systemctl status before trying to take a cosmic-screenshot in case it gets stuck
    Run Keyword And Ignore Error   Verify Systemctl status   range=1
    Run Keyword And Ignore Error   Verify Systemctl status   range=1   user=True

    IF  ${logging_in}   Kill Initial Setup

    Log To Console         Verifying login by trying to detect the launcher icon
    # This is a workaround for launcher icon missing sometimes. If launcher icon can't be found tries to search
    # for the power menu icon. Gui-vm user log is saved to help debugging.
    ${status}   ${output}   Run Keyword And Ignore Error   Locate on screen  image  ${APP_MENU_LAUNCHER}  0.95  20
    IF   $status == 'FAIL'
        Get gui-vm user journalctl log
        Log To Console    Could not find launcher icon, checking for power menu icon
        Locate on screen  image  ./power.png  0.95  10
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
        ${activity}=       Execute Command    systemctl --user is-active xdg-desktop-portal.service  return_stdout=True
        IF  $activity == "active"
            Log      User session is ${activity}, user is logged in  console=True
        ELSE
            Log      User session is ${activity}, user is logged out  console=True
            RETURN    ${True}
        END
        Sleep  1
    END
    RETURN    ${False}

Wait for user session to be active
    [Documentation]    Wait until the user session is in active state
    [Arguments]        ${iterations}=30
    Log To Console     Waiting for the user session to be active...  no_newline=true 
    FOR   ${i}   IN RANGE   ${iterations}
        ${activity}=       Execute Command    systemctl --user is-active xdg-desktop-portal.service  return_stdout=True
        IF  $activity == "active"
            Log    Success  console=True
            Log    User session is ${activity}, user is logged in  console=True
            BREAK
        END
        Log To Console   ${i}.  no_newline=true
        Sleep   0.5
    END
    RETURN   ${activity}

Get icon
    [Documentation]    Copy icon svg file to test agent machine. Crop and convert the svg file to png.
    [Arguments]        ${path}   ${icon_name}   ${crop}=0   ${background}=none   ${output_filename}=icon.png
    SSHLibrary.Get File  ${path}/${icon_name}   ${GUI_TEMP_DIR}/icon.svg
    Convert app icon  ${crop}   ${background}   input_file=${GUI_TEMP_DIR}/icon.svg  output_file=${GUI_TEMP_DIR}/${output_filename}

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

Stop swayidle
    [Documentation]    Stop swayidle to prevent automatic suspension
    Log To Console    Disabling automated lock and suspend
    Execute Command   systemctl --user stop swayidle

Start swayidle
    [Documentation]    Start swayidle to allow automatic suspension
    Log To Console    Enabling automated lock and suspend
    Execute Command   systemctl --user start swayidle

Set do not disturb state
    [Documentation]   Set do not disturb to true or false
    [Arguments]       ${state}
    Log To Console    Setting Do Not Disturb to ${state}
    Execute Command   echo ${state} > ~/.config/cosmic/com.system76.CosmicNotifications/v1/do_not_disturb
    # Make sure that currently shown notifications get closed
    IF   $state == "true"
        Execute Command   echo 0 > ~/.config/cosmic/com.system76.CosmicNotifications/v1/max_notifications
    ELSE
        Execute Command   echo 3 > ~/.config/cosmic/com.system76.CosmicNotifications/v1/max_notifications
    END

Get gui-vm user journalctl log
    [Arguments]       ${filename}=gui-vm-user.txt
    Execute Command   journalctl --user > /tmp/${filename}
    SSHLibrary.Get file   /tmp/${filename}   ${OUTPUT_DIR}/${filename}
    OperatingSystem.File Should Exist   ${OUTPUT_DIR}/${filename}

Timestamp screenshot
    ${current_time}  DateTime.Get Current Date  result_format=%Y%m%d_%H%M%S
    Run Process      sh  -c  cp ${GUI_TEMP_DIR}/screenshot.png ${GUI_TEMP_DIR}/screenshot_${current_time}.png  shell=true

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

Run ydotool command
    [Arguments]    ${command}   ${sudo}=False
    IF   $sudo == "True"
        Switch to vm    ${GUI_VM}
        Log To Console   Running ydotool command with ghaf user
        ${output}    ${rc}    Execute Command   ydotool ${command}  sudo=True  sudo_password=${PASSWORD}    return_rc=True
        Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ELSE
        ${output}    ${rc}    Execute Command    YDOTOOL_SOCKET=${YDOTOOL_SOCKET} ydotool ${command}    return_rc=True
    END
    Should Be Equal As Integers     ${rc}   0
    Sleep   0.2

Change to gray wallpaper
    Log To Console    Changing to gray wallpaper
    Put File          ../test-files/background.config   .
    Execute Command   mv background.config .config/cosmic/com.system76.CosmicBackground/v1/all

Restore default wallpaper
    Log To Console    Changing back to default wallpaper
    Remove file       ~/.config/cosmic/com.system76.CosmicBackground/v1/all

Start screen recording
    [Setup]          Kill App By Name   gpu-screen-recorder
    Log To Console   Starting screen recording
    Press key(s)     LEFTCTRL+LEFTSHIFT+LEFTALT+R
    IF   ${SCREEN_SELECTED}==${False}
        # The window to record needs to be selected when recording first time
        # Check if selection window opened
        ${pass_status}  ${output}  Run Keyword And Ignore Error   Locate on screen   text   Share   iterations=5
        IF  $pass_status=='PASS'
            # Select the display to record
            Tab and enter    tabs=3
            Tab and enter    tabs=2
        END
        Set Global Variable  ${SCREEN_SELECTED}  ${True}
    END
    Check that the application was started   gpu-screen-recorder
        

Stop screen recording
    [Arguments]      ${test_status}   ${test_name}=""
    ${pass_status}   ${output}    Run Keyword And Ignore Error   Check that the application was started   gpu-screen-recorder
    IF  $pass_status=='FAIL'
        Log To Console  Screen recording was not running
        RETURN
    END
    Log To Console   Stopping screen recording
    Press key(s)     LEFTCTRL+LEFTSHIFT+LEFTALT+R
    Kill App By Name   gpu-screen-recorder
    # Get the name of the last recording
    ${video_file}    Execute Command   ls /home/${USER_LOGIN}/Videos -Art | tail -n 1
    # Save the video file if the test failed
    IF  $test_status=='FAIL' or $test_status=='SKIP'
        Log To Console        Saving video file
        ${name}               Replace String   ${test_name}   ${SPACE}   _
        SSHLibrary.Get File   /home/${USER_LOGIN}/Videos/${video_file}   ${GUI_TEMP_DIR}/${name}.mp4
    END
    Execute Command   rm /home/${USER_LOGIN}/Videos/${video_file}
    [Teardown]        Kill App By Name   gpu-screen-recorder

Kill Initial Setup
    ${status}   ${output}   Run Keyword And Ignore Error   Check file exists   .config/cosmic-initial-setup-done
    IF   $status == 'FAIL'
        # Wait for the initial setup to start and kill the process. Initial setup window can mess with screenshot permission window.
        Run Keyword and Ignore Error     Check that the application was started   cosmic-initial-setup   range=15
        Kill App By Name   cosmic-initial-setup
    END
