# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Business VM
Force Tags          bat  regression  business-vm  lenovo-x1   dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to netvm
Test Setup          Business Apps Test Setup
Test Teardown       Business Apps Test Teardown


*** Test Cases ***

Start Microsoft Outlook on LenovoX1
    [Documentation]   Start Microsoft Outlook in Business-vm and verify process started
    [Tags]  outlook  SP-T176
    Start XDG application   "Microsoft Outlook"
    Switch to vm    business-vm
    Check that the application was started    outlook

Start Microsoft 365 on LenovoX1
    [Documentation]   Start Microsoft 365 in Business-vm and verify process started
    [Tags]  microsoft365  SP-T178
    Start XDG application   "Microsoft 365"
    Switch to vm    business-vm
    Check that the application was started    microsoft365

Start Microsoft Teams on LenovoX1
    [Documentation]   Start Microsoft Teams in Business-vm and verify process started
    [Tags]  teams  SP-T177
    Start XDG application   Teams
    Switch to vm    business-vm
    Check that the application was started    teams

Start Trusted Browser on LenovoX1
    [Documentation]   Start Trusted Browser in Business-vm and verify process started
    [Tags]  trusted_browser  SP-T179
    Start XDG application   "Trusted Browser"
    Switch to vm    business-vm
    Check that the application was started    chrome

Start Video Editor on LenovoX1
    [Documentation]   Start Video Editor in Business-vm and verify process started
    [Tags]  video_editor  SP-T244
    Start XDG application   "Video Editor"
    Switch to vm    business-vm
    Check that the application was started    lossless


*** Keywords ***

Business Apps Test Setup
    Switch to vm    gui-vm  user=${USER_LOGIN}

Business Apps Test Teardown
    Kill process  @{APP_PIDS}
    Log and remove app output     output.log             ${BUSINESS_VM}
    Run Keyword If Test Failed    Log app vm journalctl  ${BUSINESS_VM}
