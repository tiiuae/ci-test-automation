# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Launch applications via GUI
Test Tags           gui-app-launch  pre-merge  lenovo-x1  darter-pro

Resource            ../../config/variables.robot
Variables           ../../lib/performance_thresholds.py
Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Library             Collections
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Setup          Start screen recording
Test Teardown       Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}
Suite Teardown      GUI App Launch Suite Teardown
Test Template       Launch App And Save Time


*** Test Cases ***

Start Advanced Network Configuration via GUI
    [Tags]            SP-T463
    ${Advanced Network Configuration}

Start App Store via GUI
    [Tags]            SP-T460
    ${App Store}

Start Bluetooth Settings via GUI
    [Tags]            SP-T417
    ${Bluetooth Settings}

Start COSMIC Document Reader via GUI
    [Tags]            SP-T381
    ${COSMIC Document Reader}

Start COSMIC Files via GUI
    [Tags]            SP-T421
    ${COSMIC Files}

Start COSMIC Media Player via GUI
    [Tags]            SP-T442
    ${COSMIC Media Player}

Start COSMIC Settings via GUI
    [Tags]            SP-T430
    ${COSMIC Settings}

Start COSMIC System Monitor via GUI
    [Tags]            SP-T481
    ${COSMIC System Monitor}

Start COSMIC Terminal via GUI
    [Tags]            SP-T432
    ${COSMIC Terminal}

Start COSMIC Text Editor via GUI
    [Tags]            SP-T426
    ${COSMIC Text Editor}

Start Calculator via GUI
    [Tags]            SP-T416
    ${Calculator}

Start Element via GUI
    [Tags]            SP-T501
    ${Element}

Start Fingerprints via GUI
    [Tags]            SP-T475
    ${Fingerprints}

Start Gala via GUI
    [Tags]            SP-T379
    ${Gala}

Start Getting Started via GUI
    [Tags]            SP-T471
    ${Getting Started}

Start Ghaf Control Panel via GUI
    [Tags]            SP-T420
    ${Ghaf Control Panel}

Start Google Chrome via GUI
    [Tags]            SP-T499
    ${Google Chrome}

Start GPU Screen Recorder via GUI
    [Tags]            SP-T439
    ${GPU Screen Recorder}

Start Microsoft 365 via GUI
    [Tags]            SP-T394
    ${Microsoft 365}

Start Outlook via GUI
    [Tags]            SP-T390
    ${Outlook}

Start Slack via GUI
    [Tags]            SP-T398
    ${Slack}

Start Sticky Notes via GUI
    [Tags]            SP-T414
    ${Sticky Notes}

Start Teams via GUI
    [Tags]            SP-T392
    ${Teams}

Start Trusted Browser via GUI
    [Tags]            SP-T396
    ${Trusted Browser}

Start Volume Control via GUI
    [Tags]            SP-T465
    ${Volume Control}

Start VPN via GUI
    [Tags]            SP-T412
    ${VPN}

Start Zoom via GUI
    [Tags]            SP-T425
    ${Zoom}

*** Keywords ***
GUI App Launch Suite Teardown
    Create App Launch Montage And Move Graphs
    ${blocked_pids}    Get blocked process PIDs
    IF    $blocked_pids
        Log Error    DAX issue    D-state processes ${blocked_pids} found after ${SUITE_NAME}.
        Capture DAX hang snapshot
        Log blocked process diagnostics
    END

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
    ...                Threshold is read from apps.json for non-storeDisk app-specific limits.
    ...                Otherwise performance_thresholds.py is used (storeDisk uses its dedicated value).
    [Arguments]        ${app_key}
    IF    "storeDisk" in "${JOB}"
        ${threshold}    Set Variable    ${static_thresholds}[app_launch_time_storedisk]
    ELSE
        # To define separate launch time for one app, add limits for the app in apps.json
        # "app_launch_time_thresholds": {
        #     "lenovo-x1": 6,
        #     "darter-pro": 8.5
        # }
        ${has_app_thresholds}    Run Keyword And Return Status    Dictionary Should Contain Key    ${app_key}    app_launch_time_thresholds
        IF    ${has_app_thresholds}
            ${threshold}    Get App Launch Threshold
            ...    ${app_key}[app_launch_time_thresholds]    ${static_thresholds}[app_launch_time]    ${JOB}    ${DEVICE_TYPE}
        ELSE
            ${threshold}    Set Variable    ${static_thresholds}[app_launch_time]
        END
    END
    ${diff}        Evaluate    ${TIME_${app_key}[process_name]_launched} - ${TIME_${app_key}[process_name]_start}
    &{results}     Create Dictionary
    Set To Dictionary  ${results}    time_to_launch  ${diff}
    ${passed}      Save App Launch Time Data   ${TEST NAME}  ${results}  ${threshold}
    Log  <img src="${DEVICE}_${TEST NAME}.png" alt="Launch Time of ${app_key}[process_name]" width="1200">    HTML
    IF    not ${passed}
        FAIL    ${app_key}[display_name] was started in ~${diff} sec, expected <=${threshold} sec
    END
