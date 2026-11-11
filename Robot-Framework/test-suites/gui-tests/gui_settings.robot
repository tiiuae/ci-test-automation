# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Testing settings options

Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/wifi_keywords.resource

Test Tags           gui-settings  lenovo-x1  darter-pro


*** Test Cases ***
Verify hardware and operating system information in Cosmic Settings
    [Documentation]   Open the About page and compare its hardware and OS information with command-line values.
    ...               Check hardware identity on the host and OS, CPU and memory in GUI VM.
    [Tags]            SP-T530
    [Setup]           Start screen recording
    ${screenshot_path}    ${_}    Capture Action Changes    Open COSMIC About page
    Verify COSMIC About information    ${screenshot_path}
    [Teardown]    COSMIC About Test Teardown

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
Open COSMIC About page
    [Documentation]    Launch COSMIC Settings and open System & accounts → About.
    Start app via GUI    ${COSMIC Settings}
    Locate and click    text    System & accounts    scale=2    wiggle=True
    Locate and click    text    About                scale=2    wiggle=True
    Locate on screen    text    Operating system     scale=2    config=--psm 11

Verify COSMIC About information
    [Arguments]    ${screenshot_path}
    ${os}              Run Command    . /etc/os-release; printf '%s' "$PRETTY_NAME"
    ${architecture}    Run Command    uname -m
    ${kernel}          Run Command    uname -r
    ${desktop}         Run Command    cosmic-settings --version
    ${desktop}         Replace String    ${desktop}    cosmic-settings    COSMIC
    ${windowing}       Run Command    systemctl --user show-environment | sed -n 's/^XDG_SESSION_TYPE=//p'
    ${windowing}       Convert To Title Case    ${windowing}
    ${processor}       Run Command    sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n 1
    ${memory}          Run Command    awk '/^MemTotal:/ {printf "%.2f GiB", $2 / 1024 / 1024}' /proc/meminfo
    ${vendor}    ${model}    Get host hardware identity
    ${failures}        Create List
    ${ocr_data}        Get Data From Image    ${screenshot_path}    scale=3    config=--psm 11

    Check COSMIC About field    ${ocr_data}    Operating system                 ${os}              ${failures}
    Check COSMIC About field    ${ocr_data}    Operating system architecture    ${architecture}    ${failures}
    Check COSMIC About field    ${ocr_data}    Kernel version                   ${kernel}          ${failures}
    Check COSMIC About field    ${ocr_data}    Desktop environment              ${desktop}         ${failures}
    Check COSMIC About field    ${ocr_data}    Windowing system                 ${windowing}       ${failures}
    Check COSMIC About field    ${ocr_data}    Processor                        ${processor}       ${failures}
    Check COSMIC About field    ${ocr_data}    Memory                           ${memory}          ${failures}
    ${vendor_matches}    Check COSMIC About hardware model    ${ocr_data}    ${vendor}    ${model}    ${failures}

    IF    $failures    FAIL    ${failures}
    IF    not $vendor_matches
        Log Error    COSMIC hardware vendor    COSMIC About shows QEMU instead of ${vendor} (SSRCSP-9243)
        SKIP    Known issue: SSRCSP-9243 (COSMIC About shows QEMU instead of ${vendor})
    END

Get host hardware identity
    [Documentation]    Read physical DMI from the host; GUI VM's own DMI describes virtual hardware.
    [Setup]    Switch to vm    ${HOST}
    ${vendor}    Run Command    cat /sys/class/dmi/id/sys_vendor
    ${model}     Run Command    cat /sys/class/dmi/id/board_name
    Should Not Be Empty    ${vendor}
    Should Not Be Empty    ${model}
    RETURN    ${vendor}    ${model}
    [Teardown]    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}

Check COSMIC About field
    [Arguments]    ${ocr_data}    ${field}    ${expected}    ${failures}
    Should Not Be Empty    ${expected}    No command-line value for ${field}.
    ${actual}    Get Text Field From Data    ${ocr_data}    ${field}
    IF    $actual != $expected
        Append To List    ${failures}    ${field} in COSMIC About is '${actual}', expected '${expected}'.
    END

Check COSMIC About hardware model
    [Arguments]    ${ocr_data}    ${vendor}    ${model}    ${failures}
    ${actual}    Get Text Field From Data    ${ocr_data}    Hardware model
    ${vendor_matches}    Run Keyword And Return Status    Should Start With    ${actual}    ${vendor}    ignore_case=True
    IF    not $vendor_matches and not $actual.startswith('QEMU ')
        Append To List    ${failures}    Hardware model in COSMIC About is '${actual}', expected vendor '${vendor}'.
    END
    # Board identifiers contain letters and digits that OCR can confuse, for example O and 0.
    ${recognized_model}    Replace String    ${actual}    O    0
    ${expected_model}      Replace String    ${model}     O    0
    ${model_matches}       Run Keyword And Return Status    Should Contain    ${recognized_model}    ${expected_model}
    IF    not $model_matches
        Append To List    ${failures}    Hardware model in COSMIC About is '${actual}', expected board model '${model}'.
    END
    RETURN    ${vendor_matches}

COSMIC About Test Teardown
    Kill App in VM    ${COSMIC Settings}    require_exists=False
    Switch to vm    ${GUI_VM}    user=${USER_LOGIN}
    Stop screen recording    ${TEST_STATUS}    ${TEST_NAME}
    Run Keyword If Test Passed    Remove Captured Screenshots

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
