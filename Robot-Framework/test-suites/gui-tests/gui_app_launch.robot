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
Test Template       Launch App And Save Time


*** Test Cases ***

Start Advanced Network Configuration via GUI
    [Tags]            SP-T336  SP-T336-2
    ${Advanced Network Configuration}

Start App Store via GUI
    [Tags]            SP-T334  SP-T334-2
    ${App Store}

Start Bluetooth Settings via GUI
    [Tags]            SP-T204  SP-T204-2
    ${Bluetooth Settings}

Start COSMIC Document Reader via GUI
    [Tags]            SP-T105  SP-T105-2
    ${COSMIC Document Reader}

Start COSMIC Files via GUI
    [Tags]            SP-T206  SP-T206-2
    ${COSMIC Files}

Start COSMIC Media Player via GUI
    [Tags]            SP-T294  SP-T294-2
    ${COSMIC Media Player}

Start COSMIC Settings via GUI
    [Tags]            SP-T254  SP-T254-2
    ${COSMIC Settings}

Start COSMIC Terminal via GUI
    [Tags]            SP-T263  SP-T263-2
    ${COSMIC Terminal}

Start COSMIC Text Editor via GUI
    [Tags]            SP-T243  SP-T243-2
    ${COSMIC Text Editor}

Start Calculator via GUI
    [Tags]            SP-T202  SP-T202-2
    ${Calculator}

Start Element via GUI
    [Tags]            SP-T52  SP-T52-2
    ${Element}

Start Fingerprints via GUI
    [Tags]            SP-T364  SP-T364-2
    ${Fingerprints}

Start Gala via GUI
    [Tags]            SP-T104  SP-T104-2
    ${Gala}

Start Getting Started via GUI
    [Tags]            SP-T354  SP-T354-2
    ${Getting Started}

Start Ghaf Control Panel via GUI
    [Tags]            SP-T205  SP-T205-2
    ${Ghaf Control Panel}

Start Google Chrome via GUI
    [Tags]            SP-T92  SP-T92-2
    ${Google Chrome}

Start GPU Screen Recorder via GUI
    [Tags]            SP-T293  SP-T293-2
    ${GPU Screen Recorder}

Start Microsoft 365 via GUI
    [Tags]            SP-T178  SP-T178-2
    ${Microsoft 365}

Start Outlook via GUI
    [Tags]            SP-T176  SP-T176-2
    ${Outlook}

Start Slack via GUI
    [Tags]            SP-T181  SP-T181-2
    ${Slack}

Start Sticky Notes via GUI
    [Tags]            SP-T201  SP-T201-2
    ${Sticky Notes}

Start Teams via GUI
    [Tags]            SP-T177  SP-T177-2
    ${Teams}

Start Trusted Browser via GUI
    [Tags]            SP-T179  SP-T179-2
    ${Trusted Browser}

Start Volume Control via GUI
    [Tags]            SP-T349  SP-T349-2
    ${Volume Control}

Start VPN via GUI
    [Tags]            SP-T200  SP-T200-2
    ${VPN}

Start Zoom via GUI
    [Tags]            SP-T237  SP-T237-2
    ${Zoom}

*** Keywords ***
Launch App And Save Time
    [Arguments]    ${app_key}
    Set Test Documentation   Start ${app_key}[display_name] via GUI and measure launch time
    Start app via GUI   ${app_key}
    Close app via GUI   ${app_key}
    Save launch time    ${app_key}

Create App Launch Montage And Move Graphs
    [Documentation]   Combine all graphs to one image and move the single graphs to their own folder
    Run Process    sh    -c    montage *"Start"*.png -tile 4x -geometry +0+0 app_launch_times.png
    Create Directory    ${OUTPUT_DIR}/outputs/graphs/
    Run Process    sh    -c    mv *"Start"*.png "${OUTPUT_DIR}/outputs/graphs/"

Save launch time
    [Documentation]    Evaluate the time between starting the app from the GUI app menu
    ...                and locating & clicking the close button on the app window.
    ...                Threshold is read from performance_thresholds.py (storeDisk uses its dedicated value).
    [Arguments]        ${app_key}
    IF    "storeDisk" in "${JOB}"
        ${threshold}    Set Variable    ${static_thresholds}[app_launch_time_storedisk]
    ELSE
        ${threshold}    Set Variable    ${static_thresholds}[app_launch_time]
    END
    ${diff}        Evaluate    ${TIME_${app_key}[process_name]_launched} - ${TIME_${app_key}[process_name]_start}
    &{results}     Create Dictionary
    Set To Dictionary  ${results}    time_to_launch  ${diff}
    ${passed}      Save App Launch Time Data   ${TEST NAME}  ${results}  ${threshold}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="Launch Time of ${app_key}[process_name]" width="1200">    HTML
    IF    not ${passed}
        FAIL    ${app_key}[display_name] was started in ~${diff} sec, expected <=${threshold} sec
    END
