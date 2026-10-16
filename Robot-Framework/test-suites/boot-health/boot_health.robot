# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Validate boot-time records and boot diagnostics collected by relayboot.
Test Tags           boot-health

Library             ../../lib/PerformanceDataProcessing.py  ${DEVICE}  ${BUILD_ID}  ${COMMIT_HASH}  ${JOB}
...                 ${PERF_DATA_DIR}  ${CONFIG_PATH}  ${PLOT_DIR}  ${PERF_LOW_LIMIT}
Variables           ../../lib/performance_thresholds.py
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource

Suite Teardown      Close All Connections

*** Variables ***
${BOOT_TIME_DIR}    /persist/common
${MIN_SERIAL_LOG_LINES}    200

*** Test Cases ***

Verify boot time results
    [Tags]    pre-merge  bat  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  lab-only
    Check Boot Time And Plot    ${False}
    [Teardown]    Collect Boot Time Diagnostics

Verify boot time results and update baseline
    [Tags]    regression  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  lab-only
    Check Boot Time And Plot    ${True}
    [Teardown]    Collect Boot Time Diagnostics

Verify boot log health
    [Tags]    pre-merge  bat  regression  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx
    Check Boot Log Health

*** Keywords ***

Check Boot Time And Plot
    [Arguments]    ${save_history}
    Set Test Variable    ${BOOT_TIME_LIMIT_EXCEEDED}    ${False}
    Switch to vm    ${HOST}
    ${ping}    ${ping_rc}    ${boot_id_matches}=    Read Boot Ping Result
    Skip If    not ${boot_id_matches}    Saved boot time belongs to another boot; skipping timing evaluation.
    ${installer_target}    Evaluate    'installer' in $JOB.lower()
    ${target_type}    Set Variable If    ${IS_LAPTOP}    laptop    orin
    ${ping_ok}    ${ping_exceeded}    ${ping_issue}=    Validate Boot Time Value
    ...    response to ping    ${ping}    ${ping_rc}
    ...    ${static_thresholds}[boot_health][response_to_ping][${target_type}]
    ...    ${True}    ${installer_target}

    ${issues}    Create List
    Add Boot Time Issue    ${issues}    ${ping_issue}
    ${relative_limit}    Set Variable    ${thresholds}[boot_time][response_to_ping]
    ${absolute_limit}    Set Variable    ${static_thresholds}[boot_health][response_to_ping][${target_type}]
    ${statistics}    Plot Boot Time Results    ${ping}    ${ping_ok}    ${save_history}
    ...    ${relative_limit}    ${absolute_limit}
    Add Relative Boot Time Issue    ${issues}    ${statistics}
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
    ${valid}    Run Keyword And Return Status    Should Match Regexp    ${value}    ^[0-9]+$
    IF    not ${valid}
        RETURN    ${False}    ${False}    invalid ${name} value
    END
    ${exceeded}    Evaluate    float($value) > ${limit}
    IF    not ${exceeded}
        RETURN    ${True}    ${False}    ${EMPTY}
    END
    IF    ${installer_target}
        Log    Installer target exceeded ${name} limit: ${value}s    level=WARN
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

Add Relative Boot Time Issue
    [Arguments]    ${issues}    ${statistics}
    IF    not $statistics
        RETURN
    END
    ${result}    Get From Dictionary    ${statistics}    response_to_ping
    IF    ${result}[flag] > 0
        Append To List    ${issues}
        ...    response to ping ${result}[measurement]s exceeds the relative baseline margin.
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
        Fail    Boot log health failed: ${summary}
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
    ...    systemd-analyze critical-chain
    ...    systemctl --failed --no-legend --no-pager
    IF    ${IS_LAPTOP}
        FOR    ${command}    IN    @{diagnostic_commands}
            Run Keyword And Ignore Error    Run Command    ${command}    rc_match=skip    timeout=120
        END
    ELSE
        Run Keyword And Ignore Error    Run Diagnostic Commands Via Serial    ${HOST}    @{diagnostic_commands}
    END

Get Boot Log Reports
    IF    ${IS_LAPTOP}
        @{reports}    Get Journalctl And Dmesg Reports
        RETURN    @{reports}
    END
    ${saved_log}    Find Saved Serial Log    ${BOOT_DIAGNOSTICS_DIR}    ${BUILD_ID}
    ...    minimum_lines=${MIN_SERIAL_LOG_LINES}
    IF    '${saved_log}' != '${EMPTY}'
        ${report}    Get Saved Serial Log Report    ${saved_log}
        @{reports}    Create List    ${report}
        RETURN    @{reports}
    END
    Log    Saved serial logs not found or the logs are too few; using journalctl and dmesg logs.    level=WARN
    @{reports}    Get Journalctl And Dmesg Reports
    RETURN    @{reports}

Get Journalctl And Dmesg Reports
    ${journal}    ${journal_rc}=    Run Command    journalctl -b --no-pager -o short-iso
    ...    return=out rc    rc_match=skip    timeout=120
    ${dmesg}    ${dmesg_rc}=    Run Command    dmesg --color=never --time-format iso
    ...    return=out rc    rc_match=skip    sudo=True    timeout=120
    @{reports}    Create List
    IF    ${journal_rc} == 0
        ${report}    Analyze Boot Log    journalctl -b    ${journal}
        ...    gap_limit=${static_thresholds}[boot_health][serial_timestamp_gap]
        Append To List    ${reports}    ${report}
    ELSE
        Log    Could not read journalctl boot log.    level=WARN
    END
    IF    ${dmesg_rc} == 0
        ${report}    Analyze Boot Log    dmesg    ${dmesg}
        ...    gap_limit=${static_thresholds}[boot_health][serial_timestamp_gap]
        Append To List    ${reports}    ${report}
    ELSE
        Log    Could not read dmesg boot log.    level=WARN
    END
    RETURN    @{reports}

Get Saved Serial Log Report
    [Arguments]    ${saved_log}
    ${report}    Analyze Boot Log File    ${saved_log}
    ...          gap_limit=${static_thresholds}[boot_health][serial_timestamp_gap]
    RETURN    ${report}

Add Boot Log Issues
    [Arguments]    ${issues}    @{reports}
    FOR    ${report}    IN    @{reports}
        Log    Boot log health report: ${report}
        IF    ${report}[has_issues]
            Append To List    ${issues}    ${report}[file]: ${report}[summary]
        END
    END

Read Boot Ping Result
    ${ping}    ${ping_rc}=    Run Command    cat ${BOOT_TIME_DIR}/first_boot_to_ping
    ...                         return=out rc    rc_match=skip
    ${saved_boot_id}    ${saved_boot_id_rc}=    Run Command
    ...    cat ${BOOT_TIME_DIR}/first_boot_to_ping_boot_id    return=out rc    rc_match=skip
    ${current_boot_id}    ${current_boot_id_rc}=    Run Command
    ...    cat /proc/sys/kernel/random/boot_id    return=out rc    rc_match=skip
    ${boot_id_matches}    Evaluate
    ...    $saved_boot_id_rc == 0 and $current_boot_id_rc == 0 and $saved_boot_id.strip() == $current_boot_id.strip()
    IF    not ${boot_id_matches}
        Log    Saved boot time does not belong to the current boot.    level=WARN
        ${ping_rc}    Set Variable    1
    END
    RETURN    ${ping}    ${ping_rc}    ${boot_id_matches}
