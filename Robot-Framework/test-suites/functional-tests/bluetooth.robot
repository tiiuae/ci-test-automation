# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Bluetooth functional tests with external Bluetooth Board
Test Tags           bluetooth  lab-only  lenovo-x1  darter-pro

Library             SerialLibrary    encoding=ascii
Library             Process
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Acquire Bluetooth Board Lock
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

Acquire Bluetooth Board Lock
    [Documentation]    Lock the shared Bluetooth board, wait up to 3 minutes if board is busy
    [Arguments]        ${timeout}=180    ${interval}=5
    ${start_time}      Get Time    epoch
    WHILE    True
        ${acquired}    Try Acquire Bluetooth Board Lock
        IF    ${acquired}
            Log    Bluetooth board lock acquired: ${BT_BOARD_LOCK_PATH}    console=True
            Set Suite Variable    ${BT_BOARD_LOCK_ACQUIRED}    ${True}
            RETURN
        END
        ${owner}       Get Bluetooth Board Lock Owner
        ${elapsed}     Evaluate    int(time.time()) - int(${start_time})
        IF    ${elapsed} >= ${timeout}
            FAIL    Bluetooth board stayed busy for ${timeout} seconds. Lock: ${BT_BOARD_LOCK_PATH}, owner: ${owner}
        END
        Log    Bluetooth board is busy, waiting ${interval} seconds. Lock: ${BT_BOARD_LOCK_PATH}, owner: ${owner}    console=True
        Sleep    ${interval}
    END

Try Acquire Bluetooth Board Lock
    [Documentation]    Create the lock file using shell noclobber; fails if it already exists.
    ${timestamp}       Get Time
    ${lock_command}    Set Variable
    ...    ( set -C; { echo "device=${DEVICE}; created_at=${timestamp}"; } > "${BT_BOARD_LOCK_PATH}" ) 2>/dev/null
    ${result}          Run Process    sh    -c    ${lock_command}    stderr=STDOUT
    ${acquired}        Evaluate    ${result.rc} == 0
    RETURN             ${acquired}

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
        Run Process    rm    -f    ${BT_BOARD_LOCK_PATH}
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
    ${output}          Run Command  { echo "connect ${mac}"; sleep 1; echo "quit"; } | bluetoothctl  return=out  rc_match=skip
    Log                ${output}
    Should Contain     ${output}    Connection successful    Couldn't connect Bluetooth Board (didn't find 'Connection successful')
    Log                Bluetooth Board is connected     console=True
    Read Bluetooth Board Serial Until    Connected

Disconnect bluetooth device
    [Documentation]    Disconnect target device and verify disconnected state.
    [Arguments]        ${mac}
    Switch to vm       ${AUDIO_VM}
    ${output}          Run Command  { echo "disconnect ${mac}"; sleep 3; echo "quit"; } | bluetoothctl  return=out  rc_match=skip
    Log                ${output}
    Should Contain     ${output}    Disconnection successful   Couldn't disconnect Bluetooth Board (didn't find 'Disconnection successful')
    Read Bluetooth Board Serial Until    Disconnected
    Read Bluetooth Board Serial Until    Advertising restarted
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
    Run Keyword And Ignore Error    Delete All Ports

Read Bluetooth Board Serial Until
    [Documentation]    Read realtime output from BT_SERIAL_PORT until expected text appears.
    [Arguments]        ${expected}    ${timeout}=30
    ${logs}            Set Variable    ${EMPTY}
    ${found}           Set Variable    ${False}
    ${start_time}      Get Time    epoch
    WHILE    not ${found}
        ${elapsed}    Evaluate    int(time.time()) - int(${start_time})
        IF    ${elapsed} >= ${timeout}
            BREAK
        END
        ${status}    ${output}    Run Keyword And Ignore Error    SerialLibrary.Read Until    terminator=${\n}
        IF    '${status}' != 'PASS'
            CONTINUE
        END
        ${logs}      Catenate    SEPARATOR=    ${logs}    ${output}
        IF    $expected in $logs
            ${found}    Set Variable    ${True}
        END
    END
    Log    Bluetooth board serial output while waiting for "${expected}":\n${logs}
    IF     not ${found}
        FAIL    Bluetooth board serial output did not contain "${expected}" on ${BT_SERIAL_PORT} in ${timeout}s. Output:\n${logs}
    END
    RETURN    ${logs}
