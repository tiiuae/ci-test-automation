# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Validate GIVC policy initialization, delivery integrity and firewall apply wiring
Test Tags           givc-policy  security  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         GIVC policy suite setup


*** Variables ***
${POLICY_BACKUP_DIR}    /tmp


*** Test Cases ***

GIVC policy init on boot in policy-enabled VMs
    [Documentation]  Verify givc-policy-init completed without known errors and created policy files.
    [Template]       Verify givc policy init in ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END

Proxy-config policy delivery integrity
    [Documentation]  Verify proxy-config is present in policy store and active destination with matching content.
    [Template]       Verify proxy-config policy delivery integrity in ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END

Firewall-rules policy delivery and apply trigger
    [Documentation]  Verify firewall-rules content matches store and current apply units react to file changes.
    [Template]       Verify firewall policy apply flow in ${vm}
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${vm}
    END


*** Keywords ***

GIVC policy suite setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    Set Suite Variable      @{VM_LIST_WITH_HOST}

Get current VM policy config
    ${config_raw}    Run Command    cat /etc/givc-agent/config.json
    ${config}    Evaluate    json.loads($config_raw)    json
    ${policy_cfg}    Evaluate    $config["capabilities"]["policy"]
    RETURN    ${policy_cfg}

Current VM should have policy client enabled
    ${policy_cfg}    Get current VM policy config
    ${enabled}    Evaluate    bool($policy_cfg.get("enable"))
    IF    not ${enabled}
        SKIP    Policy client not enabled in current VM
    END
    RETURN    ${policy_cfg}

Get configured policy destination
    [Arguments]    ${policy_cfg}    ${policy_name}
    ${policies}    Evaluate    $policy_cfg.get("policies", {})
    ${has_policy}    Evaluate    $policy_name in $policies
    IF    not ${has_policy}
        SKIP    Policy ${policy_name} not configured in current VM
    END
    ${destination}    Evaluate    $policies[$policy_name]
    RETURN    ${destination}

Get stored policy path
    [Arguments]    ${policy_cfg}    ${policy_name}
    ${store_path}    Evaluate    $policy_cfg["storePath"]
    RETURN    ${store_path}/${policy_name}/policy.bin

Stored policy file should match destination
    [Arguments]    ${stored_path}    ${destination}
    Run Command    test -f ${stored_path}
    Run Command    test -f ${destination}
    Run Command    cmp -s ${stored_path} ${destination}

Service should not be failed
    [Arguments]    ${service}
    ${result}    Run Command    systemctl show -p Result --value ${service}    rc_match=skip
    ${state}    Run Command    systemctl show -p ActiveState --value ${service}    rc_match=skip
    Should Not Contain    ${result}    failed
    Should Not Contain    ${state}    failed

Path unit should watch file
    [Arguments]    ${path_unit}    ${destination}
    ${watched_path}    Run Command    systemctl show -p PathModified --value ${path_unit}    rc_match=skip
    Should Be Equal As Strings    ${watched_path}    ${destination}

Policy handler should run
    [Arguments]    ${service}    ${before}
    ${after}    Run Command    systemctl show -p ExecMainExitTimestampUSec --value ${service}    rc_match=skip
    ${before_is_empty}    Run Keyword And Return Status    Should Be True    '${before}' in ['','0','n/a','N/A']
    IF    ${before_is_empty}
        Should Not Be True    '${after}' in ['','0','n/a','N/A']
    ELSE
        Should Not Be Equal As Strings    ${after}    ${before}
    END

Restore policy file
    [Arguments]    ${policy_path}    ${backup}
    Run Command    cp ${backup} ${policy_path}    sudo=True

Verify givc policy init in ${vm}
    Switch to vm    ${vm}
    ${policy_cfg}    Current VM should have policy client enabled

    ${rc}    Run Command    systemctl is-enabled givc-policy-init    return=rc    rc_match=skip
    IF    ${rc}[0] != 0
        FAIL    givc-policy-init is not enabled in ${vm}
    END

    Service should not be failed    givc-policy-init
    ${journal}    Run Command    journalctl -u givc-policy-init -b --no-pager    rc_match=skip
    Should Not Contain    ${journal}    Error! file not found

    ${policy_names}    Evaluate    list($policy_cfg.get("policies", {}).keys())
    Should Not Be Empty    ${policy_names}
    FOR    ${policy_name}    IN    @{policy_names}
        ${destination}    Get configured policy destination    ${policy_cfg}    ${policy_name}
        Run Command    test -f ${destination}
        ${stored_path}    Get stored policy path    ${policy_cfg}    ${policy_name}
        ${stored_rc}    Run Command    test -f ${stored_path}    return=rc    rc_match=skip
        IF    ${stored_rc}[0] == 0
            Stored policy file should match destination    ${stored_path}    ${destination}
        END
    END

Verify proxy-config policy delivery integrity in ${vm}
    Switch to vm    ${vm}
    ${policy_cfg}    Current VM should have policy client enabled
    ${destination}    Get configured policy destination    ${policy_cfg}    proxy-config
    ${stored_path}    Get stored policy path    ${policy_cfg}    proxy-config
    Stored policy file should match destination    ${stored_path}    ${destination}

Verify firewall policy apply flow in ${vm}
    Switch to vm    ${vm}
    ${policy_cfg}    Current VM should have policy client enabled
    ${destination}    Get configured policy destination    ${policy_cfg}    firewall-rules
    ${stored_path}    Get stored policy path    ${policy_cfg}    firewall-rules
    Stored policy file should match destination    ${stored_path}    ${destination}

    ${path_rc}    Run Command    systemctl is-enabled apply-dynamic-firewall-rules.path    return=rc    rc_match=skip
    IF    ${path_rc}[0] != 0
        FAIL    apply-dynamic-firewall-rules.path is not enabled in ${vm}
    END

    Path unit should watch file    apply-dynamic-firewall-rules.path    ${destination}
    Service should not be failed    apply-dynamic-firewall-rules.service

    ${backup}    Set Variable    ${POLICY_BACKUP_DIR}/givc_firewall_rules_backup_${vm}
    Run Command    cp ${destination} ${backup}    sudo=True
    ${before}    Run Command    systemctl show -p ExecMainExitTimestampUSec --value apply-dynamic-firewall-rules.service    rc_match=skip
    Run Command    sh -c "echo '# ci-test-automation firewall policy check '$(date +%s) >> ${destination}"    sudo=True
    Wait Until Keyword Succeeds    6x    5s    Policy handler should run    apply-dynamic-firewall-rules.service    ${before}
    Service should not be failed    apply-dynamic-firewall-rules.service

    [Teardown]    Run Keywords
    ...    Restore policy file    ${destination}    ${backup}    AND
    ...    Run Command    rm -f ${backup}    sudo=True
