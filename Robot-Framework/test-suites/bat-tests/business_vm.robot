# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Business VM
Force Tags          bat  businessvm  lenovo-x1
Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/virtualization_keywords.resource
Resource            ../../resources/common_keywords.resource
Library             Browser

Suite Teardown      Close All Connections
Test Setup          Run Keywords  Connect to netvm  AND  Connect to VM  ${GUI_VM}

*** Variables ***
${ta_wifi_ssid}    TII-Testautomation
${netvm_ssh}       ${EMPTY}


*** Test Cases ***
Start Microsoft Outlook on LenovoX1
    [Documentation]   Start Microsoft Outlook in dedicated VM and verify process started
    [Tags]  outlook  SP-T176
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   "Microsoft Outlook"
    Connect to VM       ${BUSINESS_VM}
    Check that the application was started    outlook
    [Teardown]  Kill process  @{app_pids}

Start Microsoft 365 on LenovoX1
    [Documentation]   Start Microsoft 365 in dedicated VM and verify process started
    [Tags]  microsoft365  SP-T178
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   "Microsoft 365"
    Connect to VM       ${BUSINESS_VM}
    Check that the application was started    microsoft365
    [Teardown]  Kill process  @{app_pids}

Start Microsoft Teams on LenovoX1
    [Documentation]   Start Microsoft Teams in dedicated VM and verify process started
    [Tags]  teams  SP-T177
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   Teams
    Connect to VM       ${BUSINESS_VM}
    Check that the application was started    teams
    [Teardown]  Kill process  @{app_pids}

Start Trusted Browser on LenovoX1
    [Documentation]   Start Trusted Browser in dedicated VM and verify process started
    [Tags]  trusted_browser  SP-T179
    Connect to netvm
    Connect to VM       ${GUI_VM}
    Start XDG application   "Trusted Browser"
    Connect to VM       ${BUSINESS_VM}
    Check that the application was started    chromium
    [Teardown]  Kill process  @{app_pids}
