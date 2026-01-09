# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Measuring time of launching applications via GUI
Test Tags           SP-T285  time-to-launch-apps  lenovo-x1  darter-pro

Resource            ../../config/variables.robot
Library             ../../lib/GuiTesting.py   ${OUTPUT_DIR}/outputs/gui-temp/
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/performance_keywords.resource

Suite Setup         Tests Setup
Suite Teardown      Tests Teardown
Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Test Cases ***

Measure time to launch Google Chrome
    [Documentation]   Start Google Chrome via GUI and measure time of launching
    [Tags]            SP-T285-1
    Start app via GUI   ${CHROME_VM}  chrome  display_name=Chrome
    Close app via GUI   ${CHROME_VM}  google-chrome  ./window-close-neg.png   2
    Save launch time    chrome  google-chrome

Measure time to launch PDF Viewer
    [Documentation]   Start PDF Viewer via GUI and measure time of launching
    [Tags]            SP-T285-2
    Start app via GUI   ${ZATHURA_VM}  zathura   display_name=PDF
    Close app via GUI   ${ZATHURA_VM}  zathura
    Save launch time    zathura

Measure time to launch Sticky Notes
    [Documentation]   Start Sticky Notes via GUI and measure time of launching
    [Tags]            SP-T285-3
    Start app via GUI   ${GUI_VM}  sticky-wrapped  display_name=Sticky
    Close app via GUI   ${GUI_VM}  sticky-wrapped  ./window-close-neg.png
    Save launch time    sticky-wrapped

Measure time to launch Calculator
    [Documentation]   Start Calculator via GUI and measure time of launching
    [Tags]            SP-T285-4
    Start app via GUI   ${GUI_VM}  gnome-calculator  display_name=Calculator
    Close app via GUI   ${GUI_VM}  gnome-calculator  ./window-close-neg.png
    Save launch time    gnome-calculator

Measure time to launch Bluetooth Settings
    [Documentation]   Start Bluetooth Settings via GUI and measure time of launching
    [Tags]            SP-T285-5
    Start app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  display_name=Bluetooth
    Close app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped
    Save launch time    blueman-manager-wrapped-wrapped

Measure time to launch Ghaf Control Panel
    [Documentation]   Start Ghaf Control Panel via GUI and measure time of launching
    [Tags]            SP-T285-6
    Start app via GUI   ${GUI_VM}  ctrl-panel  display_name=Control
    Close app via GUI   ${GUI_VM}  ctrl-panel  ./window-close-neg.png
    Save launch time    ctrl-panel

Measure time to launch GPU Screen Recorder
    [Documentation]   Start GPU Screen Recorder via GUI and measure time of launching
    [Tags]            SP-T285-7
    Start app via GUI   ${GUI_VM}  gpu-screen-recorder-gtk  display_name="GPU Screen Recorder"
    Close app via GUI   ${GUI_VM}  gpu-screen-recorder-gtk
    Save launch time    gpu-screen-recorder-gtk

Measure time to launch COSMIC Files
    [Documentation]   Start COSMIC Files via GUI and measure time of launching
    [Tags]            SP-T285-8
    Start app via GUI   ${GUI_VM}  ^cosmic-files$  display_name=Files
    Close app via GUI   ${GUI_VM}  ^cosmic-files$  ./window-close-neg.png
    Save launch time    ^cosmic-files$

Measure time to launch COSMIC Edit
    [Documentation]   Start Editor Terminal via GUI and measure time of launching
    [Tags]            SP-T285-9
    Start app via GUI   ${GUI_VM}  cosmic-edit  display_name="COSMIC Text Editor"
    Close app via GUI   ${GUI_VM}  cosmic-edit  ./window-close-neg.png
    Save launch time    cosmic-edit

Measure time to launch COSMIC Player
    [Documentation]   Start COSMIC Player via GUI and measure time of launching
    [Tags]            SP-T285-10
    Start app via GUI   ${GUI_VM}  cosmic-player  display_name="COSMIC Media Player"
    Close app via GUI   ${GUI_VM}  cosmic-player  ./window-close-neg.png
    Save launch time    cosmic-player

Measure time to launch COSMIC Settings
    [Documentation]   Start COSMIC Settings via GUI and measure time of launching
    [Tags]            SP-T285-11
    Start app via GUI   ${GUI_VM}  ^cosmic-settings$  display_name="COSMIC Settings"
    Close app via GUI   ${GUI_VM}  ^cosmic-settings$  ./window-close-neg.png
    Save launch time    ^cosmic-settings$
    [Teardown]    Run Keyword If Test Failed    Run Keywords  Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
    ...                                                 AND   Skip  "Known Issue: SSRCSP-7518"

Measure time to launch COSMIC Terminal
    [Documentation]   Start COSMIC Terminal via GUI and measure time of launching
    [Tags]            SP-T285-12
    Start app via GUI   ${GUI_VM}  cosmic-term  display_name="COSMIC Terminal"
    Close app via GUI   ${GUI_VM}  cosmic-term  ./window-close-neg.png
    Save launch time    cosmic-term

Measure time to launch Element
    [Documentation]   Start Element via GUI and measure time of launching
    [Tags]            SP-T285-13
    Start app via GUI   ${COMMS_VM}  element  display_name=Element
    Close app via GUI   ${COMMS_VM}  element  ./window-close-neg.png
    Save launch time    element

Measure time to launch Zoom
    [Documentation]   Start Zoom via GUI and measure time of launching
    [Tags]            SP-T285-14
    Start app via GUI   ${COMMS_VM}  zoom  display_name=Zoom
    Close app via GUI   ${COMMS_VM}  zoom  ./window-close-neg.png
    Save launch time    zoom

Measure time to launch Slack
    [Documentation]   Start Slack via GUI and measure time of launching
    [Tags]            SP-T285-15
    Start app via GUI   ${COMMS_VM}  slack  display_name=Slack
    Close app via GUI   ${COMMS_VM}  slack  ./window-close-neg.png
    Save launch time    slack

Measure time to launch Gala
    [Documentation]   Start Gala via GUI and measure time of launching
    [Tags]            SP-T285-17
    Start app via GUI   ${BUSINESS_VM}  gala  display_name=Gala
    Close app via GUI   ${BUSINESS_VM}  gala  ./window-close-neg.png
    Save launch time    gala

Measure time to launch Teams
    [Documentation]   Start Teams via GUI and measure time of launching
    [Tags]            SP-T285-18
    Start app via GUI   ${BUSINESS_VM}  teams  display_name=Teams
    Close app via GUI   ${BUSINESS_VM}  teams  ./window-close-neg.png
    Save launch time    teams

Measure time to launch Trusted Browser
    [Documentation]   Start Trusted Browser via GUI and measure time of launching
    [Tags]            SP-T285-19
    Start app via GUI   ${BUSINESS_VM}  google-chrome  display_name="Trusted Browser"
    Close app via GUI   ${BUSINESS_VM}  google-chrome  ./window-close-neg.png   2
    Save launch time    google-chrome

Measure time to launch Microsoft 365
    [Documentation]   Start Microsoft 365 via GUI and measure time of launching
    [Tags]            SP-T285-20
    Start app via GUI   ${BUSINESS_VM}  microsoft365  display_name="Microsoft 365"
    Close app via GUI   ${BUSINESS_VM}  microsoft365  ./window-close-neg.png
    Save launch time    microsoft365

Measure time to launch Microsoft Outlook
    [Documentation]   Start Microsoft Outlook via GUI and measure time of launching
    [Tags]            SP-T285-21
    Start app via GUI   ${BUSINESS_VM}  outlook  display_name=Outlook
    Close app via GUI   ${BUSINESS_VM}  outlook  ./window-close-neg.png
    Save launch time    outlook

Measure time to launch VPN
    [Documentation]   Start VPN app via GUI and measure time of launching
    [Tags]            SP-T285-22
    Start app via GUI   ${BUSINESS_VM}  gpclient  display_name=VPN
    # Closing is ignored because the process stays running
    Close app via GUI   ${BUSINESS_VM}  gpclient  verify_is_killed=false
    Save launch time    gpclient

Measure time to launch App Store
    [Documentation]   Start App Store via GUI and measure time of launching
    [Tags]            SP-T285-23
    Start app via GUI   ${FLATPAK_VM}  cosmic-store  display_name="App Store"
    # Closing is ignored because it takes a while before the window can be closed via GUI
    Close app via GUI   ${FLATPAK_VM}  cosmic-store  ./window-close-neg.png  verify_is_killed=false
    Save launch time    cosmic-store

*** Keywords ***

Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment   enable_dnd=True

Tests Teardown
    Log out from laptop
    
Save launch time
    [Documentation]    Evaluate the time between starting the app from the GUI app menu
    ...                and locating & clicking the close button on the app window.
    ...                Since this action can take up to 1 sec, the time threshold is set to 6 sec (the requirement is 5).
    [Arguments]    ${app_boot}    ${app_proc}=${app_boot}
    ${diff}        Evaluate    ${TIME_${app_proc}_launched} - ${TIME_${app_boot}_start}
    &{results}     Create Dictionary
    Set To Dictionary  ${results}    time_to_launch  ${diff}
    ${passed}      Save App Launch Time Data   ${TEST NAME}  ${results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="Launch Time of ${app_boot}" width="1200">    HTML
    IF    not ${passed}
        FAIL    ${app_boot} was started in ~${diff} sec, expected <6 sec
    END
