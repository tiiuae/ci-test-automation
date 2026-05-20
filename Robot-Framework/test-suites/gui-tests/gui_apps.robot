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
    [Documentation]   Create a new document in COSMIC Text Editor, save it to Shares and verify the file was created
    [Tags]            SP-T194
    ${file_name}       Set Variable    cosmic_text_editor_save_test.txt
    ${doc_text}        Set Variable    test_content
    ${share_path}      Set Variable    /Shares/'Unsafe comms-vm share'/${file_name}

    Start app via GUI   ${GUI_VM}  cosmic-edit  display_name="COSMIC Text Editor"
    Locate on screen    image      ghaf-close.png
    Type string and press enter    ${doc_text}
    Save current document from Cosmic Text Editor to Shares   ${file_name}
    Check file exists   ${share_path}
    ${saved_content}    Run Command    cat ${share_path}
    Should Contain      ${saved_content}   ${doc_text}
    Close app via GUI   ${GUI_VM}  cosmic-edit  ghaf-close.png
    [Teardown]   Run Keywords   Remove file by name    ${file_name}
    ...    AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Copy and paste text between VMs
    [Documentation]   Copy text in COSMIC Text Editor (GUI VM) and paste it into Trusted Browser (BUSINESS VM)
    [Tags]            SP-T72
    ${clipboard_text}    Set Variable  COPYPASTE
    Start app via GUI    ${GUI_VM}     cosmic-edit  display_name="COSMIC Text Editor"
    Locate on screen     image         ghaf-close.png
    Copy text to clipboard    ${clipboard_text}
    Start app via GUI   ${BUSINESS_VM}  google-chrome  display_name="Trusted Browser"
    Paste clipboard text and verify     ${clipboard_text}
    [Teardown]    Run Keywords    Switch to vm    ${BUSINESS_VM}    AND    Kill App By Name   google-chrome   sudo=True
    ...           AND             Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ...           AND             Kill App By Name    cosmic-edit
    ...           AND             Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

Open an app from the dock
    [Documentation]   Open Zoom, minimize its window, verify it is hidden, then restore it from dock and compare coordinates.
    [Tags]            SP-T79
    Start app via GUI   ${COMMS_VM}   zoom    display_name="Zoom"
    ${zoom_window_coords}    ${zoom_anchor_coords}    Save Zoom window baseline coordinates
    Locate and click minimize window button
    Verify app window is minimized
    Locate and click   image   Zoom.png   confidence=0.90  scale=2
    Verify Zoom window restored to baseline    ${zoom_window_coords}    ${zoom_anchor_coords}
    [Teardown]   Run Keywords   Switch to vm    ${COMMS_VM}    AND    Kill App By Name   zoom   sudo=True
    ...    AND   Switch to vm    ${GUI_VM}  user=${USER_LOGIN}    AND    Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

*** Keywords ***

Save current document from Cosmic Text Editor to Shares
    [Arguments]      ${file_name}
    Press Key(s)       LEFTCTRL+LEFTSHIFT+S
    Locate on screen   text    Shares    scale=3
    Type string and press enter   ${file_name}   enter=False
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
    Locate on screen   text    Search    scale=3
    Press Key(s)       LEFTCTRL+V
    Move cursor to corner
    Verify Text Is On The Screen    ${text}

Locate and click minimize window button
    ${mouse_x}  ${mouse_y}  Locate on screen  image  ghaf-close.png  0.99  10  timeout=120  scale=2
    ${target_x}    Evaluate    ${mouse_x} - 40
    Run ydotool command   mousemove --absolute -x ${target_x} -y ${mouse_y}
    Click

Verify app window is minimized
    [Documentation]    Wait until Window disappear from the screen by checking close button
    Wait Until Keyword Succeeds    3x    1s    Verify Image On The Screen    ghaf-close.png    ${False}

Verify app window restored near coordinates
    [Arguments]    ${expected_x}   ${expected_y}   ${searched_type}=image   ${searched_item}=ghaf-close.png   ${tolerance}=5
    ${actual_x}   ${actual_y}    Locate on screen   ${searched_type}   ${searched_item}   0.99   10   timeout=120   scale=2
    ${x_in_range}    Evaluate    abs(${actual_x} - ${expected_x}) <= ${tolerance}
    ${y_in_range}    Evaluate    abs(${actual_y} - ${expected_y}) <= ${tolerance}
    IF    not ${x_in_range} or not ${y_in_range}
        FAIL    Window anchor '${searched_item}' was restored at unexpected location: expected around (${expected_x}, ${expected_y}), got (${actual_x}, ${actual_y}).
    END

Save Zoom window baseline coordinates
    ${status}   Run Keyword And Return Status   Locate on screen   image   ghaf-close.png   0.99   10   timeout=120   scale=2
    Run Keyword If    not ${status}    Focus Zoom window
    ${window_x}   ${window_y}    Locate on screen   image   ghaf-close.png   0.99   10   timeout=120   scale=2
    Focus Zoom window
    ${anchor_x}   ${anchor_y}    Locate on screen   text    Workplace        0.99   10   timeout=120   scale=2
    ${window_coords}    Create List    ${window_x}    ${window_y}
    ${anchor_coords}    Create List    ${anchor_x}    ${anchor_y}
    RETURN    ${window_coords}    ${anchor_coords}

Verify Zoom window restored to baseline
    [Arguments]    ${window_coords}    ${anchor_coords}
    Focus Zoom window
    Run Keyword And Ignore Error   Verify Image Is On The Screen    ghaf-close.png
    Run Keyword And Continue On Failure    Verify app window restored near coordinates
    ...    ${anchor_coords}[0]   ${anchor_coords}[1]   searched_type=text   searched_item=Workplace   tolerance=3
    Verify app window restored near coordinates    ${window_coords}[0]   ${window_coords}[1]

Focus Zoom window
    [Documentation]    Move the mouse on the top of the window,coordinates are hardcoded,
    ...                because App name is not always recognizable, when the text is grey
    Run ydotool command   mousemove --absolute -x 470 -y 100
    Wiggle cursor
