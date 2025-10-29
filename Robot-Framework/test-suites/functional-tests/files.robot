# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching files
Force Tags          files   lenovo-x1   darter-pro   dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource


*** Test Cases ***

Open PDF from chrome-vm
    [Documentation]    Open PDF file from Chrome VM and check that Zathura app is started
    [Tags]             bat  regression  pre-merge  SP-T131-1
    Open PDF from app-vm    ${CHROME_VM}
    [Teardown]         Kill Process And Save Logs    ${CHROME_VM}    ghaf    /tmp/out.log    ${ZATHURA_VM}

Open PDF from comms-vm
    [Documentation]    Open PDF file from Comms VM and check that Zathura app is started
    [Tags]             regression  SP-T131-2
    Open PDF from app-vm    ${COMMS_VM}
    [Teardown]         Kill Process And Save Logs    ${COMMS_VM}    ghaf    /tmp/out.log   ${ZATHURA_VM}

Open PDF from business-vm
    [Documentation]    Open PDF file from Business VM and check that Zathura app is started
    [Tags]             regression  SP-T131-3
    Open PDF from app-vm    ${BUSINESS_VM}
    [Teardown]         Kill Process And Save Logs    ${BUSINESS_VM}    ghaf   /tmp/out.log    ${ZATHURA_VM}

Open PDF from gui-vm
    [Documentation]    Open PDF file from Gui VM and check that Zathura app is started
    [Tags]             regression  SP-T131-4
    Open PDF from app-vm    ${GUI_VM}
    [Teardown]         Kill Process And Save Logs    ${GUI_VM}    ghaf    /tmp/out.log   ${ZATHURA_VM}

Open image with Oculante
    [Documentation]    Open PNG image in the Gui VM and check that Oculante app is started and opens the image
    [Tags]             bat  regression  pre-merge  SP-T197
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}

    Execute Command    mkdir test-images
    ${result}          Run Keyword And Ignore Error  Execute Command  cosmic-screenshot --interactive=false --save-dir ./  return_stdout=True   return_rc=True   timeout=5
    IF  "${result}[1][1]" == "0"
        ${img_file}    Set Variable    ${result}[1][0]
    ELSE
        Fail           Couldn't take a screenshot
    END

    Open Image         ${img_file}

    Switch to vm       ${ZATHURA_VM}
    Check that the application was started    oculante    10
    [Teardown]  Run Keywords  Remove the file in VM       ${img_file}  ${GUI_VM}    AND
    ...                       Kill Process And Save Logs  ${GUI_VM}    ${USER_LOGIN}    /tmp/out.log    ${ZATHURA_VM}

Open text file with Cosmic Text Editor
    [Documentation]    Open text file and check that Cosmic Text Editor app is started
    [Tags]             bat  regression  pre-merge  SP-T262
    Switch to vm       ${GUI_VM}  user=${USER_LOGIN}
    Create text file   test    /tmp/test_text.txt
    Open text file     /tmp/test_text.txt
    Check that the application was started    cosmic-edit    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_text.txt    ${GUI_VM}    ${USER_LOGIN}    AND
    ...                       Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /tmp/out.log


*** Keywords ***

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}   ${user}=ghaf
    Switch to vm       ${vm}   user=${user}
    Remove file        ${file_name}

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
    ${output}        Execute Command    cat /run/current-system/sw/share/applications/ghaf-pdf-xdg.desktop  sudo=True  sudo_password=${PASSWORD}    return_stderr=True
    ${path}          Get App Path From Desktop  ${output}[0]
    ${xdgopen}       Get Substring      ${path}    0    -3
    Log To Console   Trying to open ${pdf_file}
    Execute Command  echo ${PASSWORD} | sudo -S nohup sh -c '${xdgopen} ${pdf_file}' > /tmp/out.log 2>&1 &

Open Image
    [Arguments]      ${pic_file}
    ${output}        Execute Command    cat /run/current-system/sw/share/applications/ghaf-image-xdg.desktop
    Log              ${output}
    ${path}          Get App Path From Desktop  ${output}
    ${xdgopen}       Get Substring      ${path}    0    -3
    Log To Console   Trying to open ${pic_file}
    Execute Command  nohup sh -c '${xdgopen} ${pic_file}' > /tmp/out.log 2>&1 &

Open text file
    [Arguments]      ${text_file}
    Log To Console   Trying to open ${text_file}
    ${output}        Execute Command  WAYLAND_DISPLAY=wayland-1 nohup sh -c 'cosmic-edit -f ${text_file}' > /tmp/out.log 2>&1 &