# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing launching applications
Force Tags          apps
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource


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

Open PDF with Zathura
    [Documentation]    Open PDF file in the Chrome VM and check that Zathura app is started and opens the file
    [Tags]             bat  regression  SP-T131   lenovo-x1   dell-7330
    Connect to netvm
    Connect to VM      ${CHROME_VM}
    Put File           ../test-files/test_pdf.pdf         /tmp
    Open PDF           /tmp/test_pdf.pdf
    Connect to VM      ${ZATHURA_VM}
    Check that the application was started    zathura    10
    [Teardown]  Run Keywords  Remove the file in VM    /tmp/test_pdf.pdf    ${CHROME_VM}    AND
    ...                       Connect to VM      ${ZATHURA_VM}    AND
    ...                       Kill Process And Log journalctl

Open image with Oculante
    [Documentation]    Open PNG image in the Gui VM and check that Oculante app is started and opens the image
    [Tags]             bat  regression  SP-T197   lenovo-x1   dell-7330
    Connect to netvm
    Connect to VM           ${GUI_VM}   ${USER_LOGIN}   ${USER_PASSWORD}

    IF  $COMPOSITOR == 'cosmic'
        Execute Command    mkdir test-images
        ${result}          Run Keyword And Ignore Error  Execute Command  cosmic-screenshot --interactive=false --save-dir ./  return_stdout=True   return_rc=True   timeout=5
        IF  "${result}[1][1]" == "0"
            ${img_file}    Set Variable    ${result}[1][0]
        ELSE
            Fail           Couldn't take a screenshot
        END
    ELSE
        ${rc}              Execute Command  grim screenshot.png  return_stdout=False  return_rc=${true}   timeout=5
        ${img_file}        Set Variable    screenshot.png
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
