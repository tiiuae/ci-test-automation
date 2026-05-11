# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching files
Test Tags           files  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

*** Variables ***
${OUTPUT_FILE}   /tmp/out.log


*** Test Cases ***

Open PDF from chrome-vm
    [Documentation]    Open PDF file from Chrome VM and check that Ghaf Isolated Document Viewer started
    [Tags]             SP-T131  SP-T131-1  pre-merge  bat
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
    [Tags]             SP-T197  pre-merge  bat
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}

    Run Command        WAYLAND_DISPLAY=wayland-1 grim ./screenshot.png   timeout=5
    Open file with XDG handler   ./screenshot.png   sudo=False

    Switch to vm       ${MEDIA_VM}
    Check that the application was started    oculante    10
    [Teardown]  Run Keywords  Remove the file in VM       ./screenshot.png  ${GUI_VM}   ${USER_LOGIN}   AND
    ...                       Kill app and XDG process    oculante

Open text file with Cosmic Text Editor
    [Documentation]    Open text file and check that Cosmic Text Editor app is started
    [Tags]             SP-T262  pre-merge  bat
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Create text file   test    /tmp/test_text.txt
    Open file to gui-vm with XDG handler    /tmp/test_text.txt
    Check that the application was started    cosmic-edit    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_text.txt    ${GUI_VM}    ${USER_LOGIN}    AND
    ...                       Kill App Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    ${OUTPUT_FILE}    cosmic-edit    ${GUI_VM}


*** Keywords ***

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}   ${user}=ghaf
    Switch to vm       ${vm}   user=${user}
    Remove file        ${file_name}

Kill app and XDG process
    [Arguments]        ${app}
    Switch to vm       ${MEDIA_VM}
    Log                Killing ${app} and xdg-open process in ${MEDIA_VM}    console=true
    Kill App By Name   ${app}|xdg-open        sudo=True

Open PDF from app-vm
    [Arguments]       ${vm}   ${user}=ghaf   ${sudo}=True
    Switch to vm                 ${vm}   user=${user}
    Put File                     ../test-files/test_pdf.pdf   /tmp/test_pdf_${vm}.pdf
    ${open_timestamp}            Run Command    date +%s
    Open file with XDG handler   /tmp/test_pdf_${vm}.pdf   sudo=${sudo}
    Switch to vm                 ${MEDIA_VM}
    Check that the application was started    cosmic-reader   10
    [Teardown]    Run Keywords   Remove the file in VM        /tmp/test_pdf_${vm}.pdf   ${vm}  ${user}
    ...                    AND   Kill app and XDG process     cosmic-reader
    ...                    AND   Run Keyword If   '${KEYWORD_STATUS}' == 'FAIL'   Check for cosmic-reader crash   ${open_timestamp}   ${vm}

Open file with XDG handler
    [Arguments]      ${file}  ${sudo}=True
    Log To Console   Trying to open ${file}
    Run Command      WAYLAND_DISPLAY=wayland-1 xdg-open ${file}   sudo=${sudo}

Open file to gui-vm with XDG handler
    [Arguments]      ${text_file}
    Log To Console   Trying to open ${text_file}
    Run Command      WAYLAND_DISPLAY=wayland-1 nohup sh -c 'xdg-open ${text_file}' > ${OUTPUT_FILE} 2>&1 &

Check for cosmic-reader crash
    [Documentation]     Cosmic-reader crashes sometimes before it opens the file (SSRCSP-8367). Check if process started and skip the test if it did.
    [Arguments]         ${journal_since}  ${vm}
    Switch to vm        ${MEDIA_VM}
    ${reader_started}   Run Keyword And Return Status   Run Command    journalctl -b --since @${journal_since} | grep -E "Started \\[systemd-run\\].*cosmic-reader.*/run/xdg/pdf/${vm}/test_pdf_${vm}\\.pdf\\."
    Run Command         journalctl -b --since @${journal_since}   # All logs for debugging
    IF  ${reader_started}   SKIP   Known Issue: SSRCSP-8367
