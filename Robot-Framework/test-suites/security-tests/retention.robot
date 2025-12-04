# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Checking retenion policies
Force Tags          security   retention
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/setup_keywords.resource


*** Test Cases ***

Log retention policies
    [Documentation]   Check that retention policies are applied and enforced
    [Tags]            regression  SP-T329  lenovo-x1  darter-pro

    Switch to vm   ${HOST}
    Check journald configuration
    Check Disk Usage Under 500M
    Check Boot Entries    minimum=1
    Run Keyword And Continue On Failure
    ...    Verify service status   range=2   service=alloy  expected_state=active  expected_substate=running
    Check Loki Journal Directory Activity    /var/lib/alloy/data-alloy/loki.source.journal.journal  positions.yml

    Switch to vm   ${ADMIN_VM}
    Check journald configuration
    Check Loki Journal Directory Activity    /var/lib/alloy/data-alloy/loki.source.journal.journal


*** Keywords ***

Check Loki Journal Directory Activity
    [Documentation]     Looking for files in the given directory changed recently (period given in minutes).
    ...                 If file name is given, check it presents in the directory and also was changed in given period.
    [Arguments]         ${dir}    ${file}=None    ${period}=3
    ${output}  Execute Command    find ${dir} -maxdepth 1 -type f -mmin -${period}  sudo=True  sudo_password=${PASSWORD}
    Run Keyword And Continue On Failure   Should Not Be Empty   ${output}

    IF  $file != 'None'
        Run Keyword And Continue On Failure   Should Contain    ${output}   ${file}
    END

Check journald configuration
    ${output}           Execute command   cat /etc/systemd/journald.conf
    Run Keyword And Continue On Failure   Should Match Regexp    ${output}    MaxRetentionSec=\\d+
    Run Keyword And Continue On Failure   Should Match Regexp    ${output}    SystemMaxUse=\\d+M
    Run Keyword And Continue On Failure   Should Match Regexp    ${output}    SystemMaxFileSize=\\d+M
    Run Keyword And Continue On Failure   Should Contain         ${output}    Storage=persistent


Check Disk Usage Under 500M
    [Documentation]     Extracts value of disk usage by journals, converts it to megabytes
    ...                 and verifies that the total journal size is below 500M.
    ${output}      Execute command        journalctl --disk-usage
    ${match}       Get Regexp Matches     ${output}    (\\d+(?:\\.\\d+)?)\\s*([KMG]?)    1    2
    Run Keyword And Continue On Failure   Should Not Be Empty    ${match}   Couldn't find disk usage

    IF  ${match}
        ${value}   Set Variable    ${match[0][0]}
        ${unit}    Set Variable    ${match[0][1]}

        ${mb}      Run Keyword If   '${unit}'=='K'   Evaluate    float(${value})/1024
        ...               ELSE IF   '${unit}'=='G'   Evaluate    float(${value})*1024
        ...                  ELSE                    Evaluate    float(${value})

        Run Keyword And Continue On Failure   Should Be True   ${mb} < 500
    END

Check Boot Entries
    [Arguments]   ${minimum}=1
    ${count}      Get amount of boot entries
    Run Keyword And Continue On Failure   Should Be True    ${count} >= ${minimum}

Get amount of boot entries
    ${output}     Execute command   journalctl --list-boots

    @{lines}      Split To Lines    ${output}
    ${count}      Set Variable      0

    FOR    ${line}    IN    @{lines}
        ${is_boot}    Run Keyword And Return Status    Should Match Regexp    ${line}    ^\\s*[-0-9]+\\s+\\S+\\s+
        IF  ${is_boot}
            ${count}  Evaluate    ${count} + 1
        END
    END
    RETURN    ${count}
