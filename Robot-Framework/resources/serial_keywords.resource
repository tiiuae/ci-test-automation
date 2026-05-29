# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             ../lib/KMTronicLibrary.py   ${RELAY_SERIAL_PORT}
Library             ../lib/output_parser.py
Library             ../lib/helper_functions.py
Library             AdvancedLogging
Library             OperatingSystem
Library             SerialLibrary    encoding=ascii
Library             String
Resource            ../resources/device_control.resource


*** Keywords ***

Open Serial Port
    [Arguments]   ${timeout}=2.0
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
    [Arguments]           ${attempts}=10
    Log To Console        Trying to log in via serial...
    FOR    ${i}    IN RANGE    ${attempts}
        Write Data        ${\n}
        ${output}         SerialLibrary.Read Until    terminator=${HOST} login
        ${status}         Run Keyword And Return Status    Should contain    ${output}    ${HOST} login
        IF  ${status}
            Write Data    ${LOGIN}${\n}
            ${output}     SerialLibrary.Read Until    terminator=Password
            Write Data    ${PASSWORD}${\n}
        END
        ${status}         Run Keyword And Return Status    Should contain    ${output}    @${HOST}
        IF  ${status}
            Log To Console    Successfully logged in
            RETURN
        END
    END
    FAIL    Serial console is not ready

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
    [Arguments]         ${since}=${EMPTY}
    ${status}            Connect via serial   timeout=60.0
    IF    ${status}==False
        Log    Failed to connect via serial, journalctl logs will be not saved.
    ELSE
        ${journalctl_cmd}    Set Variable    journalctl
        IF    '${since}' != '${EMPTY}'
            ${journalctl_cmd}    Set Variable    journalctl --since "@${since}"
        END
        Write Data           sh -c '${journalctl_cmd} | tee /tmp/jrnl.txt | cat'${\n}
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
    [Documentation]    Run a host command on the serial console and wait for the shell prompt.
    ...                NOTE: Does not currently work if NOPASSWD sudo is enabled.
    [Arguments]    ${command}    ${timeout}=30    ${sudo}=${False}    ${pre_flush}=${True}
    ${opened_here}     Set Variable    ${False}
    IF    not ${UART_CAPTURE_ACTIVE}
        ${status}    Connect via serial    timeout=${timeout}
        IF    ${status} == False
            FAIL    Failed to connect via serial. Cannot execute host command.
        END
        ${opened_here}    Set Variable    ${True}
    END
    ${effective_command}    Set Variable    ${command}
    IF    ${sudo}
        ${effective_command}    Set Variable    sudo ${command}
    END
    Run Keyword If    ${pre_flush}    Drain Serial Output
    Write Data    ${effective_command}${\n}
    ${first_line}    SerialLibrary.Read Until    terminator=${\n}
    IF  ${sudo}
        ${search}    Set Variable    assword
        ${status}    ${output}    Run Keyword And Ignore Error
        ...    SerialLibrary.Read Until    terminator=${search}
        IF    $search in $output
            Send Password Via Serial Quietly
        END
    END
    ${output}    SerialLibrary.Read Until    terminator=ghaf@${HOST}:
    IF    ${opened_here}
        Delete All Ports
    END
    ${clean_output}    Normalize Serial Output    ${output}
    ${lower_output}    Convert To Lowercase    ${clean_output}
    ${has_host_error}    Evaluate    'permission denied' in $lower_output or 'sorry, try again' in $lower_output
    IF    ${has_host_error}
        IF    ${sudo}
            FAIL    Failed to execute sudo command '${command}' on host via serial: ${clean_output}
        END
        FAIL    Failed to execute '${command}' on host via serial: ${clean_output}
    END
    RETURN    ${clean_output}

Run Command on VM Via Serial
    [Documentation]    Execute a command on a VM through the host serial console and tunneling via ssh.
    [Arguments]        ${vm}    ${command}    ${output_redirect}=NONE    ${timeout}=5    ${sudo}=${False}    ${pre_flush}=${True}    ${logging}=${True}
    IF    "${SERIAL_PORT}" == "NONE"
        FAIL    Serial port is not configured. Cannot execute ${vm} commands via serial.
    END
    ${opened_here}     Set Variable    ${False}
    IF    not ${UART_CAPTURE_ACTIVE}
        ${status}          Connect via serial   timeout=${timeout}
        IF    ${status} == False
            FAIL    Failed to connect via serial. Cannot execute ${vm} commands.
        END
        ${opened_here}    Set Variable    ${True}
    END
    ${effective_command}    Set Variable    ${command}
    ${ssh_options}         Set Variable
    ...    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
    IF    ${sudo}
        ${effective_command}    Set Variable    sudo ${command}
        ${ssh_options}         Set Variable    -t ${ssh_options}
    END
    ${escaped_cmd}     Replace String    ${effective_command}    "    \\" 
    ${ssh_command}     Set Variable    ssh ${ssh_options} ${vm} "${escaped_cmd}"
    IF  $output_redirect != 'NONE'
        ${ssh_command}     Set Variable    ${ssh_command} > ${output_redirect}
    END
    Run Keyword If     ${pre_flush}    Drain Serial Output
    IF  ${logging}
        IF    ${sudo}
            Log    Running sudo command in ${vm}    console=True
        ELSE
            Log    Running command in ${vm}    console=True
        END
    END
    Write Data         ${ssh_command}${\n}
    # Consume echoed command line
    SerialLibrary.Read Until    terminator=${\n}
    ${search1}         Set Variable    (yes/no/[fingerprint])?
    ${search2}         Set Variable    assword
    ${post_auth_output}    Set Variable    ${EMPTY}
    ${status}  ${output}  Run Keyword And Ignore Error  SerialLibrary.Read Until  terminator=${search1}
    IF  $search1 in $output
        Write Data       yes${\n}
        SerialLibrary.Read Until    terminator=${\n}
        ${status}  ${output}  Run Keyword And Ignore Error  SerialLibrary.Read Until  terminator=${search2}
        IF  $search2 in $output
            Send Password Via Serial Quietly
        END
    ELSE
        IF  $search2 in $output
            Send Password Via Serial Quietly
        END
    END
    # If the command was run with sudo expect another password prompt
    IF    ${sudo}
        ${status}  ${post_auth_output}  Run Keyword And Ignore Error  SerialLibrary.Read Until  terminator=${search2}
        IF  $search2 in $post_auth_output
            Send Password Via Serial Quietly
        END
    END
    ${prompt_output}   SerialLibrary.Read Until    terminator=ghaf@${HOST}:
    IF    $post_auth_output != '${EMPTY}' and $search2 not in $post_auth_output
        ${prompt_output}    Catenate    SEPARATOR=    ${post_auth_output}    ${prompt_output}
    END
    IF    ${opened_here}
        Delete All Ports
    END
    ${clean_output}    Normalize Serial Output    ${prompt_output}
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
    [Documentation]    Send a password over serial with logging disabled.
    ${previous_log_level}    Set Log Level    NONE
    Write Data    ${PASSWORD}${\n}
    Set Log Level    ${previous_log_level}

Start UART Log Capture
    [Documentation]    Open the serial port for passive UART capture and initialize the target log file.
    [Arguments]    ${log_file}=${EMPTY}
    IF  "${SERIAL_PORT}" == "NONE"
        Log To Console         No serial port defined. Cannot start UART log capture.
        Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${False}
        RETURN
    END
    Create Directory   ${BOOT_DIAGNOSTICS_DIR}
    ${test_name}       Replace String     ${TEST_NAME}   ${SPACE}   _
    ${capture_file}    Set Variable If    '${log_file}' == '${EMPTY}'    ${BOOT_DIAGNOSTICS_DIR}/${BUILD_ID}_${test_name}.txt    ${log_file}
    ${status}    Open Serial Port    timeout=5.0
    IF    not ${status}
        Log To Console    Failed to open serial port for UART capture.
        Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${False}
        RETURN
    END
    Set Global Variable    ${UART_CAPTURE_ACTIVE}    ${True}
    Set Global Variable    ${UART_CAPTURE_FILE}      ${capture_file}
    OperatingSystem.Create File    ${UART_CAPTURE_FILE}

Drain Serial Output
    [Documentation]    Drain pending serial output until idle or timeout, optionally appending normalized output to the UART log file.
    [Arguments]    ${save_output}=${False}    ${max_seconds}=3
    ${empty_reads}    Set Variable    0
    ${start_time}    Get Time    epoch
    WHILE    True
        ${elapsed}    Evaluate    int(time.time()) - int(${start_time})
        IF    ${elapsed} >= ${max_seconds}
            BREAK
        END
        ${status}    ${output}    Run Keyword And Ignore Error    SerialLibrary.Read Until    terminator=${\n}
        IF    '${status}' != 'PASS'
            BREAK
        END
        ${clean_output}    Strip String    ${output}
        IF    $clean_output == '${EMPTY}'
            ${empty_reads}    Evaluate    ${empty_reads} + 1
            IF    ${empty_reads} > 2
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
    [Documentation]    Normalize raw serial text and append only readable content to the active UART log file.
    [Arguments]    ${output}
    IF    not ${UART_CAPTURE_ACTIVE}
        RETURN
    END
    ${normalized_output}    Normalize Serial Output    ${output}
    IF    $normalized_output != ''
        OperatingSystem.Append To File    ${UART_CAPTURE_FILE}    ${normalized_output}${\n}
    END

Collect Failure Diagnostics Via Serial
    [Documentation]    Collect host and VM diagnostics via serial after a failed boot.
    ...                Use various ways to collect specific command output, depending on
    ...                - how small/large output is expected,
    ...                - if sudo is required
    ...                - target location for running the command ( host / vm )
    IF    ${UART_CAPTURE_ACTIVE}
        ${status}    Run Keyword And Return Status    Wait Until Keyword Succeeds    24x    5s    Log In To Ghaf OS    attempts=1
    ELSE
        ${status}    Run Keyword And Return Status    Connect via serial    timeout=20
    END
    IF    not ${status}
        Log    Failed to connect via serial, UART diagnostics were not collected.
        RETURN
    END
    Log To Console    Collecting failure diagnostics via UART...

    @{diagnostic_commands}    Create List
    ...    uname -r
    ...    uptime
    ...    systemd-analyze
    ...    ip -br a
    ...    ss -tlnp
    ...    systemctl --failed --no-legend

    ${dmesg_command}   Set Variable   dmesg | tail -200

    # Commands with expected small output
    Run Diagnostic Commands Via Serial    ${HOST}    @{diagnostic_commands}

    # Collect expected large outputs by splitting them into batches
    Run Command On Serial    sh -c '${dmesg_command} > /tmp/${HOST}-dmesg.txt'    sudo=${True}    pre_flush=${False}
    Sleep    1
    Save Serial File Output To File    /tmp/${HOST}-dmesg.txt    ${BOOT_DIAGNOSTICS_DIR}/${HOST}-dmesg.txt
    Run Command On Serial    sh -c 'journalctl -b --no-pager -o short-monotonic > /tmp/${HOST}_journalctl_-b.txt'    pre_flush=${True}
    Sleep    1
    Save Serial File Output To File    /tmp/${HOST}_journalctl_-b.txt    ${BOOT_DIAGNOSTICS_DIR}/${HOST}_journalctl_-b.txt
    Run Command On Serial    sh -c 'journalctl -u microvm@net-vm --no-pager > /tmp/ghaf-host-microvm-net-vm-journal.txt'    pre_flush=${False}
    Sleep    1
    Save Serial File Output To File    /tmp/ghaf-host-microvm-net-vm-journal.txt    ${BOOT_DIAGNOSTICS_DIR}/ghaf-host-microvm-net-vm-journal.txt

    Drain Serial Output
    ${vm_list_output}    Run Command On Serial    command ls --color=never -1 /var/lib/microvms/
    @{vm_list}    Get Regexp Matches    ${vm_list_output}    (?m)^[A-Za-z0-9_.-]+$
    Should Not Be Empty    ${vm_list}    VM list is empty
    FOR    ${vm}    IN    @{vm_list}
        Run Diagnostic Commands Via Serial    ${vm}    @{diagnostic_commands}

        ${dmesg_output}    Run Command on VM Via Serial    ${vm}    sh -c '${dmesg_command}'    sudo=${True}    pre_flush=${False}    logging=${False}
        OperatingSystem.Create File        ${BOOT_DIAGNOSTICS_DIR}/${vm}-dmesg.txt    ${dmesg_output}

        Run Command on VM Via Serial    ${vm}    sh -c 'journalctl -b --no-pager -o short-monotonic'    output_redirect=/tmp/${vm}_journalctl_-b.txt    pre_flush=${True}    logging=${False}
        Sleep    1
        Save Serial File Output To File    /tmp/${vm}_journalctl_-b.txt    ${BOOT_DIAGNOSTICS_DIR}/${vm}_journalctl_-b.txt
    END

Run Diagnostic Commands Via Serial
    [Documentation]    Run each diagnostic command, store its output on the host, and copy it to the local output directory.
    [Arguments]    ${vm}    @{commands}
    Log               Collecting diagnostics from ${vm}    console=True
    ${output_file}    Set Variable    ${BOOT_DIAGNOSTICS_DIR}/${vm}-diagnostics.txt
    OperatingSystem.Create File       ${output_file}
    FOR    ${command}    IN    @{commands}
        ${output_name}    Replace String    ${command}    ${SPACE}    _
        IF  $vm != '${HOST}'
            ${cmd_output}    Run Command on VM Via Serial    ${vm}    sh -c '${command}'    pre_flush=${True}    logging=${False}
        ELSE
            ${cmd_output}    Run Command On Serial    sh -c '${command}'    pre_flush=${True}
        END
        OperatingSystem.Append To File     ${output_file}    ${command}\n$${cmd_output}\n\n
        Log    Saved "${command}" output from ${vm} to ${output_file}    console=True
    END

Save Serial File Output To File
    [Documentation]    Copy a host-side file through serial session to a local file in fixed-size line batches.
    [Arguments]    ${remote_file}    ${output_file}    ${batch_size}=300
    Save File Output Via Serial Chunk Read    ${output_file}    ${batch_size}    Read Serial File Chunk    ${remote_file}

Save VM File Output To File
    [Documentation]    Copy a VM-side file through serial connection and ssh tunnel to a local file in fixed-size line batches.
    [Arguments]    ${vm}    ${remote_file}    ${output_file}    ${batch_size}=300
    Save File Output Via Serial Chunk Read    ${output_file}    ${batch_size}    Read VM File Chunk    ${vm}    ${remote_file}

Save File Output Via Serial Chunk Read
    [Documentation]    Shared chunked file-copy loop used by host and VM serial readers to avoid large in-memory outputs.
    [Arguments]    ${output_file}    ${batch_size}    ${read_chunk_keyword}    @{read_chunk_args}    ${timeout}=30
    OperatingSystem.Create File    ${output_file}
    ${start_line}      Set Variable    1
    ${copied_lines}    Set Variable    0
    ${start_time}      Get Time	epoch
    # Prevent outputs from previous commands leaking into the output files
    Drain Serial Output
    WHILE    True
        ${elapsed}     Evaluate    int(time.time()) - int(${start_time})
        IF    ${elapsed} > ${timeout}
            BREAK
        END
        ${end_line}    Evaluate    ${start_line} + ${batch_size} - 1
        ${chunk}    Run Keyword    ${read_chunk_keyword}    @{read_chunk_args}    ${start_line}    ${end_line}
        ${chunk}    Strip String    ${chunk}
        IF    $chunk == ''
            Log To Console    No more lines to copy from serial source after line ${start_line}.
            BREAK
        END
        OperatingSystem.Append To File    ${output_file}    ${chunk}${\n}
        ${chunk_line_count}               Evaluate    len($chunk.splitlines())
        ${copied_lines}                   Evaluate    ${copied_lines} + ${chunk_line_count}
        ${start_line}                     Evaluate    ${start_line} + ${batch_size}
        Log To Console                    Copied ${chunk_line_count} lines (${copied_lines} total) from serial source to ${output_file}
        ${break_limit}                    Evaluate    int(${batch_size} / 2)
        IF    ${chunk_line_count} < ${break_limit}
            BREAK
        END
    END

Read Serial File Chunk
    [Documentation]    Read a line range from a host-side file over the serial shell.
    [Arguments]    ${remote_file}    ${start_line}    ${end_line}
    ${chunk_command}    Set Variable    sed -n '${start_line},${end_line}p' ${remote_file}
    ${chunk}    Run Command On Serial    ${chunk_command}    timeout=30    pre_flush=${False}
    RETURN    ${chunk}

Read VM File Chunk
    [Documentation]    Read a line range from a VM-side file through the serial SSH tunnel.
    [Arguments]    ${vm}    ${remote_file}    ${start_line}    ${end_line}
    ${chunk_command}    Set Variable    sed -n '${start_line},${end_line}p' ${remote_file}
    ${chunk}    Run Command on VM Via Serial    ${vm}    ${chunk_command}    pre_flush=${False}    logging=${False}
    RETURN    ${chunk}

Normalize Serial Output
    [Documentation]    Remove terminal control related sequences. Keep only readable serial text.
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

        # Drop lines which are not considered as command output
        IF    $line == ''
            CONTINUE
        END
        ${is_host_prompt}    Run Keyword And Return Status
        ...    Should Match Regexp    ${line}    ^\\[ghaf@[^]]+\\]\\$$
        IF    ${is_host_prompt}
            CONTINUE
        END
        ${is_osc_prompt}    Run Keyword And Return Status
        ...    Should Match Regexp    ${line}    ^\\[]0;ghaf@[^:]+:.*$
        IF    ${is_osc_prompt}
            CONTINUE
        END
        ${is_password_prompt}    Run Keyword And Return Status
        ...    Should Match Regexp    ${line}    ^\\(ghaf@[^)]+\\) Password:( \\(ghaf@[^)]+\\) Password:)*\\s*$
        IF    ${is_password_prompt}
            CONTINUE
        END

        ${clean_output}    Catenate    SEPARATOR=\n    ${clean_output}    ${line}
    END
    ${clean_output}    Strip String    ${clean_output}
    RETURN    ${clean_output}
