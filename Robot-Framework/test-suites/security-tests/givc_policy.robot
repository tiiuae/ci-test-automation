# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Validate GIVC policy initialization, delivery integrity and firewall apply wiring
Test Tags           givc-policy  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         GIVC policy suite setup


*** Variables ***

${POLICY_BACKUP_DIR}    /tmp


*** Test Cases ***

GIVC policy init on boot in policy-enabled VMs
    [Documentation]  Verify givc-policy-init completed without known errors and created policy files.
    [Tags]           SP-T365
    FOR    ${vm}    IN    @{POLICY_CLIENT_VMS}
        Verify givc policy init in ${vm}
    END

*** Keywords ***

GIVC policy suite setup
    @{VM_LIST_WITH_HOST}    Get VM list    with_host=True
    @{POLICY_CLIENT_VMS}    Create List
    FOR    ${vm}    IN    @{VM_LIST_WITH_HOST}
        ${status}    ${message}    Run Keyword And Ignore Error    Switch to vm    ${vm}
        IF    '${status}' != 'PASS'
            Log To Console    Excluding inaccessible VM from GIVC tests: ${vm}
            CONTINUE
        END
        ${status}    ${config_raw}    Run Keyword And Ignore Error    Run Command    cat /etc/givc-agent/config.json
        IF    '${status}' != 'PASS'
            Log To Console    Excluding VM without readable GIVC config from GIVC tests: ${vm}
            CONTINUE
        END
        ${policy_cfg}    Evaluate    json.loads($config_raw).get("capabilities", {}).get("policy", {})    json
        ${enabled}    Evaluate    bool($policy_cfg.get("enable"))
        IF    not ${enabled}
            CONTINUE
        END
        Append To List    ${POLICY_CLIENT_VMS}    ${vm}
    END
    List Should Contain Value    ${POLICY_CLIENT_VMS}    ${BUSINESS_VM}
    List Should Contain Value    ${POLICY_CLIENT_VMS}    ${CHROME_VM}
    Set Suite Variable      @{VM_LIST_WITH_HOST}
    Set Suite Variable      @{POLICY_CLIENT_VMS}

Get current VM policy config
    ${config_raw}    Run Command    cat /etc/givc-agent/config.json
    ${config}    Evaluate    json.loads($config_raw)    json
    ${policy_cfg}    Evaluate    $config["capabilities"]["policy"]
    RETURN    ${policy_cfg}

Get configured policy destination
    [Arguments]    ${policy_cfg}    ${policy_name}
    ${policies}    Evaluate    $policy_cfg.get("policies", {})
    ${has_policy}    Evaluate    $policy_name in $policies
    IF    not ${has_policy}
        FAIL    Policy ${policy_name} not configured in current VM
    END
    ${destination}    Evaluate    $policies[$policy_name]
    RETURN    ${destination}

Get stored policy path
    [Arguments]    ${policy_cfg}    ${policy_name}
    ${store_path}    Evaluate    $policy_cfg["storePath"]
    RETURN    ${store_path}/${policy_name}/policy.bin

Verify givc policy init in ${vm}
    Switch to vm    ${vm}
    ${policy_cfg}    Get current VM policy config

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
        # Check stored_path == destination only if stored_path exists.
        ${stored_rc}    Run Command    test -f ${stored_path}    return=rc    rc_match=skip
        IF    ${stored_rc}[0] == 0
            Stored policy file should match destination    ${stored_path}    ${destination}
        END
    END

Stored policy file should match destination
    [Arguments]    ${stored_path}    ${destination}
    Run Command    test -f ${stored_path}
    Run Command    test -f ${destination}
    Run Command    cmp -s ${stored_path} ${destination}
