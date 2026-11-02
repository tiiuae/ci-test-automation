# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Bluetooth functional tests with external Bluetooth Board

Resource            ../../resources/bluetooth.resource

Suite Setup         Wait Until Keyword Succeeds    180s    5s    Try Acquire Bluetooth Board Lock
Suite Teardown      Release Bluetooth Board Lock

Test Tags           bluetooth  lenovo-x1  darter-pro  lab-only


*** Test Cases ***
Connect and disconnect Bluetooth Board
    [Documentation]    Discover Bluetooth Board, connect/disconnect it from audio-vm, and remove device.
    [Tags]             SP-T423
    Switch to vm       ${AUDIO_VM}
    ${bt_board_mac}    Discover bluetooth device by name
    Open Bluetooth Board Serial Port
    Connect bluetooth device       ${bt_board_mac}
    Disconnect bluetooth device    ${bt_board_mac}
    Remove bluetooth device        ${bt_board_mac}
    [Teardown]         Bluetooth test teardown


*** Keywords ***
Bluetooth test teardown
    [Documentation]    Close Bluetooth board serial port and remove cached target device.
    Close Bluetooth Board Serial Port
    Switch to vm       ${AUDIO_VM}
    Remove cached bluetooth devices by name
