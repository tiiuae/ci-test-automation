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
Suite Teardown      GUI Apps Teardown


*** Variables ***

@{APP_PIDS}         ${EMPTY}
${start_menu}       ./launcher.png


*** Test Cases ***

Start and close chrome via GUI on LenovoX1
    [Documentation]   Start Chrome via GUI test automation and verify related process started
    ...               Close Chrome via GUI test automation and verify related process stopped
    [Tags]            SP-T41   lenovo-x1
    Get icon   app  google-chrome.svg  crop=30
    Start app via GUI on LenovoX1   ${CHROME_VM}  chrome
    Close app via GUI on LenovoX1   ${CHROME_VM}  google-chrome  ./window-close-neg.png   2

Start and close PDF Viewer via GUI on LenovoX1
    [Documentation]   Start PDF Viewer via GUI test automation and verify related process started
    ...               Close PDF Viewer via GUI test automation and verify related process stopped
    [Tags]            SP-T70   lenovo-x1
    Get icon   app  zathura.svg  crop=30
    Start app via GUI on LenovoX1   ${ZATHURA_VM}  zathura
    Close app via GUI on LenovoX1   ${ZATHURA_VM}  zathura  ./window-close-neg.png

Start and close Sticky Notes via GUI on LenovoX1
    [Documentation]   Start Sticky Notes via GUI test automation and verify related process started
    ...               Close Sticky Notes via GUI test automation and verify related process stopped
    [Tags]            SP-T201-2  lenovo-x1
    Get icon   /run/current-system/sw/share/icons/hicolor/scalable/apps  com.vixalien.sticky.svg   crop=15
    Start app via GUI on LenovoX1   ${GUI_VM}  sticky-wrapped  #.com.vixalien.sticky-wrapped
    Close app via GUI on LenovoX1   ${GUI_VM}  sticky-wrapped  ./window-close.png

Start and close Calculator via GUI on LenovoX1
    [Documentation]   Start Calculator via GUI test automation and verify related process started
    ...               Close Calculator via GUI test automation and verify related process stopped
    [Tags]            SP-T202  lenovo-x1
    Get icon   app  gnome-calculator.svg   crop=10
    Start app via GUI on LenovoX1   ${GUI_VM}  gnome-calculator
    Close app via GUI on LenovoX1   ${GUI_VM}  gnome-calculator  ./window-close.png

Start and close Bluetooth Settings via GUI on LenovoX1
    [Documentation]   Start Bluetooth via GUI test automation and verify related process started
    ...               Close Bluetooth via via GUI test automation and verify related process stopped
    [Tags]            SP-T204  lenovo-x1
    Get icon   app  blueman.svg   crop=30
    Start app via GUI on LenovoX1   ${GUI_VM}  blueman-manager-wrapped-wrapped
    Close app via GUI on LenovoX1   ${GUI_VM}  blueman-manager-wrapped-wrapped  ./window-close-neg.png

Start and close Control Panel via GUI on LenovoX1
    [Documentation]   Start Control Panel via GUI test automation and verify related process started
    ...               Close Control Panel via GUI test automation and verify related process stopped
    [Tags]            SP-T205  lenovo-x1
    Get icon   app  gnome-control-center.svg   crop=10
    Start app via GUI on LenovoX1   ${GUI_VM}  ctrl-panel
    Close app via GUI on LenovoX1   ${GUI_VM}  ctrl-panel  ./window-close.png

Start and close File Manager via GUI on LenovoX1
    [Documentation]   Start File Manager via GUI test automation and verify related process started
    ...               Close File Manager via GUI test automation and verify related process stopped
    [Tags]            SP-T206  lenovo-x1
    Get icon   app  xfce-filemanager.svg   crop=30
    Start app via GUI on LenovoX1   ${GUI_VM}  pcmanfm
    Close app via GUI on LenovoX1   ${GUI_VM}  pcmanfm  ./window-close-neg.png

Start and close Falcon AI via GUI on LenovoX1
    [Documentation]   Start Falcon AI via GUI test automation and verify related process started
    ...               Close Falcon AI via GUI test automation and verify related process stopped
    ...               Clicks the icon and some Alpaca window is opened.
    [Tags]            SP-T223-2  lenovo-x1
    Get icon   ghaf-artwork  falcon-icon.svg   crop=30
    Start app via GUI on LenovoX1   ${GUI_VM}  alpaca-wrapped
    Close app via GUI on LenovoX1   ${GUI_VM}  alpaca-wrapped  ./window-close.png   iterations=10
    [Teardown]    Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-6482"

Start and close Firefox via GUI on Orin AGX
    [Documentation]   Passing this test requires that display is connected to the target device
    ...               Start Firefox via GUI test automation and verify related process started
    ...               Close Firefox via GUI test automation and verify related process stopped
    [Tags]            SP-T41   # orin-agx can be added after arranging display connection for Orin-AGX in the test setup
    Get icon  app  firefox.svg  crop=30
    Start app via GUI on Orin AGX   firefox
    Close app via GUI on Orin AGX   firefox

*** Keywords ***

Start app via GUI on LenovoX1
    [Documentation]    Start Application via GUI test automation and verify related process started
    [Arguments]        ${app-vm}
    ...                ${app}
    ...                ${launch_icon}=icon.png

    Connect to VM if not already connected  gui-vm
    Check if ssh is ready on vm    ${app-vm}

    Start ydotoold

    Log To Console    Going to click the app menu icon
    Locate and click  ${start_menu}  0.95  5
    Log To Console    Going to click the application launch icon
    Locate and click  ${launch_icon}  0.95  5

    Connect to VM       ${app-vm}
    Check that the application was started    ${app}  10

    [Teardown]    Run Keywords    Connect to VM     ${GUI_VM}
    ...           AND             Move cursor to corner

Close app via GUI on LenovoX1
    [Documentation]    Close Application via GUI test automation and verify related process stopped
    [Arguments]        ${app-vm}
    ...                ${app}
    ...                ${close_button}=./window-close.png
    ...                ${windows_to_close}=1
    ...                ${iterations}=5
    Connect to netvm
    Connect to VM                             ${app-vm}
    Check that the application was started    ${app}
    Connect to VM                             ${GUI_VM}
    Start ydotoold
    Log To Console                            Going to click the close button of the application window
    Locate and click                          ${close_button}  0.8  iterations=${iterations}
    Connect to VM                             ${app-vm}
    ${status}           Run Keyword And Return Status  Check that the application is not running  ${app}  5
    IF  "${windows_to_close}" != "1"
        # At first launch chrome opens window for selecting account.
        # If this window is closed the actual browser window still opens.
        # So need to prepare to close another window in chrome test case.
        IF  '${status}' != 'True'
            Connect to VM       ${GUI_VM}
            Locate and click    ${close_button}  0.8  5
            Connect to VM       ${app-vm}
            ${status}           Run Keyword And Return Status  Check that the application is not running  ${app}  5
        END
    END
    IF  '${status}' != 'True'
        FAIL  Failed to close the application
    END
    # In case closing the app via GUI failed
    [Teardown]    Run Keywords    Kill process      @{APP_PIDS}
    ...           AND             Connect to VM     ${GUI_VM}
    ...           AND             Move cursor to corner
    ...           AND             Stop ydotoold

Start app via GUI on Orin AGX
    [Documentation]    Start Application via GUI test automation and verify related process started
    ...                Only for ghaf builds where desktop is running on ghaf-host
    [Arguments]        ${app}=firefox
    ...                ${launch_icon}=../gui-ref-images/${app}/launch_icon.png

    Connect

    Start ydotoold

    Log To Console    Going to click the app menu icon
    Locate and click  ${start_menu}  0.95  5
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

    # In case closing the app via GUI failed
    [Teardown]    Run Keywords    Kill process  @{APP_PIDS}
    ...           AND             Move cursor to corner
    ...           AND             Stop ydotoold

GUI Apps Teardown
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Connect to netvm
        Connect to VM       ${GUI_VM}
    ELSE
        Connect
    END
    Log journalctl
    Close All Connections
