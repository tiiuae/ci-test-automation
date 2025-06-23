# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications via GUI
Force Tags          gui   gui-apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui_keywords.resource
Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/


*** Variables ***

@{APP_PIDS}             ${EMPTY}


*** Test Cases ***

Start and close Google Chrome via GUI on LenovoX1
    [Documentation]   Start Google Chrome via GUI test automation and verify related process started
    ...               Close Google Chrome via GUI test automation and verify related process stopped
    [Tags]            SP-T41-2  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${CHROME_VM}  chrome  display_name=Chrome
        Close app via GUI on LenovoX1   ${CHROME_VM}  google-chrome  ./window-close-neg.png   2
    ELSE
        Get icon   app  google-chrome.svg  crop=30
        Start app via GUI on LenovoX1   ${CHROME_VM}  chrome
        Close app via GUI on LenovoX1   ${CHROME_VM}  google-chrome  ./window-close-neg.png   2
    END
    [Teardown]        Run Keyword If Test Failed     Skip if   $COMPOSITOR == 'cosmic'   "Known issue SSRCSP-6716: Chrome does not have top bar"

Start and close PDF Viewer via GUI on LenovoX1
    [Documentation]   Start PDF Viewer via GUI test automation and verify related process started
    ...               Close PDF Viewer via GUI test automation and verify related process stopped
    [Tags]            SP-T70  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${ZATHURA_VM}  zathura   display_name=PDF
        Close app via GUI on LenovoX1   ${ZATHURA_VM}  zathura  ./window-close.png
    ELSE
        Get icon   app  zathura.svg  crop=30
        Start app via GUI on LenovoX1   ${ZATHURA_VM}  zathura
        Close app via GUI on LenovoX1   ${ZATHURA_VM}  zathura  ./window-close-neg.png
    END

Start and close Sticky Notes via GUI on LenovoX1
    [Documentation]   Start Sticky Notes via GUI test automation and verify related process started
    ...               Close Sticky Notes via GUI test automation and verify related process stopped
    [Tags]            SP-T201-2  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${GUI_VM}  sticky-wrapped  display_name=Sticky
        Close app via GUI on LenovoX1   ${GUI_VM}  sticky-wrapped  ./window-close-neg.png
    ELSE
        Get icon   /run/current-system/sw/share/icons/hicolor/scalable/apps  com.vixalien.sticky.svg   crop=15
        Start app via GUI on LenovoX1   ${GUI_VM}  sticky-wrapped
        Close app via GUI on LenovoX1   ${GUI_VM}  sticky-wrapped  ./window-close.png
    END

Start and close Calculator via GUI on LenovoX1
    [Documentation]   Start Calculator via GUI test automation and verify related process started
    ...               Close Calculator via GUI test automation and verify related process stopped
    [Tags]            SP-T202-2  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${GUI_VM}  gnome-calculator  display_name=Calculator
        Close app via GUI on LenovoX1   ${GUI_VM}  gnome-calculator  ./window-close-neg.png
    ELSE
        Get icon   app  gnome-calculator.svg   crop=10
        Start app via GUI on LenovoX1   ${GUI_VM}  gnome-calculator
        Close app via GUI on LenovoX1   ${GUI_VM}  gnome-calculator  ./window-close.png
    END

Start and close Bluetooth Settings via GUI on LenovoX1
    [Documentation]   Start Bluetooth Settings via GUI test automation and verify related process started
    ...               Close Bluetooth Settings via GUI test automation and verify related process stopped
    [Tags]            SP-T204-2  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${GUI_VM}  blueman-manager-wrapped-wrapped  display_name=Bluetooth
        Close app via GUI on LenovoX1   ${GUI_VM}  blueman-manager-wrapped-wrapped  ./window-close.png
    ELSE
        Get icon   app  blueman.svg   crop=30
        Start app via GUI on LenovoX1   ${GUI_VM}  blueman-manager-wrapped-wrapped
        Close app via GUI on LenovoX1   ${GUI_VM}  blueman-manager-wrapped-wrapped  ./window-close-neg.png
    END

Start and close Ghaf Control Panel via GUI on LenovoX1
    [Documentation]   Start Ghaf Control Panel via GUI test automation and verify related process started
    ...               Close Ghaf Control Panel via GUI test automation and verify related process stopped
    [Tags]            SP-T205-2  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${GUI_VM}  ctrl-panel  display_name=Control
        Close app via GUI on LenovoX1   ${GUI_VM}  ctrl-panel  ./window-close-neg.png
    ELSE
        Get icon   app  gnome-control-center.svg   crop=10
        Start app via GUI on LenovoX1   ${GUI_VM}  ctrl-panel
        Close app via GUI on LenovoX1   ${GUI_VM}  ctrl-panel  ./window-close.png
    END
    
Start and close COSMIC Files via GUI on LenovoX1
    [Documentation]   Start COSMIC Files via GUI test automation and verify related process started
    ...               Close COSMIC Files via GUI test automation and verify related process stopped
    [Tags]            SP-T206-2  lenovo-x1
    IF  $COMPOSITOR == 'cosmic'
        Start app via GUI on LenovoX1   ${GUI_VM}  cosmic-files  display_name=Files  exact_match=true
        Close app via GUI on LenovoX1   ${GUI_VM}  cosmic-files  ./window-close-neg.png  exact_match=true
    ELSE
        Skip   App only available in Cosmic
    END

# GUI tests don't currently work on Orin (keywords expect that gui-vm is available)
Start and close Firefox via GUI on Orin AGX
    [Documentation]   Passing this test requires that display is connected to the target device
    ...               Start Firefox via GUI test automation and verify related process started
    ...               Close Firefox via GUI test automation and verify related process stopped
    [Tags]            SP-T41-2   # orin-agx can be added after arranging display connection for Orin-AGX in the test setup
    Get icon   ${ICONS}/Papirus/128x128/apps  firefox.svg  crop=30
    Start app via GUI on Orin AGX   firefox
    Close app via GUI on Orin AGX   firefox

*** Keywords ***

Start app via GUI on LenovoX1
    [Documentation]    Start Application via GUI test automation and verify related process started
    [Arguments]        ${app-vm}
    ...                ${app}
    ...                ${display_name}=""
    ...                ${launch_icon}=icon.png
    ...                ${exact_match}=false
    Check if ssh is ready on vm    ${app-vm}

    IF  $COMPOSITOR == 'cosmic'
        Open app menu
        Type string and press enter  ${display_name}
        Tab and enter   tabs=1
    ELSE
        Log To Console    Going to click the app menu icon
        Locate and click  ${APP_MENU_LAUNCHER}  0.95  5
        Log To Console    Going to click the application launch icon
        Locate and click  ${launch_icon}  0.95  5
    END

    Connect to VM       ${app-vm}
    Check that the application was started    ${app}  10  ${exact_match}

    [Teardown]    Run Keywords    Switch to gui-vm as ghaf
    ...           AND             Move cursor to corner

Open app menu
    [Documentation]    Check if app menu is open and if not open it (cosmic)
    # Searches for app menu magnifying glass to identify if app menu is open
    Log To Console     Checking that app menu is not already open
    ${status}   ${output}      Run Keyword And Ignore Error   Locate image on screen  search-neg.png  0.90  1
    IF  '${status}' == 'PASS'
        Log To Console    App menu is already open
    ELSE
        Log To Console    Opening app menu
        Locate and click  ${APP_MENU_LAUNCHER}  0.95  5
    END

Close app via GUI on LenovoX1 
    [Documentation]    Close Application via GUI test automation and verify related process stopped
    [Arguments]        ${app-vm}
    ...                ${app}
    ...                ${close_button}=./window-close.png
    ...                ${windows_to_close}=1
    ...                ${iterations}=5
    ...                ${exact_match}=false
    Connect to netvm
    Connect to VM                             ${app-vm}
    Check that the application was started    ${app}  exact_match=${exact_match}
    Switch to gui-vm as ghaf
    Log To Console                            Going to click the close button of the application window
    Locate and click                          ${close_button}  0.8  iterations=${iterations}
    Connect to VM                             ${app-vm}
    ${status}           Run Keyword And Return Status  Check that the application is not running  ${app}  5  ${exact_match}
    IF  "${windows_to_close}" != "1"
        # At first launch chrome opens window for selecting account.
        # If this window is closed the actual browser window still opens.
        # So need to prepare to close another window in chrome test case.
        IF  '${status}' != 'True'
            Switch to gui-vm as ghaf
            Locate and click    ${close_button}  0.8  5
            Connect to VM       ${app-vm}
            ${status}           Run Keyword And Return Status  Check that the application is not running  ${app}  5  ${exact_match}
        END
    END
    IF  '${status}' != 'True'
        FAIL  Failed to close the application
    END
    # In case closing the app via GUI failed
    [Teardown]     Run Keywords   Connect to VM   ${app-vm}   AND   Kill process   @{APP_PIDS}
    ...            AND   Switch to gui-vm as ghaf   AND   Move cursor to corner

Start app via GUI on Orin AGX
    [Documentation]    Start Application via GUI test automation and verify related process started
    ...                Only for ghaf builds where desktop is running on ghaf-host
    [Arguments]        ${app}=firefox
    ...                ${launch_icon}=../gui-ref-images/${app}/launch_icon.png

    Connect

    Start ydotoold

    Log To Console    Going to click the app menu icon
    Locate and click  ${APP_MENU_LAUNCHER}  0.95  5
    Log To Console    Going to click the application launch icon
    Locate and click  ${launch_icon}  0.95  5

    Check that the application was started    ${app}  10

    [Teardown]    Run Keywords    Move cursor to corner

Close app via GUI on Orin AGX
    [Documentation]    Close Application via GUI test automation and verify related process stopped
    ...                Only for ghaf builds where desktop is running on ghaf-host
    [Arguments]        ${app}=firefox
    ...                ${close_button}=../gui-ref-images/${app}/close_button.png

    Connect
    Check that the application was started    ${app}
    Start ydotoold

    Log To Console    Going to click the close button of the application window
    Locate and click  ${close_button}  0.999  5

    Check that the application is not running    ${app}   5
