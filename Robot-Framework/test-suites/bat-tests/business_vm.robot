# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Business VM
Force Tags          bat  businessvm  lenovo-x1
Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/virtualization_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/gui_keywords.resource
Library             ../../lib/gui_testing.py
Library             Browser

# Suite Teardown      Run Keywords  Remove Wifi configuration  AND  Close All Connections
# Suite Teardown      Close All Connections
# Test Setup          Run Keywords  Connect to netvm  AND  Connect to VM  ${GUI_VM}

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

Logim to Microsoft Outlook on LenovoX1
    [Documentation]   Start Microsoft Outlook in dedicated VM and login
    [Tags]  outlook   SP-5328

    Run Keyword And Continue On Failure  GUI Log in
    Run Keyword And Continue On Failure  Verify login
    Configure wifi  ${netvm_ssh}  ${ta_wifi_ssid}  ${TA_WIFI_PSWD}  lenovo=True
    # Start ydotoold
    Log To Console    Typing username and password to login
    Browser.Open Browser  browser=chromium
    Connect to VM       ${BUSINESS_VM}
    Log to console  open browser
    Sleep  20
    Check Application Login Page
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

*** Keywords ***
# Remove these after rebasing logging pr
Configure wifi
    [Arguments]   ${netvm_ssh}  ${SSID}  ${passw}  ${lenovo}=False
    Switch Connection  ${netvm_ssh}
    Log To Console     Configuring Wifi
    IF  ${lenovo}
        Execute Command    nmcli dev wifi connect ${SSID} password ${passw}   sudo=True    sudo_password=${PASSWORD}
    ELSE
        Execute Command    sh -c "wpa_passphrase ${SSID} ${passw} > /etc/wpa_supplicant.conf"   sudo=True    sudo_password=${PASSWORD}
        Execute Command    systemctl restart wpa_supplicant.service   sudo=True    sudo_password=${PASSWORD}
    END

Remove Wifi configuration
    [Arguments]         ${lenovo}=False
    Switch Connection   ${netvm_ssh}
    Log To Console      Removing Wifi configuration
    IF  ${lenovo}
        Execute Command    nmcli con down id ${SSID}   sudo=True    sudo_password=${PASSWORD}
    ELSE
        Execute Command    rm /etc/wpa_supplicant.conf  sudo=True    sudo_password=${PASSWORD}
        Execute Command    systemctl restart wpa_supplicant.service  sudo=True    sudo_password=${PASSWORD}
    END