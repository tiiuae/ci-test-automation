# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps   lenovo-x1   dell-7330

Library             String
Resource            ../../resources/app_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to netvm


*** Variables ***
@{APP_PIDS}         ${EMPTY}


*** Test Cases ***

Start Chrome
    [Documentation]   Start Chrome in dedicated VM and verify process started
    [Tags]            bat  regression   pre-merge   SP-T92
    [Setup]           Run Keywords    Switch Connection    ${CONNECTION}    AND
    ...               Verify service status  range=15  service=microvm@chrome-vm.service
    Switch to vm           gui-vm  user=${USER_LOGIN}
    Start XDG application  'Google Chrome'
    Connect to VM          ${CHROME_VM}
    Check that the application was started    chrome
    [Teardown]  Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /home/testuser/output.log    ${CHROME_VM}

Start Zathura
    [Documentation]   Start Zathura in dedicated VM and verify process started
    [Tags]            bat  regression  pre-merge   SP-T105
    [Setup]           Check if ssh is ready on vm    ${ZATHURA_VM}
    Switch to vm           gui-vm  user=${USER_LOGIN}
    Start XDG application  'PDF Viewer'
    Connect to VM          ${ZATHURA_VM}
    Check that the application was started    zathura
    [Teardown]  Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /home/testuser/output.log    ${ZATHURA_VM}

Start Gala
    [Documentation]   Start Gala in dedicated VM and verify process started
    [Tags]            bat  regression  SP-T104
    [Setup]           Check if ssh is ready on vm    ${GALA_VM}
    Switch to vm           gui-vm  user=${USER_LOGIN}
    Start XDG application  GALA
    Connect to VM          ${GALA_VM}
    Check that the application was started    gala
    [Teardown]  Run Keywords
    ...         Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /home/testuser/output.log    ${GALA_VM}    AND
    ...         Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-6434"

Start Element
    [Documentation]   Start Element in dedicated VM and verify process started
    [Tags]            bat  regression  SP-T52
    [Setup]           Check if ssh is ready on vm    ${COMMS_VM}
    Switch to vm           gui-vm  user=${USER_LOGIN}
    Start XDG application  Element
    Connect to VM          ${COMMS_VM}
    Check that the application was started    element
    [Teardown]  Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /home/testuser/output.log    ${COMMS_VM}

Start Slack
    [Documentation]   Start Slack in dedicated VM and verify process started
    [Tags]            bat  regression  SP-T181
    [Setup]           Check if ssh is ready on vm    ${COMMS_VM}
    Switch to vm           gui-vm  user=${USER_LOGIN}
    Start XDG application  Slack
    Connect to VM          ${COMMS_VM}
    Check that the application was started    slack
    [Teardown]  Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /home/testuser/output.log    ${COMMS_VM}

Open PDF from chrome-vm
    [Documentation]    Open PDF file from Chrome VM and check that Zathura app is started
    [Tags]             bat  regression  SP-T131-1
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
    [Tags]             bat  regression  SP-T197
    Switch to vm       gui-vm  user=${USER_LOGIN}

    Execute Command    mkdir test-images
    ${result}          Run Keyword And Ignore Error  Execute Command  cosmic-screenshot --interactive=false --save-dir ./  return_stdout=True   return_rc=True   timeout=5
    IF  "${result}[1][1]" == "0"
        ${img_file}    Set Variable    ${result}[1][0]
    ELSE
        Fail           Couldn't take a screenshot
    END

    Open Image         ${img_file}

    Connect to VM      ${ZATHURA_VM}
    Check that the application was started    oculante    10
    [Teardown]  Run Keywords  Remove the file in VM       ${img_file}  ${GUI_VM}    AND
    ...                       Kill Process And Save Logs  ${GUI_VM}    ${USER_LOGIN}    /tmp/out.log    ${ZATHURA_VM}

Open text file with Cosmic Text Editor
    [Documentation]    Open text file and check that Cosmic Text Editor app is started
    [Tags]             bat  regression  SP-T262
    Switch to vm       gui-vm  user=${USER_LOGIN}
    Create text file   test    /tmp/test_text.txt
    Open text file     /tmp/test_text.txt
    Check that the application was started    cosmic-edit    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_text.txt    ${GUI_VM}    ${USER_LOGIN}    AND
    ...                       Kill Process And Save Logs    ${GUI_VM}    ${USER_LOGIN}    /tmp/out.log


*** Keywords ***

Kill Process And Save Logs
    [Documentation]    Kill all running process and log apps output and journalctl
    ...                app_start_vm - the VM from which the app was started
    ...                user - by what user the app was started
    ...                log_file - the name of the file which was defined in the app's starting command
    ...                app_running_vm - the VM where the App is actually running
    [Arguments]        ${app_start_vm}   ${user}=ghaf    ${log_file}=output.log    ${app_running_vm}=${app_start_vm}
    Switch to vm       ${app_running_vm}
    Kill process       @{APP_PIDS}
    Log and remove app output   ${log_file}  ${app_start_vm}   user=${user}
    Run Keyword If Test Failed  Log app vm journalctl  ${app_running_vm}

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
