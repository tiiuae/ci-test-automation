# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/KMTronicLibrary.py   ${RELAY_SERIAL_PORT}
Library             ../lib/output_parser.py
Library             AdvancedLogging
Library             OperatingSystem
Library             SerialLibrary    encoding=ascii
Library             String
Resource            ../resources/device_control.resource


*** Keywords ***

Open Serial Port
    [Arguments]   ${timeout}=1.0
    TRY
        Add Port      ${SERIAL_PORT}
        ...           baudrate=115200
        ...           bytesize=8
        ...           parity=N
        ...           stopbits=1
        ...           timeout=${timeout}
        Log           Opened serial port ${SERIAL_PORT}     console=True
        RETURN    True
    EXCEPT   	SerialException: [Errno 2] could not open port ${SERIAL_PORT}: [Errno 2] No such file or directory: '${SERIAL_PORT}'
        RETURN    False
    END

Turn Relay Off
    [Documentation]     Turn given ${relay_number} relay off.
    [Arguments]         ${relay_number}
    Set Relay State     ${relay_number}    OFF
    Sleep    1s
    ${state}            Get Relay State    ${relay_number}
    ${status}           Run Keyword And Return Status     Should Be Equal As Strings    ${state}    OFF
    IF  ${status}
        Log To Console  Relay number:${relay_number} is turned OFF!
    ELSE
        FAIL            Relay number:${relay_number} failed to turn OFF!
    END

Turn Relay On
    [Documentation]     Turn given ${relay_number} relay on.
    [Arguments]         ${relay_number}
    Set Relay State     ${relay_number}   ON
    Sleep    1s
    ${state}            Get Relay State    ${relay_number}
    ${status}           Run Keyword And Return Status     Should Be Equal As Strings    ${state}    ON
    IF  ${status}
        Log To Console  Relay number:${relay_number} is turned ON!
    ELSE
        FAIL            Relay number:${relay_number} failed to turn ON!
    END

Check Serial Connection
    [Documentation]    Check if device is available by serial
    Log To Console     Trying to connect via serial...
    ${serial_status}   Open Serial Port
    IF   ${serial_status}==False
        Log       Serial port is not available      console=True
        RETURN    False
    END
    FOR    ${i}    IN RANGE    30
        Write Data     ${\n}
        ${output}      SerialLibrary.Read Until
        ${status}      Run Keyword And Return Status    Should contain    ${output}    ghaf
        IF    ${status}    BREAK
        Sleep   1
    END
    Delete All Ports
    IF  ${status}
        Log To Console       Device is available via serial
        Set Global Variable  ${CONNECTION_TYPE}    serial
        Set Global Variable  ${IS_AVAILABLE}       True
    ELSE
        Log To Console       Device is not available via serial
    END

Log In To Ghaf OS
    [Documentation]       Log in with ${LOGIN} and ${PASSWORD}
    [Arguments]           ${attempts}=10    ${read_timeout}=5    ${console}=${True}
    ${logged_in}    Set Variable    ${False}
    IF    ${console}
        Log To Console    Trying to log in via serial...
    END
    FOR    ${i}    IN RANGE    ${attempts}
        Write Data        ${\n}
        ${output}         SerialLibrary.Read Until    terminator=${HOST} login    timeout=${read_timeout}
        ${status}         Run Keyword And Return Status    Should contain    ${output}    ${HOST} login
        IF  ${status}
            Write Data    ${LOGIN}${\n}
            ${output}     SerialLibrary.Read Until    terminator=Password
            Write Data    ${PASSWORD}${\n}
        END
        ${status}         Run Keyword And Return Status    Should contain    ${output}    @${HOST}
        IF  ${status}
            ${logged_in}    Set Variable    ${True}
            IF    ${console}
                Log    Successfully logged in    console=True
            END
            BREAK
        END
    END
    IF    not ${logged_in}
        FAIL    Console is not ready
    END
    RETURN    ${logged_in}

Verify init.scope status via serial
    [Arguments]         ${range}=60
    [Documentation]     Check if init.scope service is running with given loop ${range}
    ${status}           Connect via serial  timeout=10
    IF    ${status}==False
        FAIL       Failed to connect via serial, init.scope status was not verified
    END
    ${start_time}       Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        Write Data      systemctl status init.scope${\n}
        ${output}       SerialLibrary.Read Until    terminator=Units
        Write Data      \x03${\n}        # write ctrl+c to stop reading status
        ${status}  ${state}   Get Service Status    ${output}
        IF  '${state}' not in ['running', 'starting']
            Log         init.scope status is ${status}  console=True
            FAIL        init.scope is not running! Status is ${state}
        ELSE IF  '${state}' == 'running'
            ${diff}     Evaluate    int(time.time()) - int(${start_time})
            Log         init.scope status is ${status}  console=True
            RETURN
        END
        Sleep    1
    END
    ${diff}=    Evaluate    int(time.time()) - int(${start_time})
    FAIL    init.scope is not running after ${diff} sec! Status is ${status}
    [Teardown]       Delete All Ports

Connect via serial
    [Arguments]         ${timeout}=1.0
    ${status}           Open Serial Port    timeout=${timeout}
    IF    ${status}
        ${status}   Run Keyword And Return Status    Log In To Ghaf OS
    END
    RETURN    ${status}

Save log
    ${status}            Connect via serial   timeout=60.0
    IF    ${status}==False
        Log    Failed to connect via serial, journalctl logs will be not saved.
    ELSE
        Write Data           sh -c 'journalctl | tee jrnl.txt | cat'${\n}
        ${output}            SerialLibrary.Read Until    ghaf@${HOST}:
        Write Advanced Testlog    journalctl.txt     ${output}
        Log  ${output}
    END
    [Teardown]           Delete All Ports

Get ethernet IP address
    ${status}            Connect via serial
    IF    ${status}
        Write Data           ifconfig${\n}
        ${output}            SerialLibrary.Read Until    ghaf@${HOST}:
        ${ip}                Get ip from ifconfig    ${output}   eth0
        Set Global Variable  ${DEVICE_IP_ADDRESS}  ${ip}
    ELSE
        FAIL     There is no serial connection. Couldn't get IP address.
    END
    [Teardown]           Delete All Ports

Verify shutdown via serial
    [Documentation]   Reading serial port and expects 'System Power Off' text.
    ...               Works only in case of Shutdown (not reboot)
    ...               And only for LAPTOPS
    Log               Wait until shutdown via serial    console=True
    ${status}         Open Serial Port  timeout=60
    IF    ${status}
        ${output}         SerialLibrary.Read Until    System Power Off
        Log               ${output}
        IF  "System Power Off" in $output
            Log    Found "System Power Off" in serial logs    console=True
        ELSE
            Log    Can't find "System Power Off" in serial logs of ${DEVICE}
            Verify shutdown via network
        END
    ELSE
        Verify shutdown via network
    END
    ${time}           BuiltIn.Get Time   epoch
    RETURN            ${time}
    [Teardown]        Delete All Ports

Run Command On Serial
    [Arguments]    ${command}    ${capture}=${True}    ${timeout}=30    ${sudo}=${False}
    ${uart_capture_active}    Get Variable Value    ${UART_CAPTURE_ACTIVE}    ${False}
    ${marker_seed}    Generate Random String    8
    ${start_marker_plain}    Set Variable    __SERIAL_BEGIN_${marker_seed}__
    ${end_marker_plain}    Set Variable    __SERIAL_END_${marker_seed}__
    ${sudo_prompt_plain}    Set Variable    __SERIAL_SUDO_PROMPT_${marker_seed}__
    ${effective_command}    Set Variable    ${command}
    IF    ${sudo}
        ${effective_command}    Set Variable
        ...    sudo -p "$(printf '${sudo_prompt_plain}\\n')" ${command}
    END
    ${start_time}    Get Time    epoch
    Drain Serial Output    ${False}
    Write Data
    ...    printf '\\r\\n${start_marker_plain}\\r\\n'; ${effective_command}; printf '\\r\\n${end_marker_plain}\\r\\n'${\n}
    ${capturing}    Set Variable    ${False}
    ${output}    Set Variable    ${EMPTY}
    WHILE    True
        ${elapsed}    Evaluate    int(time.time()) - int(${start_time})
        IF    ${elapsed} >= ${timeout}
            ${output}    Strip String    ${output}
            FAIL    Timed out after ${timeout}s waiting for serial command completion: ${command}\nPartial output:\n${output}
        END
        ${status}    ${line}    Run Keyword And Ignore Error    SerialLibrary.Read Until    terminator=${\n}    timeout=1
        IF    '${status}' != 'PASS'
            BREAK
        END
        ${line}    Replace String    ${line}    \r    ${EMPTY}
        ${line}    Replace String Using Regexp    ${line}    \\x1B\\[[0-9;?]*[ -/]*[@-~]    ${EMPTY}
        ${line}    Strip String    ${line}
        IF    $line == ''
            CONTINUE
        END
        IF    not ${capturing}
            IF    $line == $start_marker_plain
                ${capturing}    Set Variable    ${True}
            END
            CONTINUE
        END
        IF    $line == $end_marker_plain
            BREAK
        END
        IF    $line == $sudo_prompt_plain
            Send Password Via Serial Quietly
            CONTINUE
        END
        IF    $effective_command != '' and $line == $effective_command
            CONTINUE
        END
        IF    'ghaf@' in $line or '[?2004' in $line or $line == '~]$' or $line == ']$'
            CONTINUE
        END
        ${output}    Catenate    SEPARATOR=\n    ${output}    ${line}
    END
    ${output}    Strip String    ${output}
    RETURN    ${output}

Run Command on VM Via Serial
    [Arguments]        ${vm}    ${command}    ${timeout}=10    ${sudo}=${False}
    IF    "${SERIAL_PORT}" == "NONE"
        FAIL    Serial port is not configured. Cannot execute ${vm} commands via serial.
    END
    ${uart_capture_active}    Get Variable Value    ${UART_CAPTURE_ACTIVE}    ${False}
    ${opened_here}     Set Variable    ${False}
    IF    not ${uart_capture_active}
        ${status}          Connect via serial   timeout=${timeout}
        IF    ${status} == False
            FAIL    Failed to connect via serial. Cannot execute ${vm} commands.
        END
        ${opened_here}    Set Variable    ${True}
    END
    ${effective_command}    Set Variable    ${command}
    IF    ${sudo}
        ${effective_command}    Set Variable
        ...    sudo -S -p '' ${command}
    END
    ${escaped_cmd}     Replace String    ${effective_command}    "    \\" 
    ${ssh_command}     Set Variable    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${vm} "${escaped_cmd}"
    Drain Serial Output    ${False}
    IF    ${sudo}
        Log    Running sudo command in ${vm}    console=True
    ELSE
        Log    Running command in ${vm}    console=True
    END
    Write Data         ${ssh_command}${\n}
    # Consume echoed command line before waiting for the host prompt again.
    SerialLibrary.Read Until    terminator=${\n}
    ${pre_output}      Set Variable    ${EMPTY}
    ${search1}         Set Variable    (yes/no/[fingerprint])?
    ${search2}         Set Variable    assword
    ${status}  ${output}  Run Keyword And Ignore Error  SerialLibrary.Read Until  terminator=${search1}
    IF  $search1 in $output
        ${pre_output}    Catenate    SEPARATOR=    ${pre_output}    ${output}
        Write Data       yes${\n}
        SerialLibrary.Read Until    terminator=${\n}
        ${status}  ${output}  Run Keyword And Ignore Error  SerialLibrary.Read Until  terminator=${search2}
        IF  $search2 in $output
            ${pre_output}    Catenate    SEPARATOR=    ${pre_output}    ${output}
            Send Password Via Serial Quietly
        END
    ELSE
        IF  $search2 in $output
            ${pre_output}    Catenate    SEPARATOR=    ${pre_output}    ${output}
            Send Password Via Serial Quietly
        END
    END
    IF    ${sudo}
        Send Password Via Serial Quietly
    END
    ${prompt_output}   SerialLibrary.Read Until    terminator=ghaf@${HOST}:    timeout=${timeout}
    ${output}          Catenate    SEPARATOR=    ${pre_output}    ${output}    ${prompt_output}
    IF    ${opened_here}
        Delete All Ports
    END
    ${clean_output}    Normalize Serial Output    ${output}
    Log                ${clean_output}
    ${lower_output}    Convert To Lowercase    ${clean_output}
    ${has_vm_error}    Evaluate    'permission denied' in $lower_output or 'could not resolve hostname' in $lower_output or 'no route to host' in $lower_output or 'sorry, try again' in $lower_output
    IF    ${has_vm_error}
        IF    ${sudo}
            FAIL    Failed to execute sudo command '${command}' on ${vm} via serial: ${clean_output}
        END
        FAIL    Failed to execute '${command}' on ${vm} via serial: ${clean_output}
    END
    RETURN            ${clean_output}

Send Password Via Serial Quietly
    ${previous_log_level}    Set Log Level    NONE
    Write Data    ${PASSWORD}${\n}
    Run Keyword And Ignore Error    SerialLibrary.Read Until    terminator=${\n}    timeout=2
    Set Log Level    ${previous_log_level}

Start UART Log Capture
    [Arguments]    ${log_file}=${EMPTY}
    IF  "${SERIAL_PORT}" == "NONE"
        Log To Console         No serial port defined. Cannot start UART log capture.
        Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${False}
        RETURN
    END
    ${test_name}       Replace String     ${TEST_NAME}   ${SPACE}   _
    ${capture_file}    Set Variable If    '${log_file}' == '${EMPTY}'    ${OUTPUT_DIR}/${BUILD_ID}_${test_name}.txt    ${log_file}
    ${status}    Open Serial Port
    IF    not ${status}
        Log To Console    Failed to open serial port for UART capture.
        Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${False}
        RETURN
    END
    Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${True}
    Set Global Variable    ${UART_CAPTURE_FILE}      ${capture_file}
    OperatingSystem.Create File    ${UART_CAPTURE_FILE}

Drain UART Output
    ${uart_capture_active}    Get Variable Value    ${UART_CAPTURE_ACTIVE}    ${False}
    IF    not ${uart_capture_active}
        RETURN
    END
    Drain Serial Output

Drain Serial Output
    [Arguments]    ${save_output}=${True}
    ${empty_reads}    Set Variable    0
    WHILE    True
        ${status}    ${output}    Run Keyword And Ignore Error    SerialLibrary.Read Until    terminator=${\n}    timeout=1
        IF    '${status}' != 'PASS'
            BREAK
        END
        ${clean_output}    Strip String    ${output}
        IF    $clean_output == '${EMPTY}'
            ${empty_reads}    Evaluate    ${empty_reads} + 1
            IF    ${empty_reads} >= 3
                BREAK
            END
            CONTINUE
        END
        ${empty_reads}    Set Variable    0
        IF  ${save_output}
            Append Normalized UART Capture    ${output}
        END
    END

Append Normalized UART Capture
    [Arguments]    ${output}
    ${uart_capture_active}    Get Variable Value    ${UART_CAPTURE_ACTIVE}    ${False}
    IF    not ${uart_capture_active}
        RETURN
    END
    ${normalized_output}    Normalize Serial Output    ${output}
    IF    $normalized_output != ''
        OperatingSystem.Append To File    ${UART_CAPTURE_FILE}    ${normalized_output}${\n}
    END

Collect UART Failure Diagnostics
    ${uart_capture_active}    Get Variable Value    ${UART_CAPTURE_ACTIVE}    ${False}
    IF    ${uart_capture_active}
        ${status}    Run Keyword And Return Status    Wait Until Keyword Succeeds    24x    5s    Log In To Ghaf OS    attempts=1    read_timeout=1    console=${False}
    ELSE
        ${status}    Run Keyword And Return Status    Connect via serial    timeout=60
    END
    IF    not ${status}
        Log    Failed to connect via serial, UART diagnostics were not collected.
        RETURN
    END
    Log To Console    Collecting failure diagnostics via UART...
    ${diag_command}    Set Variable    { uname -r; uptime; systemd-analyze; ip -br a; ss -tlnp; systemctl --failed --no-legend; journalctl -b --no-pager -o short-monotonic; }
    ${dmesg_command}   Set Variable   dmesg | tail -200
    Run Command On Serial    sh -c '${diag_command} > /tmp/${HOST}-diag.txt'
    Save Serial File Output To File    /tmp/${HOST}-diag.txt    ${OUTPUT_DIR}/${HOST}-diag.txt    batch_size=500
    Run Command On Serial    sh -c '${dmesg_command} > /tmp/${HOST}-dmesg.txt'    sudo=${True}
    Save Serial File Output To File    /tmp/${HOST}-dmesg.txt    ${OUTPUT_DIR}/${HOST}-dmesg.txt    batch_size=500
    Run Command On Serial    sh -c 'journalctl -u microvm@net-vm --no-pager > /tmp/ghaf-host-microvm-net-vm-journal.txt'
    Save Serial File Output To File    /tmp/ghaf-host-microvm-net-vm-journal.txt    ${OUTPUT_DIR}/ghaf-host-microvm-net-vm-journal.log    batch_size=500
    ${vm_list_output}    Run Command On Serial    command ls --color=never -1 /var/lib/microvms/
    @{vm_list}    Get Regexp Matches    ${vm_list_output}    (?m)^[A-Za-z0-9_.-]+$
    Should Not Be Empty    ${vm_list}    VM list is empty
    FOR    ${vm}    IN    @{vm_list}
        Run Command on VM Via Serial    ${vm}    sh -c '${diag_command} > /tmp/${vm}-diag.txt'
        Save VM File Output To File     ${vm}    /tmp/${vm}-diag.txt    ${OUTPUT_DIR}/${vm}-diag.txt    batch_size=500
        Run Command on VM Via Serial    ${vm}    sh -c '${dmesg_command} > /tmp/${vm}-dmesg.txt'    sudo=${True}
        Save VM File Output To File     ${vm}    /tmp/${vm}-dmesg.txt    ${OUTPUT_DIR}/${vm}-dmesg.txt    batch_size=500
    END

Save Serial File Output To File
    [Arguments]    ${remote_file}    ${output_file}    ${batch_size}=500
    Save File Output Via Serial Chunk Read    ${output_file}    ${batch_size}    Read Serial File Chunk    ${remote_file}

Save VM File Output To File
    [Arguments]    ${vm}    ${remote_file}    ${output_file}    ${batch_size}=500
    Save File Output Via Serial Chunk Read    ${output_file}    ${batch_size}    Read VM File Chunk    ${vm}    ${remote_file}

Save File Output Via Serial Chunk Read
    [Arguments]    ${output_file}    ${batch_size}    ${read_chunk_keyword}    @{read_chunk_args}
    ${uart_capture_active}    Get Variable Value    ${UART_CAPTURE_ACTIVE}    ${False}
    OperatingSystem.Create File    ${output_file}
    ${start_line}    Set Variable    1
    ${copied_lines}    Set Variable    0
    WHILE    True
        ${end_line}    Evaluate    ${start_line} + ${batch_size} - 1
        ${chunk}    Run Keyword    ${read_chunk_keyword}    @{read_chunk_args}    ${start_line}    ${end_line}
        ${chunk}    Strip String    ${chunk}
        IF    $chunk == ''
            Log To Console    No more lines to copy from serial source after line ${start_line}.
            BREAK
        END
        OperatingSystem.Append To File    ${output_file}    ${chunk}${\n}
        ${chunk_line_count}    Evaluate    len($chunk.splitlines())
        ${copied_lines}    Evaluate    ${copied_lines} + ${chunk_line_count}
        ${start_line}    Evaluate    ${start_line} + ${batch_size}
        Log To Console    Copied ${chunk_line_count} lines (${copied_lines} total) from serial source to ${output_file}
        IF    ${chunk_line_count} < ${batch_size}
            BREAK
        END
    END

Read Serial File Chunk
    [Arguments]    ${remote_file}    ${start_line}    ${end_line}
    ${chunk_command}    Set Variable    sed -n '${start_line},${end_line}p' ${remote_file}
    ${chunk}    Run Command On Serial    ${chunk_command}    capture=${False}
    RETURN    ${chunk}

Read VM File Chunk
    [Arguments]    ${vm}    ${remote_file}    ${start_line}    ${end_line}
    ${chunk_command}    Set Variable    sed -n '${start_line},${end_line}p' ${remote_file}
    ${chunk}    Run Command on VM Via Serial    ${vm}    ${chunk_command}    timeout=30
    RETURN    ${chunk}

Normalize Serial Output
    [Arguments]    ${raw}
    ${output}    Replace String    ${raw}    \r    ${EMPTY}
    # Strip CSI escape sequences used for screen control, colors, cursor moves, and terminal resets.
    ${output}    Replace String Using Regexp    ${output}    \\x1B\\[[0-?]*[ -/]*[@-~]    ${EMPTY}
    # Strip OSC escape sequences, such as title-setting and similar terminal metadata.
    ${output}    Replace String Using Regexp    ${output}    \\x1B\\][^\\x07]*(\\x07|\\x1B\\\\)    ${EMPTY}
    # Strip DCS / PM / APC style escape sequences that some firmware and consoles emit.
    ${output}    Replace String Using Regexp    ${output}    \\x1B[P^_].*?\\x1B\\\\    ${EMPTY}
    # Remove remaining ASCII control characters, keeping printable text only.
    ${output}    Replace String Using Regexp    ${output}    [\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]    ${EMPTY}
    ${lines}    Split To Lines    ${output}
    ${clean_output}    Set Variable    ${EMPTY}
    FOR    ${line}    IN    @{lines}
        ${line}    Strip String    ${line}
        IF    $line == ''
            CONTINUE
        END
        ${clean_output}    Catenate    SEPARATOR=\n    ${clean_output}    ${line}
    END
    ${clean_output}    Strip String    ${clean_output}
    RETURN    ${clean_output}
