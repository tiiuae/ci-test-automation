# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Testing settings options

Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/wifi_keywords.resource

Test Tags           gui-settings  lenovo-x1  darter-pro


*** Test Cases ***
Connect to known Wi-Fi in Cosmic Settings
    [Documentation]   Enable Wi-Fi, connect to a known network and disconnect via COSMIC Settings
    ...               Verify Wi-Fi traffic in NetVM
    [Tags]            SP-T527    lab-only
    [Setup]           Prepare known Wi-Fi GUI test
    Open COSMIC Wi-Fi page
    Enable Wi-Fi via GUI
    Locate on screen            text    Known networks    config=--psm 11
    Connect to Wi-Fi via GUI     ${TEST_WIFI_SSID}
    Locate on screen            text    Authentication required
    Confidential password write    ${TEST_WIFI_PSWD}
    Verify Wi-Fi connection
    Disconnect Wi-Fi via GUI       ${TEST_WIFI_SSID}
    Verify Wi-Fi disconnected
    [Teardown]    Run Keywords      Remove Wifi configuration if present    ${TEST_WIFI_SSID}
    ...    AND    Switch to vm      ${NET_VM}
    ...    AND    Run Command       nmcli radio wifi on    sudo=True
    ...    AND    Kill App in VM    ${COSMIC Settings}    require_exists=False
    ...    AND    Switch to vm      ${GUI_VM}    user=${USER_LOGIN}
    ...    AND    Stop screen recording    ${TEST_STATUS}    ${TEST_NAME}

Change timezone in settings
    [Documentation]   Open COSMIC Settings app and change timezone
    [Tags]            SP-T136
    [Setup]           Run Keywords   Start screen recording   AND  Save original timezone
    Set timezone      UTC
    Search in COSMIC Settings   zone
    Tab and enter     tabs=5
    Tab and enter     tabs=2
    Type string       Dubai    enter_at_end=True
    Tab and enter     tabs=1
    Wait Until Keyword Succeeds  10s  1s   Verify timezone   Asia/Dubai
    Sleep   2   # Give time for the timezone change to finish

    [Teardown]   Run Keywords   Set timezone   ${ORIGINAL_TIMEZONE}
    ...          AND   Move cursor to corner
    ...          AND   Kill App in VM          ${COSMIC Settings}
    ...          AND   Stop screen recording   ${TEST_STATUS}   ${TEST_NAME}


*** Keywords ***
Prepare known Wi-Fi GUI test
    [Documentation]    Start screen recording and prepare a disconnected known network
    ...    (Known Networks avoids relying on the search field, which disappears below 15 detected networks)
    Start screen recording
    Switch to vm    ${NET_VM}
    # Start with Wi-Fi off so the test explicitly enables it through the GUI.
    Run Command    nmcli radio wifi off    sudo=True
    Create known Wi-Fi profile    ${TEST_WIFI_SSID}
    [Teardown]    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}

Create known Wi-Fi profile
    [Documentation]    Replace the SSID's profile without connecting or saving a password. Leave the connection in NetVM
    ...    Disable autoconnect and request the password so activation and authentication happen through the GUI
    [Arguments]    ${SSID}
    Switch to vm    ${NET_VM}
    Remove Wifi configuration if present    ${SSID}
    ${command}    Catenate
    ...    nmcli connection add type wifi ifname '*'
    ...    con-name '${SSID}' ssid '${SSID}'
    ...    connection.autoconnect no wifi-sec.key-mgmt wpa-psk wifi-sec.psk-flags 2
    Run Command    ${command}    sudo=True

Open COSMIC Wi-Fi page
    [Documentation]    Open the Wi-Fi page and wait for its Add network control
    Start app via GUI    ${COSMIC Settings}
    Locate and click    text    Network & wireless    scale=2    wiggle=True
    Locate and click    text    Wi-Fi connections and connection profiles    scale=2    config=--psm 11    wiggle=True
    Locate on screen    text    Add network    scale=2    config=--psm 11

Enable Wi-Fi via GUI
    [Documentation]    Locate the toggle relative to Add network to avoid ambiguous Wi-Fi text labels
    ${x}    ${y}    Locate on screen    text    Add network    scale=2    config=--psm 11
    ${x}    Evaluate    ${x} + 15
    ${y}    Evaluate    ${y} + 33
    Run ydotool command    mousemove --absolute -x ${x} -y ${y}
    Click    wiggle=True

Connect to Wi-Fi via GUI
    [Documentation]    Click Connect in the SSID's row to open authentication for the intended network
    [Arguments]        ${SSID}
    Move cursor to corner
    ${x}    ${_}    Locate on screen    text    Connect    scale=2    config=--psm 11
    ${_}    ${y}    Locate on screen    text    ${SSID}    scale=2    precision_percent=90    config=--psm 11
    Run ydotool command    mousemove --absolute -x ${x} -y ${y}
    Click    wiggle=True

Disconnect Wi-Fi via GUI
    [Documentation]    Disconnect the network through its row's menu
    [Arguments]        ${SSID}
    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
    Move cursor to corner
    ${x}    ${_}    Locate on screen    image    wifi-view-more.png    confidence=0.90
    ${_}    ${y}    Locate on screen    text    ${SSID}    scale=2    precision_percent=90    config=--psm 11
    Run ydotool command    mousemove --absolute -x ${x} -y ${y}
    Click    wiggle=True
    Locate and click    text    Disconnect    scale=2    wiggle=True

Search in COSMIC Settings
    [Arguments]     ${search_term}
    Move cursor to corner
    Locate and click  image  ${COSMIC Settings}[icon]  0.95
    # Wait for settings to open
    Locate on screen  text   Network   iterations=20
    Tab and enter     tabs=1
    Tab and enter     tabs=1
    Type string       ${search_term}   enter_at_end=True

Save original timezone
    ${timezone}           Get timezone
    Set Suite Variable    ${ORIGINAL_TIMEZONE}   ${timezone}
