# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Library             ../../lib/output_parser.py


*** Variables ***
@{APP_PIDS}         ${EMPTY}


*** Test Cases ***

Start Firefox
    [Documentation]   Start Firefox and verify process started
    ...               Known Issues: Firefox is temporarily disabled from target SW (nuc, orin-agx)
    [Tags]            bat  regression  SP-T41
    [Setup]           Skip If   "${JOB}" == "nvidia-jetson-orin-agx-debug-nodemoapps-from-x86_64.x86_64-linux"
    ...               Skipped because this build doesn't contain applications
    Connect
    Start Firefox
    Check that the application was started    firefox
    [Teardown]  Kill Process And Log journalctl

Start Chrome on LenovoX1
    [Documentation]   Start Chrome in dedicated VM and verify process started
    [Tags]            bat  regression   pre-merge   SP-T92   lenovo-x1   dell-7330
    Verify service status  range=15  service=microvm@chrome-vm.service  expected_status=active  expected_state=running
    Connect to netvm
    Check if ssh is ready on vm    ${CHROME_VM}
    ${vm_ssh}    Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Start XDG application   'Google Chrome'
    Connect to VM       ${CHROME_VM}
    Check that the application was started    chrome
    [Teardown]  Kill Process And Log journalctl

Start Zathura on LenovoX1
    [Documentation]   Start Zathura in dedicated VM and verify process started
    [Tags]            bat  regression  pre-merge   SP-T105   lenovo-x1   dell-7330
    Connect to netvm
    Check if ssh is ready on vm    ${ZATHURA_VM}
    Connect to VM       ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Start XDG application   'PDF Viewer'
    Connect to VM       ${ZATHURA_VM}
    Check that the application was started    zathura
    [Teardown]  Kill Process And Log journalctl

Start Gala on LenovoX1
    [Documentation]   Start Gala in dedicated VM and verify process started
    [Tags]            bat  regression  SP-T104   lenovo-x1   dell-7330
    Connect to netvm
    Check if ssh is ready on vm    ${GALA_VM}
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Start XDG application   GALA
    Connect to VM       ${GALA_VM}
    Check that the application was started    gala
    [Teardown]  Run Keywords
    ...         Kill Process And Log journalctl    AND
    ...         Run Keyword If Test Failed     Skip    "Known issue: SSRCSP-6434"

Start Element on LenovoX1
    [Documentation]   Start Element in dedicated VM and verify process started
    [Tags]            bat  regression  SP-T52   lenovo-x1   dell-7330
    Connect to netvm
    Check if ssh is ready on vm    ${COMMS_VM}
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Start XDG application  Element
    Connect to VM          ${COMMS_VM}
    Check that the application was started    element
    [Teardown]  Kill Process And Log journalctl

Start Slack on LenovoX1
    [Documentation]   Start Slack in dedicated VM and verify process started
    [Tags]            bat  regression  SP-T181   lenovo-x1   dell-7330
    Connect to netvm
    Check if ssh is ready on vm    ${COMMS_VM}
    Connect to VM          ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Start XDG application  Slack
    Connect to VM          ${COMMS_VM}
    Check that the application was started    slack
    [Teardown]  Kill Process And Log journalctl

Open PDF from chrome-vm
    [Documentation]    Open PDF file from Chrome VM and check that Zathura app is started
    [Tags]             bat  regression  SP-T131-1   lenovo-x1   dell-7330
    Open PDF from app-vm    ${CHROME_VM}

Open PDF from comms-vm
    [Documentation]    Open PDF file from Comms VM and check that Zathura app is started
    [Tags]             regression  SP-T131-2   lenovo-x1   dell-7330
    Open PDF from app-vm    ${COMMS_VM}

Open PDF from business-vm
    [Documentation]    Open PDF file from Business VM and check that Zathura app is started
    [Tags]             regression  SP-T131-3   lenovo-x1   dell-7330
    Open PDF from app-vm    ${BUSINESS_VM}

Open PDF from gui-vm
    [Documentation]    Open PDF file from Gui VM and check that Zathura app is started
    [Tags]             regression  SP-T131-4   lenovo-x1   dell-7330
    Open PDF from app-vm    ${GUI_VM}

Open image with Oculante
    [Documentation]    Open PNG image in the Gui VM and check that Oculante app is started and opens the image
    [Tags]             bat  regression  SP-T197   lenovo-x1   dell-7330
    Connect to netvm
    Connect to VM           ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}

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
    [Teardown]  Run Keywords  Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}    AND
    ...                       Remove the file in VM    ${img_file}    ${GUI_VM}    AND
    ...                       Connect to VM      ${ZATHURA_VM}    AND
    ...                       Kill Process And Log journalctl

Open text file with Cosmic Text Editor
    [Documentation]    Open text file and check that Cosmic Text Editor app is started
    [Tags]             bat  regression  SP-T262   lenovo-x1   dell-7330
    Connect to netvm
    Connect to VM      ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}
    Create text file   test    /tmp/test_text.txt
    Open text file     /tmp/test_text.txt
    Check that the application was started    cosmic-edit    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_text.txt    ${GUI_VM}    AND
    ...                       Kill Process And Log journalctl


*** Keywords ***

Kill Process And Log journalctl
    [Documentation]    Kill all running process and log journalctl
    ${output}          Execute Command    journalctl
    Log                ${output}
    Kill process       @{APP_PIDS}
    Close All Connections

Remove the file in VM
    [Arguments]        ${file_name}    ${vm}
    Connect to VM      ${vm}
    Remove file        ${file_name}
    Check file doesn't exist    ${file_name}

Open PDF from app-vm
    [Arguments]        ${vm}
    Connect to netvm
    Connect to VM      ${vm}
    Put File           ../test-files/test_pdf.pdf         /tmp
    Open PDF           /tmp/test_pdf.pdf
    Connect to VM      ${ZATHURA_VM}
    Check that the application was started    zathura    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_pdf.pdf    ${vm}    AND
    ...                       Remove the file in VM    /tmp/out.log         ${vm}    AND
    ...                       Connect to VM      ${ZATHURA_VM}    AND
    ...                       Kill Process And Log journalctl

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
