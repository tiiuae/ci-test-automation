# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing applications via GUI
Test Tags           gui-apps  lenovo-x1  darter-pro

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Test Cases ***

Create and save text file from COSMIC Text Editor via GUI
    [Documentation]   Create a new document in ${COSMIC Text Editor}[display_name], save it to Shares and verify the file was created
    [Tags]            SP-T194
    ${file_name}       Set Variable    cosmic_text_editor_save_test.txt
    ${doc_text}        Set Variable    test_content
    ${share_path}      Set Variable    /Shares/'Unsafe comms-vm share'/${file_name}

    Start app via GUI   ${COSMIC Text Editor}
    Locate on screen    image      ${COSMIC Text Editor}[close_button]
    Type string         ${doc_text}   enter_at_end=True
    Save current document from COSMIC Text Editor to Shares   ${file_name}
    Check file exists   ${share_path}
    ${saved_content}    Run Command    cat ${share_path}
    Should Contain      ${saved_content}   ${doc_text}
    Close app via GUI   ${COSMIC Text Editor}
    [Teardown]   Run Keywords   Kill App in VM   ${COSMIC Text Editor}   require_exists=False
    ...    AND   Switch to vm            ${GUI_VM}        user=${USER_LOGIN}
    ...    AND   Remove file by name     ${file_name}
    ...    AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Copy and paste text between VMs
    [Documentation]   Copy text in ${COSMIC Text Editor}[display_name] and paste it into ${Trusted Browser}[display_name]
    [Tags]            SP-T72
    ${clipboard_text}    Set Variable  COPYPASTE
    Start app via GUI    ${COSMIC Text Editor}
    Locate on screen     image         ${COSMIC Text Editor}[close_button]
    Copy text to clipboard    ${clipboard_text}
    Start app via GUI    ${Trusted Browser}
    Paste clipboard text and verify     ${clipboard_text}
    [Teardown]    Run Keywords    Kill App in VM   ${Trusted Browser}
    ...           AND             Kill App in VM   ${COSMIC Text Editor}
    ...           AND             Switch to vm     ${GUI_VM}        user=${USER_LOGIN}
    ...           AND             Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Open an app from the dock
    [Documentation]   Open Zoom, minimize its window, verify it is hidden, then restore it from dock and compare coordinates.
    [Tags]            SP-T79
    Start app via GUI    ${Zoom}
    ${zoom_window_coords}    ${zoom_anchor_coords}    Save Zoom window baseline coordinates
    ${zoom_before_x}   ${zoom_before_y}    Save Zoom icon coordinates
    Locate and click minimize window button
    Verify app window is minimized
    Wait for Zoom icon coordinates to change and restore window    ${zoom_before_x}    ${zoom_before_y}
    Verify Zoom window restored to baseline    ${zoom_window_coords}    ${zoom_anchor_coords}
    [Teardown]   Run Keywords    Kill App in VM   ${Zoom}
    ...    AND   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}    AND    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Maximize and restore window
    [Documentation]   Open Zoom, maximize its window, verify it, then restore it and compare coordinates.
    [Tags]            SP-T78
    Start app via GUI    ${Zoom}
    ${zoom_window_coords}    ${zoom_anchor_coords}    Save Zoom window baseline coordinates
    Locate and click maximize/restore window button   ${Zoom}
    Verify app window is maximized   ${Zoom}
    Locate and click maximize/restore window button   ${Zoom}
    Verify Zoom window restored to baseline    ${zoom_window_coords}    ${zoom_anchor_coords}
    [Teardown]   Run Keywords    Kill App in VM   ${Zoom}
    ...    AND   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}    AND    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Verify Gala is loaded
    [Documentation]   Open Gala and wait the window to be loaded
    [Tags]            SP-T108
    Start app via GUI   ${Gala}
    Verify Gala sign in arrow load time
    Close app via GUI   ${Gala}
    [Teardown]   Run Keywords    Kill App in VM   ${Gala}   require_exists=False
    ...    AND   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}    AND    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Trusted Browser opens blocked page in normal browser
    [Documentation]    Open blocked Yle in ${Trusted Browser}[display_name], then open it in ${Google Chrome}[display_name].
    [Tags]             SP-T220
    Open restricted page in Trusted Browser
    Verify page is blocked in Trusted Browser
    Forward page to normal browser
    Verify page opened in normal browser
    [Teardown]   Run Keywords    Kill App in VM   ${Google Chrome}   require_exists=False
    ...    AND   Kill App in VM   ${Trusted Browser}   require_exists=False
    ...    AND   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}    AND    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Ghaf Control Panel shows device information
    [Documentation]    Open Ghaf Control Panel 'About' page and verify device information matches system data.
    [Tags]             SP-T370
    Start app via GUI   ${Ghaf Control Panel}
    Navigate To Device Information Page
    Verify Device Information
    [Teardown]     Ghaf Control Panel Test Teardown

Take a screenshot via Print Screen
    [Documentation]   Open screenshot tool with PrtSc, take a screenshot with Enter, and verify the image was saved to Pictures
    [Tags]            SP-T171
    Set Test Variable   ${screenshots_dir}    /home/${USER_LOGIN}/Pictures/Screenshots
    Run Command         mkdir -p ${screenshots_dir}
    Open Folder In COSMIC Files    ${screenshots_dir}    Screenshots
    ${expected_screenshot_pattern}    Take Screenshot With Print Screen
    ${screenshot}    Wait Until Keyword Succeeds    5x    1s    Get Saved Screenshot    ${expected_screenshot_pattern}
    Verify Saved Screenshot Contains Text    ${screenshot}    Screenshots
    [Teardown]   Run Keywords   Remove file    ${screenshot}
    ...    AND   Kill App in VM   ${COSMIC Files}
    ...    AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Record screen with keyboard shortcut
    [Documentation]   Start and stop screen recording with Ctrl+Shift+Alt+R, then verify the recorded video is visible in Videos
    [Tags]            SP-T296
    [Setup]           Screen Recording Test Setup
    Open Folder In COSMIC Files    ${videos_dir}    Videos
    ${videos_before}    Get Videos Folder Recording List
    Start Screen Recording With Shortcut
    Stop Screen Recording With Shortcut
    ${recorded_video}   Wait Until Keyword Succeeds    10x    1s    Get New Saved Screen Recording    ${videos_before}
    Verify Video Is Visible In COSMIC Files    ${recorded_video}
    [Teardown]        Screen Recording Test Teardown


*** Keywords ***

Verify Gala sign in arrow load time
    [Arguments]    ${expected_max_seconds}=10    ${timeout_seconds}=60
    ${start_time}    Get Time    epoch
    ${status}        Run Keyword And Return Status    Wait Until Keyword Succeeds    ${timeout_seconds}s    1s
    ...              Verify Image On The Screen    gala_signin_arrow.png    confidence=0.8
    ${end_time}      Get Time    epoch
    ${elapsed}       Evaluate    ${end_time} - ${start_time}
    IF    not ${status}
        FAIL    Gala window still does not contain sign in arrow after approximately ${elapsed} seconds.
    END
    Log    Gala sign in arrow appeared in approximately ${elapsed} seconds.    console=True
    IF    ${elapsed} > ${expected_max_seconds}
        Log Error    Slow Gala    Gala took ${elapsed} seconds to open
        SKIP    Known Issue: SSRCSP-8855 (Gala page loaded in approximately ${elapsed} seconds, expected less than ${expected_max_seconds} seconds.)
    END

Navigate To Device Information Page
    [Documentation]   Open the 'About' page from the initial Services view.
    Open Ghaf Control Panel Settings
    Locate and click   text   About

Open Ghaf Control Panel Settings
    [Documentation]   Click Settings by offset from the close button because OCR does not reliably detect the tab text.
    ...               Offsets are in ydotool mouse coordinates: Settings center is about 33 px left and 30 px down
    ...               from the Ghaf Control Panel close button center.
    ${close_x}   ${close_y}   Locate on screen   image   ${Ghaf Control Panel}[close_button]   0.90
    ${settings_x}   Evaluate   ${close_x} - 33
    ${settings_y}   Evaluate   ${close_y} + 30
    Run ydotool command   mousemove --absolute -x ${settings_x} -y ${settings_y}
    Click

Verify Device Information
    ${ghaf_version}     Get Ghaf Version
    ${device_id}        Get Actual Device ID
    ${sysinfo}          Run Command   givc-cli sysinfo
    ${secure_boot}      Get givc-cli sysinfo field   ${sysinfo}   Secure Boot
    ${disk_encryption}  Get givc-cli sysinfo field   ${sysinfo}   Disk Encryption
    ${device_info_failures}         Create List
    ${device_info_unknown_fields}   Create List
    Set Test Variable   ${device_info_failures}
    Set Test Variable   ${device_info_unknown_fields}

    Check Device Information Field   Ghaf Version       ${ghaf_version}     scale=3
    Check Device Information Field   Device ID          ${device_id}        scale=3
    Check Device Information Field   Secure Boot        ${secure_boot}
    Check Device Information Field   Disk Encryption    ${disk_encryption}

    IF    $device_info_failures          FAIL    ${device_info_failures}
    IF    $device_info_unknown_fields    SKIP    Known issue: SSRCSP-8770 (value 'unknown' for ${device_info_unknown_fields})

Ghaf Control Panel Test Teardown
    Kill App in VM                 ${Ghaf Control Panel}    require_exists=False
    Switch to vm                   ${GUI_VM}    user=${USER_LOGIN}
    Stop screen recording          ${TEST_STATUS}   ${TEST_NAME}
    Run Keyword If Test Failed     Log Error    Ghaf Control Panel     Ghaf Control Panel test failed

Check Device Information Field
    [Arguments]    ${field}    ${expected}   ${scale}=2
    ${screenshot_path}  Take Remote Screenshot And Download
    ${actual}           Get Text Field From Image   ${screenshot_path}   ${field}   scale=${scale}
    IF    '${actual.strip().lower()}' == 'unknown'
        Append To List    ${device_info_unknown_fields}    ${field}
        RETURN
    END
    ${matches}    Run Keyword And Return Status    Should Be Equal As Strings    ${actual}    ${expected}    ignore_case=True
    IF    not ${matches}
        Append To List    ${device_info_failures}    ${field} value in Ghaf Control Panel is ${actual}, expected ${expected}
    END

Get givc-cli sysinfo field
    [Arguments]    ${output}    ${field}
    ${matches}     Get Regexp Matches    ${output}    (?m)^${field}:\\s*(\\S(?:.*\\S)?)\\s*$    1
    Should Not Be Empty    ${matches}    Could not find ${field} in givc-cli sysinfo output:\n${output}
    RETURN         ${matches}[0]

Open Folder In COSMIC Files
    [Arguments]    ${folder}    ${folder_name}
    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
    Start App in VM    ${COSMIC Files}    always_check_vm=True    params_string=-- ${folder}
    Locate on screen   text    ${folder_name}    iterations=10    scale=3
    # Fullscreen window to make sure whole file name can be seen
    Locate and click maximize/restore window button   ${COSMIC Files}
    Verify app window is maximized   ${COSMIC Files}
    Move cursor to corner

Take Screenshot With Print Screen
    Press Key(s)       PRINT
    Wait Until Keyword Succeeds    5x    0.5s    Check that process is running    ${COSMIC Screenshot}[process_name]
    ${expected_screenshot_pattern}    Run Command    date '+Screenshot_%F_%H-%M-[0-9][0-9].png'
    Press Key(s)       ENTER
    RETURN             ${expected_screenshot_pattern}

Get Saved Screenshot
    [Arguments]    ${expected_screenshot_pattern}
    ${screenshot}    Run Command    ls -t ${screenshots_dir}/${expected_screenshot_pattern} | head -n 1
    Should Not Be Empty    ${screenshot}
    ...    New screenshot matching ${expected_screenshot_pattern} was not created under ${screenshots_dir}.
    RETURN    ${screenshot}

Verify Saved Screenshot Contains Text
    [Arguments]    ${screenshot}    ${text}
    ${local_screenshot}    Set Variable    ${GUI_OUTPUT_DIR}/saved_screenshot.png
    SSHLibrary.Get File    ${screenshot}    ${local_screenshot}
    Locate text    ${local_screenshot}    ${text}    scale=2

Screen Recording Test Setup
    Set Test Variable   ${videos_dir}        /home/${USER_LOGIN}/Videos
    Set Test Variable   ${recorded_video}    ${EMPTY}

Start Screen Recording With Shortcut
    Press Key(s)    LEFTCTRL+LEFTSHIFT+LEFTALT+R
    Select a display to record
    Wait Until Keyword Succeeds    10x    0.5s    Check that process is running    ${GPU Screen Recorder}[recording_process_name]

Stop Screen Recording With Shortcut
    Press Key(s)    LEFTCTRL+LEFTSHIFT+LEFTALT+R
    Wait Until Keyword Succeeds    20x    0.5s    Check that process is not running    ${GPU Screen Recorder}[recording_process_name]

Get Videos Folder Recording List
    ${videos}    Run Command    ls -1 ${videos_dir}/*.mp4    rc_match=skip
    RETURN       ${videos}

Get New Saved Screen Recording
    [Arguments]    ${videos_before}
    ${videos_after}    Get Videos Folder Recording List
    @{videos_before}   Split To Lines    ${videos_before}
    @{videos_after}    Split To Lines    ${videos_after}
    Remove Values From List    ${videos_after}    @{videos_before}
    Should Not Be Empty    ${videos_after}    New screen recording was not created under ${videos_dir}.
    ${recorded_video}      Set Variable    ${videos_after}[0]
    Run Command            test -s '${recorded_video}'
    RETURN                 ${recorded_video}

Verify Video Is Visible In COSMIC Files
    [Arguments]    ${recorded_video}
    ${recorded_video_name}    Run Command    basename ${recorded_video}
    ${recording_pattern}    Replace String    ${recorded_video_name}    ghaf-    ${EMPTY}
    Locate on screen   text    Videos    iterations=10    scale=2
    Locate on screen   text    ${recording_pattern}    iterations=15    scale=2

Screen Recording Test Teardown
    Kill process by name    ${GPU Screen Recorder}[recording_process_name]    sudo=False    require_exists=False
    Kill App in VM     ${COSMIC Files}
    Run Keyword If    '${recorded_video}' != '${EMPTY}' and '${TEST_STATUS}' != 'PASS'    Save Recorded Shortcut Video    ${recorded_video}
    Run Keyword If    '${recorded_video}' != '${EMPTY}'    Remove file    ${recorded_video}

Save Recorded Shortcut Video
    [Arguments]    ${recorded_video}
    ${recorded_video_name}    Run Command    basename ${recorded_video}
    SSHLibrary.Get File    ${recorded_video}    ${GUI_OUTPUT_DIR}/${recorded_video_name}

Save current document from COSMIC Text Editor to Shares
    [Arguments]      ${file_name}
    Press Key(s)       LEFTCTRL+LEFTSHIFT+S
    Locate on screen   text    Shares    scale=3
    Type string        ${file_name}
    Locate and click   text   Shares
    Locate and click   text   comms-vm    wiggle=True   double_click=True
    Press Key(s)       ENTER

Copy text to clipboard
    [Arguments]    ${text}
    Run ydotool command  type ${text}
    Press Key(s)         LEFTCTRL+A
    Press Key(s)         LEFTCTRL+C
    Press Key(s)         BACKSPACE

Paste clipboard text and verify
    [Arguments]    ${text}
    Accept Chrome Terms Of Service If Shown
    Locate on screen   image   open-normal-browser.png   confidence=0.80
    Press Key(s)       LEFTCTRL+V
    Move cursor to corner
    Verify Text Is On The Screen    ${text}

Open restricted page in Trusted Browser
    Start App in VM    ${Trusted Browser}    params_string=-- https://yle.fi    always_check_vm=True
    Switch to vm       ${GUI_VM}    user=${USER_LOGIN}
    Accept Chrome Terms Of Service If Shown

Verify page is blocked in Trusted Browser
    Switch to vm       ${GUI_VM}    user=${USER_LOGIN}
    Wait Until Keyword Succeeds    10x    1s    Verify Text Is On The Screen    This site can’t be reached
    Verify Text Is On The Screen    Uutiset    expected=${False}    scale=2

Forward page to normal browser
    Locate and click   image   open-normal-browser.png   confidence=0.80   iterations=20   scale=2

Verify page opened in normal browser
    Check that App is running in VM    ${Google Chrome}    range=10
    Switch to vm       ${GUI_VM}    user=${USER_LOGIN}
    Accept Chrome Terms Of Service If Shown
    Skip Chrome sign-in prompt if shown
    Wait Until Keyword Succeeds    10x    1s
    ...    Run Keywords
    ...    Accept Chrome Terms Of Service If Shown    attempts=1    interval=0s
    ...    AND    Verify Text Is On The Screen    Uutiset    scale=2

Skip Chrome sign-in prompt if shown
    [Documentation]    Chrome sign-in prompt is shown not every time
    ${status}    Run Keyword And Return Status      Wait Until Keyword Succeeds    3x    1s   Verify Text Is On The Screen    Sign in to Chrome
    Run Keyword If    ${status}    Tab and enter   tabs=1

Locate and click minimize window button
    ${mouse_x}  ${mouse_y}  Locate on screen  image  ${Zoom}[close_button]  0.99  10  timeout=120  scale=2
    ${target_x}    Evaluate    ${mouse_x} - 40
    Run ydotool command   mousemove --absolute -x ${target_x} -y ${mouse_y}
    Click

Verify app window is minimized
    [Documentation]    Wait until Window disappear from the screen by checking close button
    Wait Until Keyword Succeeds    3x    1s    Verify Image On The Screen    ${Zoom}[close_button]    ${False}

Verify app window restored near coordinates
    [Arguments]    ${expected_x}   ${expected_y}   ${searched_type}=image   ${searched_item}=${Zoom}[close_button]   ${tolerance}=5
    ${actual_x}   ${actual_y}    Locate on screen   ${searched_type}   ${searched_item}   0.99   10   timeout=120   scale=2
    ${x_in_range}    Evaluate    abs(${actual_x} - ${expected_x}) <= ${tolerance}
    ${y_in_range}    Evaluate    abs(${actual_y} - ${expected_y}) <= ${tolerance}
    IF    not ${x_in_range} or not ${y_in_range}
        FAIL    Window anchor '${searched_item}' was restored at unexpected location: expected around (${expected_x}, ${expected_y}), got (${actual_x}, ${actual_y}).
    END

Save Zoom window baseline coordinates
    Accept Chrome Terms Of Service If Shown    attempts=3
    ${status}   Run Keyword And Return Status   Locate on screen   image   ${Zoom}[close_button]   0.99   10   timeout=120   scale=2
    Run Keyword If    not ${status}    Focus Zoom window
    ${window_x}   ${window_y}    Locate on screen   image   ${Zoom}[close_button]   0.99   10   timeout=120   scale=2
    Focus Zoom window
    ${anchor_x}   ${anchor_y}    Locate on screen   text    Workplace        0.99   10   timeout=120   scale=2
    ${window_coords}    Create List    ${window_x}    ${window_y}
    ${anchor_coords}    Create List    ${anchor_x}    ${anchor_y}
    RETURN    ${window_coords}    ${anchor_coords}

Verify Zoom window restored to baseline
    [Arguments]    ${window_coords}    ${anchor_coords}
    Focus Zoom window
    Run Keyword And Ignore Error   Verify Image On The Screen    ${Zoom}[close_button]
    Run Keyword And Continue On Failure    Verify app window restored near coordinates
    ...    ${anchor_coords}[0]   ${anchor_coords}[1]   searched_type=text   searched_item=Workplace   tolerance=3
    Verify app window restored near coordinates    ${window_coords}[0]   ${window_coords}[1]

Focus Zoom window
    [Documentation]    Move the mouse on the top of the window,coordinates are hardcoded,
    ...                because App name is not always recognizable, when the text is grey
    Run ydotool command   mousemove --absolute -x 470 -y 100
    Wiggle cursor

Save Zoom icon coordinates
    ${zoom_x}   ${zoom_y}    Locate on screen   image   ${Zoom}[icon]   0.80   10   timeout=120   scale=2
    RETURN    ${zoom_x}    ${zoom_y}

Wait for Zoom icon coordinates to change and restore window
    [Arguments]    ${old_x}    ${old_y}
    FOR    ${i}    IN RANGE    5
        ${new_x}   ${new_y}    Locate on screen   image   ${Zoom}[icon]   0.90   10   timeout=10   scale=2
        ${changed}    Evaluate    abs(${new_x} - ${old_x}) > 2 or abs(${new_y} - ${old_y}) > 2
        IF    ${changed}
            Locate and click   image   ${Zoom}[icon]   confidence=0.90  scale=2
            RETURN
        END
    END
    FAIL    An additional minimized Zoom session icon hasn't appeared.

Locate and click maximize/restore window button
    [Arguments]    ${app}   ${tolerance}=3
    ${mouse_x}  ${mouse_y}  Locate on screen  image  ${app}[close_button]  0.99  10  timeout=120  scale=2
    ${target_x}    Evaluate    ${mouse_x} - 20
    Run ydotool command   mousemove --absolute -x ${target_x} -y ${mouse_y}
    Click   wiggle=True

Verify app window is maximized
    [Arguments]    ${app}   ${tolerance}=3
    ${window_x}   ${window_y}    Locate on screen   image   ${app}[close_button]   0.99   10   timeout=120   scale=2
    ${x_in_range}    Evaluate    abs(${window_x} - 947) <= ${tolerance}
    ${y_in_range}    Evaluate    abs(${window_y} - 25) <= ${tolerance}
