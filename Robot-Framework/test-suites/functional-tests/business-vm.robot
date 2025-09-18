# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Business VM
Force Tags          bat  regression  pre-merge  business-vm  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to netvm
Test Teardown       Business Apps Test Teardown


*** Test Cases ***

Start Microsoft Outlook
    [Documentation]   Start Microsoft Outlook in Business-vm and verify process started
    [Tags]  outlook  SP-T176
    Start application in VM   "Microsoft Outlook"   ${BUSINESS_VM}   outlook

Start Microsoft 365
    [Documentation]   Start Microsoft 365 in Business-vm and verify process started
    [Tags]  microsoft365  SP-T178
    Start application in VM   "Microsoft 365"   ${BUSINESS_VM}   microsoft365

Start Microsoft Teams
    [Documentation]   Start Microsoft Teams in Business-vm and verify process started
    [Tags]  teams  SP-T177
    Start application in VM   Teams   ${BUSINESS_VM}   teams

Start Trusted Browser
    [Documentation]   Start Trusted Browser in Business-vm and verify process started
    [Tags]  trusted_browser  SP-T179
    Start application in VM   "Trusted Browser"  ${BUSINESS_VM}   chrome

Start Video Editor
    [Documentation]   Start Video Editor in Business-vm and verify process started
    [Tags]  video_editor  SP-T244
    Start application in VM   "Video Editor"  ${BUSINESS_VM}   lossless

Start Gala
    [Documentation]   Start Gala in Business-vm and verify process started
    [Tags]  gala  SP-T104
    Start application in VM   gala   ${BUSINESS_VM}   gala

*** Keywords ***

Business Apps Test Teardown
    Kill process  @{APP_PIDS}
    Log and remove app output     output.log             ${GUI_VM}    ${USER_LOGIN}
    Run Keyword If Test Failed    Log app vm journalctl  ${BUSINESS_VM}
