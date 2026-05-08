# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications via GUI
Test Tags           gui-apps  lenovo-x1  darter-pro

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Test Cases ***

Start and close Google Chrome via GUI
    [Documentation]   Start Google Chrome via GUI and verify related process started
    ...               Close Google Chrome via GUI and verify related process stopped
    [Tags]            SP-T41
    Start app via GUI   ${CHROME_VM}  chrome  display_name="Google Chrome"
    Close app via GUI   ${CHROME_VM}  chrome  ghaf-close.png   2

Start and close COSMIC Document Reader via GUI
    [Documentation]   Start COSMIC Document Reader via GUI and verify related process started
    ...               Close COSMIC Document Reader via GUI and verify related process stopped
    [Tags]            SP-T70
    Start app via GUI   ${GUI_VM}  cosmic-reader   display_name="COSMIC Document Reader"
    Close app via GUI   ${GUI_VM}  cosmic-reader   ghaf-close.png

Start and close Sticky Notes via GUI
    [Documentation]   Start Sticky Notes via GUI and verify related process started
    ...               Close Sticky Notes via GUI and verify related process stopped
    [Tags]            SP-T201  SP-T201-2
    Start app via GUI   ${GUI_VM}  sticky-wrapped  display_name="Sticky Notes"
    Close app via GUI   ${GUI_VM}  sticky-wrapped  window-close-neg.png

Start and close Calculator via GUI
    [Documentation]   Start Calculator via GUI and verify related process started
    ...               Close Calculator via GUI and verify related process stopped
    [Tags]            SP-T202  SP-T202-2
    Start app via GUI   ${GUI_VM}  gnome-calculator  display_name=Calculator
    Close app via GUI   ${GUI_VM}  gnome-calculator  window-close-neg.png

Start and close Bluetooth Settings via GUI
    [Documentation]   Start Bluetooth Settings via GUI and verify related process started
    ...               Close Bluetooth Settings via GUI and verify related process stopped
    [Tags]            SP-T204  SP-T204-2
    Start app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  display_name="Bluetooth Settings"
    Close app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  window-close.png

Start and close Ghaf Control Panel via GUI
    [Documentation]   Start Ghaf Control Panel via GUI and verify related process started
    ...               Close Ghaf Control Panel via GUI and verify related process stopped
    [Tags]            SP-T205  SP-T205-2
    Start app via GUI   ${GUI_VM}  ctrl-panel  display_name="Ghaf Control Panel"
    Close app via GUI   ${GUI_VM}  ctrl-panel  window-close-neg.png
    
Start and close COSMIC Files via GUI
    [Documentation]   Start COSMIC Files via GUI and verify related process started
    ...               Close COSMIC Files via GUI and verify related process stopped
    [Tags]            SP-T206  SP-T206-2
    Start app via GUI   ${GUI_VM}  ^cosmic-files$  display_name="COSMIC Files"
    Close app via GUI   ${GUI_VM}  ^cosmic-files$  ghaf-close.png

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
    [Documentation]   Copy text in COSMIC Text Editor (GUI VM) and paste it into Slack (COMMS VM)
    [Tags]            SP-T72
    ${clipboard_text}    Set Variable  COPYPASTE
    Start app via GUI    ${GUI_VM}     cosmic-edit  display_name="COSMIC Text Editor"
    Locate on screen     image         ghaf-close.png
    Copy text to clipboard    ${clipboard_text}
    Start app via GUI         ${COMMS_VM}    slack    display_name=Slack
    Paste clipboard text to Slack and verify     ${clipboard_text}
    [Teardown]    Run Keywords    Switch to vm    ${COMMS_VM}    AND    Kill App By Name    slack    sudo=True
    ...           AND             Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    ...           AND             Kill App By Name    cosmic-edit
    ...           AND             Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
Open an app from the dock
    [Documentation]   Open Slack, minimize its window, verify it is hidden, then restore it from dock.
    [Tags]            SP-T79
    Start app via GUI   ${COMMS_VM}   slack    display_name="Slack"
    Save Slack window baseline coordinates
    Locate and click minimize window button
    Verify app window is minimized
    Locate and click app in dock
    Verify Slack window restored to baseline
    [Teardown]   Run Keywords   Kill App By Name    slack
    ...    AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}

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

Paste clipboard text to Slack and verify
    [Arguments]    ${text}
    Locate and click   text   your-workspace   wiggle=True
    Press Key(s)       LEFTCTRL+V
    Move cursor to corner
    Verify Text Is On The Screen    ${text}

Locate and click minimize window button
    ${mouse_x}  ${mouse_y}  Locate on screen  image  ghaf-close.png  0.99  10  timeout=120  scale=2
    ${target_x}    Evaluate    ${mouse_x} - 40
    Run ydotool command   mousemove --absolute -x ${target_x} -y ${mouse_y}
    Click

Locate and click app in dock
    ${mouse_x}  ${mouse_y}  Locate on screen  image    ${APP_MENU_LAUNCHER}    0.95    10
    ${target_x}    Evaluate    ${mouse_x} + 190
    Run ydotool command   mousemove --absolute -x ${target_x} -y ${mouse_y}
    Click

Verify app window is minimized
    Sleep    1
    ${status}   ${output}    Run Keyword And Ignore Error    Locate on screen    image    ghaf-close.png    0.99    5    timeout=120    scale=2
    IF    '${status}' == 'PASS'
        FAIL    App window close button is still visible, window was not minimized.
    END

Verify app window restored near coordinates
    [Arguments]    ${expected_x}   ${expected_y}   ${searched_type}=image   ${searched_item}=ghaf-close.png   ${tolerance}=35
    Sleep    1
    ${actual_x}   ${actual_y}    Locate on screen   ${searched_type}   ${searched_item}   0.99   10   timeout=120   scale=2
    ${x_in_range}    Evaluate    abs(${actual_x} - ${expected_x}) <= ${tolerance}
    ${y_in_range}    Evaluate    abs(${actual_y} - ${expected_y}) <= ${tolerance}
    IF    not ${x_in_range} or not ${y_in_range}
        FAIL    Window anchor '${searched_item}' was restored at unexpected location: expected around (${expected_x}, ${expected_y}), got (${actual_x}, ${actual_y}).
    END

Save Slack window baseline coordinates
    ${window_x}   ${window_y}    Locate on screen   image   ghaf-close.png   0.99   10   timeout=120   scale=2
    ${anchor_x}   ${anchor_y}    Locate on screen   text    your-workspace   0.99   10   timeout=120   scale=2
    Set Test Variable    ${SLACK_WINDOW_X}    ${window_x}
    Set Test Variable    ${SLACK_WINDOW_Y}    ${window_y}
    Set Test Variable    ${SLACK_ANCHOR_X}    ${anchor_x}
    Set Test Variable    ${SLACK_ANCHOR_Y}    ${anchor_y}

Verify Slack window restored to baseline
    Verify app window restored near coordinates    ${SLACK_WINDOW_X}   ${SLACK_WINDOW_Y}
    Verify app window restored near coordinates    ${SLACK_ANCHOR_X}   ${SLACK_ANCHOR_Y}   searched_type=text   searched_item=your-workspace   tolerance=35
