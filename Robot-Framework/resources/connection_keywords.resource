# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot


*** Keywords ***

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
