# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Validate GIVC policy initialization and live policy update handling
Test Tags           givc-policy  security  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         GIVC policy suite setup


*** Variables ***
${POLICY_BACKUP_DIR}    /tmp


*** Test Cases ***

GIVC policy init on boot in policy-enabled VMs
    [Documentation]  Verify givc-policy-init exists and did not fail in VMs where policy client is enabled.
    [Template]       Verify givc policy init in ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END

GIVC policy update triggers handler in policy-enabled VMs
    [Documentation]  Modify an active policy file and verify its handler runs.
    [Template]       Verify givc policy update handler in ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END


*** Keywords ***

GIVC policy suite setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}

Verify givc policy init in ${vm}
    Switch to vm    ${vm}
    ${rc}    Run Command    systemctl is-enabled givc-policy-init    return=rc    rc_match=skip
    IF    ${rc}[0] != 0
        SKIP    givc-policy-init not enabled in ${vm}
    END
    ${result}    Run Command    systemctl show -p Result --value givc-policy-init    rc_match=skip
    ${state}     Run Command    systemctl show -p ActiveState --value givc-policy-init    rc_match=skip
    Should Not Contain    ${result}    failed
    Should Not Contain    ${state}     failed

Verify givc policy update handler in ${vm}
    Switch to vm    ${vm}
    ${service}    ${path_unit}    ${policy_path}    Get GIVC policy handler details
    IF    "${service}" == "${EMPTY}" or "${policy_path}" == "${EMPTY}"
        SKIP    No givc policy handler detected in ${vm}
    END

    ${backup}    Set Variable    ${POLICY_BACKUP_DIR}/givc_policy_backup_${vm}
    Run Command    cp ${policy_path} ${backup}    sudo=True

    ${before}    Run Command    systemctl show -p ExecMainExitTimestampUSec --value ${service}    rc_match=skip
    Run Command    sh -c "echo '# ci-test-automation policy update '$(date +%s)' ' | tee -a ${policy_path} >/dev/null"    sudo=True

    Wait Until Keyword Succeeds    6x    5s    Policy handler should run    ${service}    ${before}

    [Teardown]    Run Keywords
    ...    Restore policy file    ${policy_path}    ${backup}    AND
    ...    Run Command    rm -f ${backup}    sudo=True

Policy handler should run
    [Arguments]    ${service}    ${before}
    ${after}    Run Command    systemctl show -p ExecMainExitTimestampUSec --value ${service}    rc_match=skip
    ${before_is_empty}    Run Keyword And Return Status    Should Be True    '${before}' in ['','0','n/a','N/A']
    IF    ${before_is_empty}
        Should Not Be True    '${after}' in ['','0','n/a','N/A']
    ELSE
        Should Not Be Equal As Strings    ${after}    ${before}
    END

Get GIVC policy handler details
    ${services_out}    Run Command    systemctl list-units --type=service 'givc-policy-*' --no-legend --no-pager --all    rc_match=skip
    ${service}    Set Variable    ${EMPTY}
    ${path_unit}  Set Variable    ${EMPTY}
    ${policy_path}    Set Variable    ${EMPTY}

    @{lines}    Split To Lines    ${services_out}
    FOR    ${line}    IN    @{lines}
        ${line}    Strip String    ${line}
        IF    '${line}' == ''
            CONTINUE
        END
        ${tokens}    Split String    ${line}
        ${candidate_service}    Set Variable    ${tokens}[0]
        ${candidate_path}    Replace String    ${candidate_service}    .service    .path
        ${path_out}    Run Command    systemctl list-units --type=path ${candidate_path} --no-legend --no-pager --all    rc_match=skip
        ${path_status}    Run Keyword And Return Status    Should Contain    ${path_out}    ${candidate_path}
        IF    ${path_status}
            ${path_value}    Run Command    systemctl show -p PathModified --value ${candidate_path}    rc_match=skip
            IF    '${path_value}' != ''
                ${service}    Set Variable    ${candidate_service}
                ${path_unit}  Set Variable    ${candidate_path}
                ${policy_path}    Set Variable    ${path_value}
                EXIT FOR LOOP
            END
        END
    END

    RETURN    ${service}    ${path_unit}    ${policy_path}

Restore policy file
    [Arguments]    ${policy_path}    ${backup}
    Run Command    cp ${backup} ${policy_path}    sudo=True
