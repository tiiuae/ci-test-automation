# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching files
Test Tags           files  bat  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

*** Variables ***
${OUTPUT_FILE}   /tmp/out.log


*** Test Cases ***

Open PDF from chrome-vm
    [Documentation]    Open PDF file from Chrome VM and check that Ghaf Isolated Document Viewer started
    [Tags]             SP-T131  SP-T131-1  pre-merge
    Open PDF from app-vm    ${CHROME_VM}

Open PDF from comms-vm
    [Documentation]    Open PDF file from Comms VM and check that Ghaf Isolated Document Viewer started
    [Tags]             SP-T131  SP-T131-2
    Open PDF from app-vm    ${COMMS_VM}

Open PDF from business-vm
    [Documentation]    Open PDF file from Business VM and check that Ghaf Isolated Document Viewer started
    [Tags]             SP-T131  SP-T131-3
    Open PDF from app-vm    ${BUSINESS_VM}

Open PDF from gui-vm
    [Documentation]    Open PDF file from Gui VM and check that Ghaf Isolated Document Viewer started
    [Tags]             SP-T131  SP-T131-4
    Open PDF from app-vm    ${GUI_VM}  user=${USER_LOGIN}  sudo=False

Open image with Oculante
    [Documentation]    Open PNG image in the Gui VM and check that Oculante app is started and opens the image
    [Tags]             SP-T197  pre-merge
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Run Command        WAYLAND_DISPLAY=wayland-1 grim ./screenshot.png   timeout=5
    Open file with XDG handler   ./screenshot.png   sudo=False
    Check that App is running in VM    ${MEDIA_VM}   oculante   range=10
    [Teardown]  Run Keywords  Remove the file in VM       ./screenshot.png  ${GUI_VM}   ${USER_LOGIN}   AND
    ...                       Kill app and XDG process    oculante

Open video with COSMIC Media Player
    [Documentation]    Record a video in the Gui VM and check that xdg-open opens it with COSMIC Media Player
    [Tags]             SP-T367
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    ${test_name}       Replace String   ${TEST_NAME}   ${SPACE}   _
    ${video_file}      Set Variable     /home/${USER_LOGIN}/Videos/${test_name}.mkv
    Start screen recording   unit_name=robot-video-file-test-recording   video_file=${video_file}   log_file=/tmp/gpu-screen-recorder-video-file-test.log
    Sleep              3s
    Stop screen recording service   robot-video-file-test-recording
    Check file exists              ${video_file}
    ${open_timestamp}            Run Command    date +%s
    Open file with XDG handler     ${video_file}   sudo=False
    Check that App is running in VM    ${MEDIA_VM}   cosmic-player   range=10
    [Teardown]  Run Keywords  Switch to vm    ${GUI_VM}  user=${USER_LOGIN}   AND
    ...                       Stop screen recording service   robot-video-file-test-recording   AND
    ...                       Remove the file in VM       ${video_file}  ${GUI_VM}   ${USER_LOGIN}   AND
    ...                       Kill app and XDG process    cosmic-player   AND
    ...                       Run Keyword If   '${TEST_STATUS}' == 'FAIL'   Check for cosmic app crash   ${open_timestamp}   cosmic-player   ${test_name}.mkv

Open text file with Cosmic Text Editor
    [Documentation]    Open text file and check that Cosmic Text Editor app is started
    [Tags]             SP-T262  pre-merge
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Create text file   test    /tmp/test_text.txt
    Open file to gui-vm with XDG handler    /tmp/test_text.txt
    Check that App is running in VM         ${GUI_VM}   cosmic-edit   range=10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_text.txt    ${GUI_VM}    ${USER_LOGIN}    AND
    ...                       Kill App in VM    ${GUI_VM}    cosmic-edit    log_file=${OUTPUT_FILE}


*** Keywords ***

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}   ${user}=ghaf
    Switch to vm       ${vm}   user=${user}
    Remove file        ${file_name}

Kill app and XDG process
    [Arguments]        ${app}
    Switch to vm           ${MEDIA_VM}
    Log                    Killing ${app} and xdg-open process in ${MEDIA_VM}    console=true
    Kill process by name   ${app}|xdg-open   sudo=True   require_exists=False

Open PDF from app-vm
    [Arguments]       ${vm}   ${user}=ghaf   ${sudo}=True
    Switch to vm                 ${vm}   user=${user}
    Put File                     ../test-files/test_pdf.pdf   /tmp/test_pdf_${vm}.pdf
    ${open_timestamp}            Run Command    date +%s
    Open file with XDG handler   /tmp/test_pdf_${vm}.pdf   sudo=${sudo}
    Check that App is running in VM    ${MEDIA_VM}   cosmic-reader   range=10
    [Teardown]    Run Keywords   Remove the file in VM        /tmp/test_pdf_${vm}.pdf   ${vm}  ${user}
    ...                    AND   Kill app and XDG process     cosmic-reader
    ...                    AND   Run Keyword If   '${KEYWORD_STATUS}' == 'FAIL'   Check for cosmic app crash   ${open_timestamp}   cosmic-reader   test_pdf_${vm}.pdf

Open file with XDG handler
    [Arguments]      ${file}  ${sudo}=True
    Log To Console   Trying to open ${file}
    Run Command      WAYLAND_DISPLAY=wayland-1 xdg-open ${file}   sudo=${sudo}

Open file to gui-vm with XDG handler
    [Arguments]      ${text_file}
    Log To Console   Trying to open ${text_file}
    Run Command      WAYLAND_DISPLAY=wayland-1 nohup sh -c 'xdg-open ${text_file}' > ${OUTPUT_FILE} 2>&1 &

Check for cosmic app crash
    [Documentation]     COSMIC app crashes sometimes before it opens the file (SSRCSP-8367). Check if process started and skip the test if it did.
    [Arguments]         ${journal_since}  ${app}  ${file_name}
    Switch to vm        ${MEDIA_VM}
    ${app_started}      Run Keyword And Return Status   Run Command    journalctl -b --since @${journal_since} | grep -E "Started \\[systemd-run\\].*${app}.*${file_name}"
    Run Command         journalctl -b --since @${journal_since}   # All logs for debugging
    IF  ${app_started}   SKIP   Known Issue: SSRCSP-8367
