# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Measuring time of launching applications via GUI
Force Tags          performance   app_launcing_time   lenovo-x1   darter-pro

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
    [Documentation]   Start PDF Viewer via GUI and verify related process started
    ...               Close PDF Viewer via GUI and verify related process stopped
    [Tags]            SP-T285-2
    Start app via GUI   ${ZATHURA_VM}  zathura   display_name=PDF
    Close app via GUI   ${ZATHURA_VM}  zathura  ./window-close.png
    Save launch time    zathura    zathura

Measure time to launch Sticky Notes
    [Documentation]   Start Sticky Notes via GUI and verify related process started
    ...               Close Sticky Notes via GUI and verify related process stopped
    [Tags]            SP-T285-3
    Start app via GUI   ${GUI_VM}  sticky-wrapped  display_name=Sticky
    Close app via GUI   ${GUI_VM}  sticky-wrapped  ./window-close-neg.png
    Save launch time    sticky-wrapped    sticky-wrapped

Measure time to launch Calculator
    [Documentation]   Start Calculator via GUI and verify related process started
    ...               Close Calculator via GUI and verify related process stopped
    [Tags]            SP-T285-4
    Start app via GUI   ${GUI_VM}  gnome-calculator  display_name=Calculator
    Close app via GUI   ${GUI_VM}  gnome-calculator  ./window-close-neg.png
    Save launch time    gnome-calculator    gnome-calculator

Measure time to launch Bluetooth Settings
    [Documentation]   Start Bluetooth Settings via GUI and verify related process started
    ...               Close Bluetooth Settings via GUI and verify related process stopped
    [Tags]            SP-T285-5
    Start app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  display_name=Bluetooth
    Close app via GUI   ${GUI_VM}  blueman-manager-wrapped-wrapped  ./window-close.png
    Save launch time    blueman-manager-wrapped-wrapped    blueman-manager-wrapped-wrapped

Measure time to launch Ghaf Control Panel
    [Documentation]   Start Ghaf Control Panel via GUI and verify related process started
    ...               Close Ghaf Control Panel via GUI and verify related process stopped
    [Tags]            SP-T285-6
    Start app via GUI   ${GUI_VM}  ctrl-panel  display_name=Control
    Close app via GUI   ${GUI_VM}  ctrl-panel  ./window-close-neg.png
    Save launch time    ctrl-panel    ctrl-panel

Measure time to launch COSMIC Files
    [Documentation]   Start COSMIC Files via GUI and verify related process started
    ...               Close COSMIC Files via GUI and verify related process stopped
    [Tags]            SP-T285-7
    Start app via GUI   ${GUI_VM}  cosmic-files  display_name=Files  exact_match=true
    Close app via GUI   ${GUI_VM}  cosmic-files  ./window-close-neg.png  exact_match=true
    Save launch time    cosmic-files    cosmic-files

*** Keywords ***

Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment   enable_dnd=True

    # There's a bug that occasionally causes the app menu to freeze on Cosmic, especially on the first login.
    # Logging out once before running tests helps reduce the chances of it happening. (SSRCSP-6684)
    ${first_login}   Is first graphical login
    IF  ${first_login}
        Log To Console   First login detected. Logging out and back in to go around a Cosmic bug.
        Log out and verify   disable_dnd=True
        Log in, unlock and verify   enable_dnd=True
    END

Is first graphical login
    [Documentation]   Returns True if there has only been one graphical login and False if there has been more than one
    ${result}   Execute Command    journalctl --user -u graphical-session.target | grep "Reached target Current graphical user session"
    Log         ${result}
    ${lines}    Count lines    ${result}
    IF  ${lines} <= 1   RETURN   True
    RETURN      False
    
Save launch time
    [Arguments]    ${app_boot}    ${app_proc}
    ${diff}        Evaluate    ${TIME_${app_proc}_launched} - ${TIME_${app_boot}_start}
    &{results}     Create Dictionary
    Set To Dictionary       ${results}  time_to_launch  ${diff}
    Log    ${results}
    Save App Launch Time Data   ${TEST NAME}  ${results}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="Launch Time of ${app_boot}" width="1200">    HTML
    IF    ${diff} > 5.5
        Run Keyword And Continue On Failure  FAIL    Chrome was started in more than 5 sec
    END
    