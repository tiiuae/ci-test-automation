# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

***Settings***
Documentation       Testing Business VM
Force Tags          gui lenovo-x1
Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource
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
Logim to Microsoft Outlook
    [Documentation]   Start Microsoft Outlook in dedicated VM and login
    [Tags]  outlook   SP-5328
    # Configure wifi  ${netvm_ssh}  ${ta_wifi_ssid}  ${TA_WIFI_PSWD}  lenovo=True
    Connect to netvm
    Connect to VM       ${BUSINESS_VM}
    Open Browser  browser=chromium
    Log to console  open browser
    Sleep  20
    Check Application Login Page
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

Check Application Login Page
    [Documentation]  Check that user is able to login
    Log  Checking items
