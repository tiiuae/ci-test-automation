# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Launch applications via GUI
Test Tags           SP-T285  gui-app-launch  lenovo-x1  darter-pro

Resource            ../../config/variables.robot
Variables           ../../lib/performance_thresholds.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
Suite Teardown      Create App Launch Montage And Move Graphs


*** Test Cases ***

Start App Store via GUI
    [Documentation]   Start App Store via GUI and measure launch time
    [Tags]            SP-T334  SP-T334-2
    Start app via GUI   ${FLATPAK_VM}  cosmic-store  "App Store"
    Close app via GUI   ${FLATPAK_VM}  cosmic-store  window-close-neg.png
    Save launch time    cosmic-store

Start Bluetooth Settings via GUI
    [Documentation]   Start Bluetooth Settings via GUI and measure launch time
    [Tags]            SP-T204  SP-T204-2
    Start app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  "Bluetooth Settings"
    Close app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  window-close.png
    Save launch time    blueman-manager-wrapped-wrapped

Start COSMIC Document Reader via GUI
    [Documentation]   Start COSMIC Document Reader via GUI and measure launch time
    [Tags]            SP-T105  SP-T105-2
    Start app via GUI   ${GUI_VM}  cosmic-reader   "COSMIC Document Reader"
    Close app via GUI   ${GUI_VM}  cosmic-reader   ghaf-close.png
    Save launch time    cosmic-reader

Start COSMIC Files via GUI
    [Documentation]   Start COSMIC Files via GUI and measure launch time
    [Tags]            SP-T206  SP-T206-2
    Start app via GUI   ${GUI_VM}  ^cosmic-files$  "COSMIC Files"
    Close app via GUI   ${GUI_VM}  ^cosmic-files$  ghaf-close.png
    Save launch time    ^cosmic-files$

Start COSMIC Media Player via GUI
    [Documentation]   Start COSMIC Media Player via GUI and measure launch time
    [Tags]            SP-T294  SP-T294-2
    Start app via GUI   ${GUI_VM}  cosmic-player  "COSMIC Media Player"
    Close app via GUI   ${GUI_VM}  cosmic-player  ghaf-close.png
    Save launch time    cosmic-player

Start COSMIC Settings via GUI
    [Documentation]   Start COSMIC Settings via GUI and measure launch time
    [Tags]            SP-T254  SP-T254-2
    Start app via GUI   ${GUI_VM}  cosmic-settings$  "COSMIC Settings"
    Close app via GUI   ${GUI_VM}  cosmic-settings$  ghaf-close.png
    Save launch time    cosmic-settings$

Start COSMIC Terminal via GUI
    [Documentation]   Start COSMIC Terminal via GUI and measure launch time
    [Tags]            SP-T263  SP-T263-2
    Start app via GUI   ${GUI_VM}  cosmic-term  "COSMIC Terminal"
    Close app via GUI   ${GUI_VM}  cosmic-term  ghaf-close.png
    Save launch time    cosmic-term

Start COSMIC Text Editor via GUI
    [Documentation]   Start COSMIC Text Editor via GUI and measure launch time
    [Tags]            SP-T243  SP-T243-2
    Start app via GUI   ${GUI_VM}  cosmic-edit  "COSMIC Text Editor"
    Close app via GUI   ${GUI_VM}  cosmic-edit  ghaf-close.png
    Save launch time    cosmic-edit

Start Calculator via GUI
    [Documentation]   Start Calculator via GUI and measure launch time
    [Tags]            SP-T202  SP-T202-2
    Start app via GUI   ${GUI_VM}  gnome-calculator  Calculator
    Close app via GUI   ${GUI_VM}  gnome-calculator  window-close-neg.png
    Save launch time    gnome-calculator

Start Element via GUI
    [Documentation]   Start Element via GUI and measure launch time
    [Tags]            SP-T52  SP-T52-2
    Start app via GUI   ${COMMS_VM}  element  Element
    Close app via GUI   ${COMMS_VM}  element  ghaf-close.png
    Save launch time    element

Start Fingerprints via GUI
    [Documentation]   Start Fingerprints via GUI and measure launch time
    [Tags]            SP-T364  SP-T364-2
    Start app via GUI   ${GUI_VM}  fingwit  Fingerprints
    Close app via GUI   ${GUI_VM}  fingwit  window-close.png
    Save launch time    fingwit

Start GPU Screen Recorder via GUI
    [Documentation]   Start GPU Screen Recorder via GUI and measure launch time
    [Tags]            SP-T293  SP-T293-2
    Start app via GUI   ${GUI_VM}  gpu-screen-recorder-gtk  "GPU Screen Recorder"
    Close app via GUI   ${GUI_VM}  gpu-screen-recorder-gtk  window-close.png
    Save launch time    gpu-screen-recorder-gtk

Start Gala via GUI
    [Documentation]   Start Gala via GUI and measure launch time
    [Tags]            SP-T104  SP-T104-2
    Start app via GUI   ${BUSINESS_VM}  gala  Gala
    Close app via GUI   ${BUSINESS_VM}  gala  ghaf-close.png
    Save launch time    gala

Start Getting Started via GUI
    [Documentation]   Start 'Getting Started' via GUI and measure launch time
    [Tags]            SP-T354  SP-T354-2
    Start app via GUI   ${CHROME_VM}  ghaf-intro  "Getting Started"
    Close app via GUI   ${CHROME_VM}  ghaf-intro  ghaf-close.png
    Save launch time    ghaf-intro

Start Ghaf Control Panel via GUI
    [Documentation]   Start Ghaf Control Panel via GUI and measure launch time
    [Tags]            SP-T205  SP-T205-2
    Start app via GUI   ${GUI_VM}  ctrl-panel  "Ghaf Control Panel"
    Close app via GUI   ${GUI_VM}  ctrl-panel  window-close-neg.png
    Save launch time    ctrl-panel

Start Google Chrome via GUI
    [Documentation]   Start Google Chrome via GUI and measure launch time
    [Tags]            SP-T92  SP-T92-2
    Start app via GUI   ${CHROME_VM}  chrome  "Google Chrome"
    Close app via GUI   ${CHROME_VM}  chrome  ghaf-close.png
    Save launch time    chrome

Start Microsoft 365 via GUI
    [Documentation]   Start Microsoft 365 via GUI and measure launch time
    [Tags]            SP-T178  SP-T178-2
    Start app via GUI   ${BUSINESS_VM}  microsoft365  "Microsoft 365"
    Close app via GUI   ${BUSINESS_VM}  microsoft365  ghaf-close.png
    Save launch time    microsoft365

Start Outlook via GUI
    [Documentation]   Start Outlook via GUI and measure launch time
    [Tags]            SP-T176  SP-T176-2
    Start app via GUI   ${BUSINESS_VM}  outlook  Outlook
    Close app via GUI   ${BUSINESS_VM}  outlook  ghaf-close.png
    Save launch time    outlook

Start Slack via GUI
    [Documentation]   Start Slack via GUI and measure launch time
    [Tags]            SP-T181  SP-T181-2
    Start app via GUI   ${COMMS_VM}  slack  Slack
    Close app via GUI   ${COMMS_VM}  slack  ghaf-close.png
    Save launch time    slack

Start Sticky Notes via GUI
    [Documentation]   Start Sticky Notes via GUI and measure launch time
    [Tags]            SP-T201  SP-T201-2
    Start app via GUI   ${GUI_VM}  sticky-wrapped  "Sticky Notes"
    Close app via GUI   ${GUI_VM}  sticky-wrapped  window-close-neg.png
    Save launch time    sticky-wrapped

Start Teams via GUI
    [Documentation]   Start Teams via GUI and measure launch time
    [Tags]            SP-T177  SP-T177-2
    Start app via GUI   ${BUSINESS_VM}  teams  Teams
    Close app via GUI   ${BUSINESS_VM}  teams  ghaf-close.png
    Save launch time    teams

Start Trusted Browser via GUI
    [Documentation]   Start Trusted Browser via GUI and measure launch time
    [Tags]            SP-T179  SP-T179-2
    Start app via GUI   ${BUSINESS_VM}  google-chrome  "Trusted Browser"
    Close app via GUI   ${BUSINESS_VM}  google-chrome  ghaf-close.png
    Save launch time    google-chrome

Start Volume Control via GUI
    [Documentation]   Start Volume Control via GUI and measure launch time
    [Tags]            SP-T349  SP-T349-2
    Start app via GUI   ${GUI_VM}  pavucontrol  "Volume Control"
    Close app via GUI   ${GUI_VM}  pavucontrol  window-close.png
    Save launch time    pavucontrol

Start VPN via GUI
    [Documentation]   Start VPN app via GUI and measure launch time
    [Tags]            SP-T200  SP-T200-2
    Start app via GUI   ${BUSINESS_VM}  gp-gui  VPN
    Close app via GUI   ${BUSINESS_VM}  gp-gui  ghaf-close.png
    Save launch time    gp-gui

Start Zoom via GUI
    [Documentation]   Start Zoom via GUI and measure launch time
    [Tags]            SP-T237  SP-T237-2
    Start app via GUI   ${COMMS_VM}  zoom  Zoom
    Close app via GUI   ${COMMS_VM}  zoom  ghaf-close.png
    Save launch time    zoom

*** Keywords ***

Create App Launch Montage And Move Graphs
    [Documentation]   Combine all graphs to one image and move the single graphs to their own folder
    Run Process    sh    -c    montage *"Start"*.png -tile 4x -geometry +0+0 app_launch_times.png
    Create Directory    ${OUTPUT_DIR}/outputs/graphs/
    Run Process    sh    -c    mv *"Start"*.png "${OUTPUT_DIR}/outputs/graphs/"

Save launch time
    [Documentation]    Evaluate the time between starting the app from the GUI app menu
    ...                and locating & clicking the close button on the app window.
    ...                Threshold is read from performance_thresholds.py (storeDisk uses its dedicated value).
    [Arguments]    ${app_boot}    ${app_proc}=${app_boot}
    IF    "storeDisk" in "${JOB}"
        ${threshold}    Set Variable    ${static_thresholds}[app_launch_time_storedisk]
    ELSE
        ${threshold}    Set Variable    ${static_thresholds}[app_launch_time]
    END
    ${diff}        Evaluate    ${TIME_${app_proc}_launched} - ${TIME_${app_boot}_start}
    &{results}     Create Dictionary
    Set To Dictionary  ${results}    time_to_launch  ${diff}
    ${passed}      Save App Launch Time Data   ${TEST NAME}  ${results}  ${threshold}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="Launch Time of ${app_boot}" width="1200">    HTML
    IF    not ${passed}
        FAIL    ${app_boot} was started in ~${diff} sec, expected <=${threshold} sec
    END
