# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Validate boot-time records and boot diagnostics collected by relayboot.

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/performance_data_processing.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Variables           ../../lib/performance_thresholds.py

Suite Teardown      Close All Connections


*** Variables ***
${BOOT_TIME_DIR}    /persist/common
${MIN_SERIAL_LOG_LINES}    200


*** Test Cases ***
Verify boot time results
    [Tags]    SP-T516  pre-merge  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  lab-only
    Check Boot Time And Plot    ${False}
    [Teardown]    Collect Boot Time Diagnostics

Verify boot time results and update baseline
    [Tags]    SP-T517  regression  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  lab-only
    Check Boot Time And Plot    ${True}
    [Teardown]    Collect Boot Time Diagnostics

Verify boot log health
    [Tags]    SP-T518  pre-merge  regression  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx
    Check Boot Log Health


*** Keywords ***
Check Boot Time And Plot
    [Arguments]    ${save_history}
    Set Test Variable    ${BOOT_TIME_LIMIT_EXCEEDED}    ${False}
    Switch to vm    ${HOST}
    ${ping}    ${ping_rc}    ${boot_id_matches}     Read Boot Ping Result
    Skip If    not ${boot_id_matches}    Saved boot time belongs to another boot; skipping timing evaluation.
    ${installer_target}    Evaluate    'installer' in $JOB.lower()
    ${target_type}    Set Variable    ${DEVICE_TYPE}
    ${ping_ok}    ${ping_exceeded}    ${ping_issue}     Validate Boot Time Value
    ...    response to ping    ${ping}    ${ping_rc}
    ...    ${static_thresholds}[boot_health][response_to_ping][${target_type}]
    ...    ${True}    ${installer_target}

    ${issues}    Create List
    Add Boot Time Issue    ${issues}    ${ping_issue}
    ${relative_limit}    Set Variable    ${thresholds}[boot_time][response_to_ping]
    ${absolute_limit}    Set Variable    ${static_thresholds}[boot_health][response_to_ping][${target_type}]
    ${statistics}    Plot Boot Time Results    ${ping}    ${ping_ok}    ${save_history}
    ...    ${relative_limit}    ${absolute_limit}
    Log Relative Boot Time Deviation    ${statistics}
    ${relative_exceeded}    Evaluate
    ...    bool($statistics) and $statistics.get('response_to_ping', {}).get('flag', 0) > 0
    ${limit_exceeded}    Evaluate    $ping_exceeded or $relative_exceeded
    Set Test Variable    ${BOOT_TIME_LIMIT_EXCEEDED}    ${limit_exceeded}

    IF    $issues
        ${summary}    Catenate    SEPARATOR=\n    @{issues}
        Fail    Boot health failed: ${summary}
    END

Validate Boot Time Value
    [Arguments]    ${name}    ${value}    ${return_code}    ${limit}    ${required}    ${installer_target}
    IF    not ${required}
        RETURN    ${False}    ${False}    ${EMPTY}
    END
    IF    ${return_code} != 0
        RETURN    ${False}    ${False}    missing ${name}
    END
    ${valid}    Run Keyword And Return Status
    ...    Should Match Regexp    ${value}    ^[0-9]+(?:\.[0-9]+)?$
    IF    not ${valid}
        RETURN    ${False}    ${False}    invalid ${name} value
    END
    ${exceeded}    Evaluate    float($value) > ${limit}
    IF    not ${exceeded}
        RETURN    ${True}    ${False}    ${EMPTY}
    END
    IF    ${installer_target}
        Log    Installer target exceeded ${name} limit: ${value}s. This is expected on first boot.    console=True
        RETURN    ${True}    ${True}    ${EMPTY}
    END
    RETURN    ${True}    ${True}    ${name} ${value}s exceeds ${limit}s

Add Boot Time Issue
    [Arguments]    ${issues}    ${issue}
    IF    '${issue}' != '${EMPTY}'
        Append To List    ${issues}    ${issue}
    END

Plot Boot Time Results
    [Arguments]    ${ping}    ${ping_ok}    ${save_history}    ${relative_limit}    ${absolute_limit}
    ${statistics}    Create Dictionary
    IF    ${ping_ok}
        &{boot_results}    Create Dictionary
        Set To Dictionary    ${boot_results}    response_to_ping=${ping}
        ${plot_name}    Set Variable If    ${IS_ORIN}    Boot Health Orin    Boot Health Laptop
        IF    ${save_history}
            ${statistics}    Save Boot Time Data And Plot    ${plot_name}    ${boot_results}
            ...    absolute_limit=${absolute_limit}
        ELSE
            ${statistics}    Plot Boot Time Data Without Saving    ${plot_name}    ${boot_results}
            ...    ${relative_limit}    ${absolute_limit}
        END
    END
    RETURN    ${statistics}

Log Relative Boot Time Deviation
    [Arguments]    ${statistics}
    IF    not $statistics
        RETURN
    END
    ${result}    Get From Dictionary    ${statistics}    response_to_ping
    IF    ${result}[flag] > 0
        Log    Response to ping ${result}[measurement]s exceeds the relative baseline margin.
        ...    level=WARN
    ELSE IF    ${result}[flag] < 0
        Log    Response to ping improved relative to baseline: ${result}    console=True
    END

Check Boot Log Health
    Switch to vm    ${HOST}
    ${issues}    Create List
    @{reports}    Get Boot Log Reports
    Add Boot Log Issues    ${issues}    @{reports}

    IF    $issues
        ${summary}    Catenate    SEPARATOR=\n    @{issues}
        Log Error     Boot health    Potential issues detected in boot logs
        Log           Potential issues detected in boot logs: ${summary}    level=WARN
        # For now not allowing the test to fail on potential issues
        # TODO: Decide if this can be allowed to fail, review critical_pattern
        # FAIL    Boot log health failed: ${summary}
    END

Collect Boot Time Diagnostics
    IF    ${BOOT_TIME_LIMIT_EXCEEDED}
        Collect Boot Diagnostics
    END

Collect Boot Diagnostics
    @{diagnostic_commands}    Create List
    ...    uname -r
    ...    uptime
    ...    systemd-analyze --no-pager
    ...    systemd-analyze blame --no-pager
    ...    systemd-analyze critical-chain --no-pager
    ...    systemctl --failed --no-legend --no-pager
    IF    ${IS_LAPTOP}
        FOR    ${command}    IN    @{diagnostic_commands}
            Run Keyword And Ignore Error    Run Command    ${command}    rc_match=skip    timeout=120
        END
    ELSE
        Run Keyword And Ignore Error    Run Diagnostic Commands Via Serial    ${HOST}    @{diagnostic_commands}
    END

Get Boot Log Reports
    [Documentation]    On laptops: Collects journalctl and dmesg
    ...                On Orins:   Collects journalctl and serial logs, or dmesg when serial output is insufficient
    ...                Analyses the collected logs and creates reports
    ${timestamp_boundary}    Read Boot Ping Timestamp
    IF    not $timestamp_boundary
        Log    Ping timestamp is unavailable for this boot; timestamp-gap checks are skipped.
        ...    level=WARN
    END
    IF    ${IS_LAPTOP}
        @{reports}    Get Journalctl And Optional Dmesg Reports    ${timestamp_boundary}
        RETURN    @{reports}
    END
    ${saved_log}    Find Saved Serial Log    ${BOOT_DIAGNOSTICS_DIR}    ${BUILD_ID}
    ...    minimum_lines=${MIN_SERIAL_LOG_LINES}
    IF    '${saved_log}' != '${EMPTY}'
        @{reports}    Get Journalctl And Optional Dmesg Reports
        ...    ${timestamp_boundary}    include_dmesg=${False}
        ${report}    Get Saved Serial Log Report    ${saved_log}    ${timestamp_boundary}
        Append To List    ${reports}    ${report}
    ELSE
        Log    Saved serial logs not found or the logs are too few; using journalctl and dmesg logs.    level=WARN
        @{reports}    Get Journalctl And Optional Dmesg Reports    ${timestamp_boundary}
    END
    RETURN    @{reports}

Get Journalctl And Optional Dmesg Reports
    [Arguments]    ${timestamp_boundary}=${EMPTY}    ${include_dmesg}=${True}
    Create Directory    ${BOOT_DIAGNOSTICS_DIR}
    ${journal_remote}    Set Variable    /tmp/${BUILD_ID}-boot-health-journalctl.log
    ${journal_local}    Set Variable    ${BOOT_DIAGNOSTICS_DIR}/.journalctl-capture.tmp
    ${journal_output}    ${journal_rc}     Run Command
    ...    journalctl -b --no-pager -o short-iso > ${journal_remote}
    ...    return=out,rc    rc_match=skip    timeout=120
    @{reports}    Create List
    IF    ${journal_rc} == 0
        SSHLibrary.Get File    ${journal_remote}    ${journal_local}
        Run Command    rm -f ${journal_remote}    return=rc    rc_match=skip
        ${report}    Analyze Boot Log File    ${journal_local}    gap_limit=${None}
        ...    source=journalctl -b
        Append To List    ${reports}    ${report}
    ELSE
        Run Command    rm -f ${journal_remote}    return=rc    rc_match=skip
        Log    Could not read journalctl boot log.    level=WARN
    END
    IF    ${include_dmesg}
        ${dmesg_remote}    Set Variable    /tmp/${BUILD_ID}-boot-health-dmesg.log
        ${dmesg_local}    Set Variable    ${BOOT_DIAGNOSTICS_DIR}/.dmesg-capture.tmp
        ${dmesg_output}    ${dmesg_rc}     Run Command
        ...    dmesg --color=never --time-format iso > ${dmesg_remote}
        ...    return=out,rc    rc_match=skip    sudo=True    timeout=120
        IF    ${dmesg_rc} == 0
            SSHLibrary.Get File    ${dmesg_remote}    ${dmesg_local}
            Run Command    rm -f ${dmesg_remote}    return=rc    rc_match=skip
            ${gap_limit}    Set Variable    ${static_thresholds}[boot_health][serial_timestamp_gap]
            IF    not $timestamp_boundary
                ${gap_limit}    Set Variable    ${None}
            END
            ${report}    Analyze Boot Log File    ${dmesg_local}
            ...    gap_limit=${gap_limit}    source=dmesg    timestamp_boundary=${timestamp_boundary}
            Append To List    ${reports}    ${report}
        ELSE
            Run Command    rm -f ${dmesg_remote}    return=rc    rc_match=skip
            Log    Could not read dmesg boot log.    level=WARN
        END
    END
    RETURN    @{reports}

Get Saved Serial Log Report
    [Arguments]    ${saved_log}    ${timestamp_boundary}=${EMPTY}
    ${gap_limit}    Set Variable    ${static_thresholds}[boot_health][serial_timestamp_gap]
    IF    not $timestamp_boundary
        ${gap_limit}    Set Variable    ${None}
    END
    ${report}    Analyze Boot Log File    ${saved_log}
    ...          gap_limit=${gap_limit}    timestamp_boundary=${timestamp_boundary}
    RETURN    ${report}

Add Boot Log Issues
    [Arguments]    ${issues}    @{reports}
    FOR    ${report}    IN    @{reports}
        IF    ${report}[has_low_priority_issues]
            ${low_priority_report}    Save Boot Log Issue Report
            ...    ${report}    ${BOOT_DIAGNOSTICS_DIR}    ${BUILD_ID}    low_priority
            ${low_priority_message}    Catenate    SEPARATOR=${SPACE}
            ...    Low-priority boot log findings ${report}[file]: ${report}[low_priority_summary].
            ...    Details: ${low_priority_report}
            Log    ${low_priority_message}
        END
        IF    ${report}[has_critical_issues]
            ${critical_report}    Save Boot Log Issue Report
            ...    ${report}    ${BOOT_DIAGNOSTICS_DIR}    ${BUILD_ID}    critical
            ${critical_message}    Catenate    SEPARATOR=${SPACE}
            ...    Critical boot log issues ${report}[file]: ${report}[critical_summary].
            ...    Details: ${critical_report}
            Log    ${critical_message}
            ${full_log_file}    Save Full Boot Log    ${report}[file]    ${BOOT_DIAGNOSTICS_DIR}    ${BUILD_ID}
            IF    '${full_log_file}' != '${EMPTY}'
                Log    Full boot log saved: ${full_log_file}
            END
            Append To List    ${issues}
            ...    ${report}[file]: ${report}[critical_summary] (${critical_report})
        END
        IF    '${report}[capture_path]' != '${EMPTY}'
            OperatingSystem.Remove File    ${report}[capture_path]
        END
    END

Read Boot Ping Result
    ${ping}    ${ping_rc}     Run Command    cat ${BOOT_TIME_DIR}/first_boot_to_ping
    ...                         return=out rc    rc_match=skip
    ${saved_boot_id}    ${saved_boot_id_rc}     Run Command
    ...    cat ${BOOT_TIME_DIR}/first_boot_to_ping_boot_id    return=out rc    rc_match=skip
    ${current_boot_id}    ${current_boot_id_rc}     Run Command
    ...    cat /proc/sys/kernel/random/boot_id    return=out rc    rc_match=skip
    ${boot_id_matches}    Evaluate
    ...    $saved_boot_id_rc == 0 and $current_boot_id_rc == 0 and $saved_boot_id.strip() == $current_boot_id.strip()
    IF    not ${boot_id_matches}
        Log    Saved boot time does not belong to the current boot.    level=WARN
        ${ping_rc}    Set Variable    1
    END
    RETURN    ${ping}    ${ping_rc}    ${boot_id_matches}

Read Boot Ping Timestamp
    ${timestamp}    ${timestamp_rc}     Run Command
    ...    cat ${BOOT_TIME_DIR}/first_boot_to_ping_timestamp    return=out,rc    rc_match=skip
    ${saved_boot_id}    ${saved_boot_id_rc}     Run Command
    ...    cat ${BOOT_TIME_DIR}/first_boot_to_ping_boot_id    return=out,rc_match=skip
    ${current_boot_id}    ${current_boot_id_rc}     Run Command
    ...    cat /proc/sys/kernel/random/boot_id    return=out,rc_match=skip
    ${boot_id_matches}    Evaluate
    ...    $saved_boot_id_rc == 0 and $current_boot_id_rc == 0 and $saved_boot_id.strip() == $current_boot_id.strip()
    IF    ${timestamp_rc} != 0 or not ${boot_id_matches}
        RETURN    ${EMPTY}
    END
    ${timestamp}    Strip String    ${timestamp}
    RETURN    ${timestamp}
