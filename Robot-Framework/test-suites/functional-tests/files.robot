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
    [Documentation]    Open PDF file from Chrome VM and check that Zathura app is started
    [Tags]             SP-T131  SP-T131-1  pre-merge  bat
    Open PDF from app-vm    ${CHROME_VM}
    [Teardown]         Kill PDF Reader   ${CHROME_VM}

Open PDF from comms-vm
    [Documentation]    Open PDF file from Comms VM and check that Zathura app is started
    [Tags]             SP-T131  SP-T131-2
    Open PDF from app-vm    ${COMMS_VM}
    [Teardown]         Kill PDF Reader   ${COMMS_VM}

Open PDF from business-vm
    [Documentation]    Open PDF file from Business VM and check that Zathura app is started
    [Tags]             SP-T131  SP-T131-3
    Open PDF from app-vm    ${BUSINESS_VM}
    [Teardown]         Kill PDF Reader   ${BUSINESS_VM}

Open PDF from gui-vm
    [Documentation]    Open PDF file from Gui VM and check that Zathura app is started
    [Tags]             SP-T131  SP-T131-4
    Open PDF from app-vm    ${GUI_VM}
    [Teardown]         Kill PDF Reader   ${GUI_VM}

Open image with Oculante
    [Documentation]    Open PNG image in the Gui VM and check that Oculante app is started and opens the image
    [Tags]             SP-T197  pre-merge  bat
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}

    Run Command        mkdir test-images   rc_match=skip
    Run Command        WAYLAND_DISPLAY=wayland-1 grim ./screenshot.png   timeout=5

    Open Image         ./screenshot.png

    Switch to vm       ${ZATHURA_VM}
    Check that the application was started    oculante    10
    [Teardown]  Run Keywords  Remove the file in VM       ./screenshot.png  ${GUI_VM}   ${USER_LOGIN}   AND
    ...                       Kill App Process And Save Logs  ${GUI_VM}    ${USER_LOGIN}    ${OUTPUT_FILE}    oculante    ${ZATHURA_VM}

Open text file with Cosmic Text Editor
    [Documentation]    Open text file and check that Cosmic Text Editor app is started
    [Tags]             SP-T262  pre-merge  bat
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Create text file   test    /tmp/test_text.txt
    Open text file     /tmp/test_text.txt
    Check that the application was started    cosmic-edit    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_text.txt    ${GUI_VM}    ${USER_LOGIN}    AND
    ...                       Kill App Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    ${OUTPUT_FILE}    cosmic-edit    ${GUI_VM}


*** Keywords ***

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}   ${user}=ghaf
    Switch to vm       ${vm}   user=${user}
    Remove file        ${file_name}

Kill PDF Reader
    [Arguments]   ${pdf_launcher_vm}
    Kill App Process And Save Logs   ${pdf_launcher_vm}  ${LOGIN}  ${OUTPUT_FILE}  zathura  ${ZATHURA_VM}

Open PDF from app-vm
    [Arguments]        ${vm}
    Switch to vm       ${vm}
    Put File           ../test-files/test_pdf.pdf         /tmp
    Open PDF           /tmp/test_pdf.pdf
    Switch to vm       ${ZATHURA_VM}
    Check that the application was started    zathura    10
    [Teardown]         Remove the file in VM    /tmp/test_pdf.pdf    ${vm}

Open PDF
    [Arguments]      ${pdf_file}
    Log To Console   Trying to open ${pdf_file}
    Run Command      echo ${PASSWORD} | sudo -S nohup sh -c 'xdg-open-ghaf pdf ${pdf_file}' > ${OUTPUT_FILE} 2>&1 &

Open Image
    [Arguments]      ${pic_file}
    Log To Console   Trying to open ${pic_file}
    Run Command      nohup sh -c 'xdg-open-ghaf image ${pic_file}' > ${OUTPUT_FILE} 2>&1 &

Open text file
    [Arguments]      ${text_file}
    Log To Console   Trying to open ${text_file}
    Run Command      WAYLAND_DISPLAY=wayland-1 nohup sh -c 'cosmic-edit -f ${text_file}' > ${OUTPUT_FILE} 2>&1 &