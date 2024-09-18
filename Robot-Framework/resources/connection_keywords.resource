# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot


*** Keywords ***
Configure wifi
    [Arguments]         ${netvm_ssh}  ${SSID}  ${passw}
    Switch Connection   ${netvm_ssh}
    Log To Console      Configuring Wifi
    Set Log Level       NONE
    Execute Command     nmcli dev wifi connect ${SSID} password ${passw}   sudo=True    sudo_password=${PASSWORD}
    Set Log Level       INFO

Remove Wifi configuration
    [Arguments]         ${SSID}
    Switch Connection   ${netvm_ssh}
    Log To Console      Removing Wifi configuration
    Execute Command     nmcli connection delete id ${SSID}

Turn OFF WiFi
    [Arguments]         ${SSID}
    Switch Connection   ${netvm_ssh}
    Log To Console      Turning off Wifi
    Execute Command     nmcli con down id ${SSID}   sudo=True    sudo_password=${PASSWORD}

Turn ON WiFi
    [Arguments]         ${SSID}
    Switch Connection   ${netvm_ssh}
    Log To Console      Turning on Wifi
    Execute Command     nmcli con up id ${SSID}    sudo=True    sudo_password=${PASSWORD}
