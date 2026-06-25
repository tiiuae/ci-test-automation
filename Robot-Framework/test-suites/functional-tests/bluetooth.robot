# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Bluetooth functional tests with external Bluetooth Board
Test Tags           bluetooth  lab-only  lenovo-x1  darter-pro

Library             SerialLibrary    encoding=ascii
Library             Process
Library             OperatingSystem
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Wait Until Keyword Succeeds    180s    5s    Try Acquire Bluetooth Board Lock
Suite Teardown      Release Bluetooth Board Lock

*** Variables ***
${BT_BOARD_LOCK_PATH}        /tmp/.bt-board-lock
${BT_BOARD_LOCK_ACQUIRED}    ${False}

*** Test Cases ***

Connect and disconnect Bluetooth Board
    [Documentation]    Discover Bluetooth Board, connect/disconnect it from audio-vm, and remove device.
    [Tags]             SP-T221
    Switch to vm       ${AUDIO_VM}
    ${bt_board_mac}    Discover bluetooth device by name
    Open Bluetooth Board Serial Port
    Connect bluetooth device       ${bt_board_mac}
    Disconnect bluetooth device    ${bt_board_mac}
    Remove bluetooth device        ${bt_board_mac}
    [Teardown]         Bluetooth test teardown

*** Keywords ***

Try Acquire Bluetooth Board Lock
    [Documentation]    Create the lock file using shell noclobber; fails if it already exists.
    ${timestamp}       Get Time
    ${lock_command}    Set Variable
    ...    ( set -C; { echo "device=${DEVICE}; created_at=${timestamp}"; } > "${BT_BOARD_LOCK_PATH}" ) 2>/dev/null
    ${result}          Run Process    sh    -c    ${lock_command}    stderr=STDOUT
    ${owner}           Get Bluetooth Board Lock Owner
    IF    ${result.rc} != 0
        Log    Bluetooth board is busy. Lock: ${BT_BOARD_LOCK_PATH}, owner: ${owner}    console=True
        FAIL   Bluetooth board is busy. Lock: ${BT_BOARD_LOCK_PATH}, owner: ${owner}
    END
    Log                Bluetooth board lock acquired: ${BT_BOARD_LOCK_PATH}    console=True
    Set Suite Variable    ${BT_BOARD_LOCK_ACQUIRED}    ${True}

Get Bluetooth Board Lock Owner
    [Documentation]    Return the first line from the Bluetooth board lock file.
    ${result}          Run Process    cat    ${BT_BOARD_LOCK_PATH}
    IF    ${result.rc} != 0
        RETURN    ${EMPTY}
    END
    RETURN             ${result.stdout}

Release Bluetooth Board Lock
    [Documentation]    Remove the Bluetooth board lock only if current testrun acquired it.
    IF    ${BT_BOARD_LOCK_ACQUIRED}
        Remove File    ${BT_BOARD_LOCK_PATH}
        Set Suite Variable    ${BT_BOARD_LOCK_ACQUIRED}    ${False}
        Log    Bluetooth board lock removed: ${BT_BOARD_LOCK_PATH}    console=True
    END

Bluetooth test teardown
    [Documentation]    Close Bluetooth board serial port and remove cached target device.
    Close Bluetooth Board Serial Port
    Switch to vm       ${AUDIO_VM}
    Remove cached bluetooth devices by name

Remove cached bluetooth devices by name
    [Documentation]    Disconnect and remove cached Bluetooth devices matching the board name.
    [Arguments]        ${device_name}=${BT_BOARD_NAME}
    Run Command        bluetoothctl power on    rc_match=skip
    ${devices_out}     Run Command    { echo "devices"; echo "quit"; } | bluetoothctl  return=out,err,rc  rc_match=skip  timeout=10
    ${combined_out}    Catenate    SEPARATOR=\n    ${devices_out}[0]    ${devices_out}[1]
    @{matches}         Get Regexp Matches    ${combined_out}    Device ([0-9A-F:]{17}) .*${device_name}    1
    FOR    ${mac}    IN    @{matches}
        Run Command    { echo "disconnect ${mac}"; sleep 1; echo "remove ${mac}"; sleep 1; echo "quit"; } | bluetoothctl    rc_match=skip    timeout=15
    END

Discover bluetooth device by name
    [Documentation]    Scan and return target MAC by advertised name using bluetoothctl.
    [Arguments]        ${device_name}=${BT_BOARD_NAME}    ${scan_delay}=10
    Switch to vm       ${AUDIO_VM}
    ${mac}             Wait Until Keyword Succeeds    3x    1s    Scan bluetooth device by name    ${device_name}    ${scan_delay}
    RETURN             ${mac}

Scan bluetooth device by name
    [Documentation]    Run one bluetoothctl scan and return target MAC by advertised name.
    [Arguments]        ${device_name}=${BT_BOARD_NAME}    ${scan_delay}=10
    Log                Scanning for Bluetooth device "${device_name}".    console=True
    Run Command        bluetoothctl power off
    Run Command        bluetoothctl power on
    ${scan_out}        Run Command
    ...                { echo "scan on"; sleep ${scan_delay}; echo "scan off"; echo "devices"; echo "quit"; } | bluetoothctl
    ...                return=out,err,rc
    ...                rc_match=skip
    ...                timeout=45
    ${combined_out}    Catenate    SEPARATOR=\n    ${scan_out}[0]    ${scan_out}[1]
    @{matches}         Get Regexp Matches    ${combined_out}    Device ([0-9A-F:]{17}) .*${device_name}    1
    ${count}           Get Length    ${matches}
    IF  ${count} == 0
        Log     Scan output:\n${combined_out}
        FAIL    Could not discover Bluetooth device "${device_name}".
    END
    ${mac}             Get From List    ${matches}    -1
    Log                ${BT_BOARD_NAME} MAC: ${mac}     console=True
    RETURN             ${mac}

Connect bluetooth device
    [Documentation]    Connect target device and verify success.
    [Arguments]        ${mac}
    Switch to vm       ${AUDIO_VM}
    Run Command        bluetoothctl power on
    ${output}          Run Command  { echo "connect ${mac}"; sleep 3; echo "quit"; } | bluetoothctl  return=out  rc_match=skip
    Log                ${output}
    ${connected}       Run Keyword And Return Status    Should Contain    ${output}    Connection successful
    IF    not ${connected}
        Log Bluetooth Board Serial Output
        FAIL    Couldn't connect Bluetooth Board (didn't find 'Connection successful'). bluetoothctl output:\n${output}
    END
    Log                Bluetooth Board is connected     console=True
    Wait Until Keyword Succeeds    30s    1s    Read BT Serial Until    Connected

Disconnect bluetooth device
    [Documentation]    Disconnect target device and verify disconnected state.
    [Arguments]        ${mac}
    Switch to vm       ${AUDIO_VM}
    ${output}          Run Command  { echo "disconnect ${mac}"; sleep 3; echo "quit"; } | bluetoothctl  return=out  rc_match=skip
    Log                ${output}
    ${disconnected}    Run Keyword And Return Status    Should Contain    ${output}    Disconnection successful
    IF    not ${disconnected}
        Log Bluetooth Board Serial Output
        FAIL    Couldn't disconnect Bluetooth Board (didn't find 'Disconnection successful'). bluetoothctl output:\n${output}
    END
    Wait Until Keyword Succeeds    30s    1s    Read BT Serial Until    Disconnected
    Wait Until Keyword Succeeds    30s    1s    Read BT Serial Until    Advertising restarted
    Log                Bluetooth Board is disconnected     console=True

Remove bluetooth device
    [Documentation]    Remove target device from bluetoothctl cache.
    [Arguments]        ${mac}
    Switch to vm       ${AUDIO_VM}
    ${output}          Run Command  { echo "remove ${mac}"; sleep 1; echo "quit"; } | bluetoothctl  return=out  rc_match=skip
    Log                ${output}
    Log                Bluetooth Board is removed from Known Devices     console=True

Open Bluetooth Board Serial Port
    [Documentation]    Open serial console of the Bluetooth test board, not the DUT serial console.
    TRY
        Add Port      ${BT_SERIAL_PORT}
        ...           baudrate=115200
        ...           bytesize=8
        ...           parity=N
        ...           stopbits=1
        ...           timeout=1
        Log           Opened Bluetooth board serial port ${BT_SERIAL_PORT}    console=True
    EXCEPT    AS    ${error}
        FAIL    Could not open Bluetooth board serial port ${BT_SERIAL_PORT}: ${error}
    END

Close Bluetooth Board Serial Port
    [Documentation]    Close all SerialLibrary ports opened by this test.
    TRY
        Delete All Ports
    EXCEPT
        Log    Bluetooth board serial ports were already closed.    DEBUG
    END

Read BT Serial Until
    [Documentation]    Read one line from the Bluetooth board serial output and verify expected text.
    [Arguments]        ${expected}
    ${output}          SerialLibrary.Read Until    terminator=${\n}
    Log                Bluetooth board serial output: ${output}
    Should Contain     ${output}    ${expected}    Bluetooth board serial output did not contain "${expected}" on ${BT_SERIAL_PORT}. Output:\n${output}
    RETURN             ${output}

Log Bluetooth Board Serial Output
    [Documentation]    Log available Bluetooth board serial output
    [Arguments]        ${wait_seconds}=5
    Sleep              ${wait_seconds}
    ${output}          SerialLibrary.Read All Data
    Log                ${output}
