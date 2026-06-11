# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for update tooling
Test Tags           rebuild

Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/update_keywords.resource
Resource            ../../resources/service_keywords.resource

Suite Setup          Rebuild Setup
Suite Teardown       Rebuild Teardown

*** Variables ***
${repository_path}      /persist/ghaf
${setup_skipped}        ${False}


*** Test Cases ***

Check device-id persistence over nixos-rebuild
    [Documentation]         Verify that device-id has not changed over nixos-rebuild and reboot
    [Tags]                  SP-T351
    [Timeout]               1 minutes
    ${device_id_check}      Get Actual Device ID
    IF  $device_id_check != '${device_id}'
        Set Suite Variable      ${device_id}   ${device_id_check}
        FAIL    Device ID has changed over nixos-rebuild and reboot
    END

Check net-vm hostname persistence over nixos-rebuild
    [Documentation]         Verify that net-vm hostname has not changed over nixos-rebuild and reboot
    [Tags]                  SP-T352  SP-352-2
    [Timeout]               1 minutes
    IF  "${netvm_hostname_before}" != "${NETVM_NAME}"
        FAIL    Net-vm hostname has changed over nixos-rebuild and reboot
    END

Check file system changes are logged
    [Documentation]         Create file and verify that the operation was logged
    [Tags]                  SP-T280
    [Setup]                 Prepare File Audit Test
    ${file_path}              Set Variable    /tmp/test_text_${BUILD_ID}.txt
    ${audit_start}            Get Audit Search Timestamp
    Create text file          test    ${file_path}
    ${file_owner}             Run Command    stat -c "%U" ${file_path}
    ${logs}                   Wait Until Keyword Succeeds    10s    1s
    ...                       Find Audit Logs   since=${audit_start}   file=${file_path}
    Run Keyword And Continue On Failure   Should Contain    ${logs}    nametype=CREATE
    Run Keyword And Continue On Failure   Should Contain    ${logs}    ouid=${file_owner}
    Run Keyword And Continue On Failure   Should Contain    ${logs}    key=successful-modification

Check that system logs privilege uses and key events
    [Documentation]         Execute check of ipset list and verify that the command was logged
    [Tags]                  SP-T281
    [Setup]                 Check That Logging Is Working in VM   ${NET_VM}   ${NETVM_NAME}
    Switch to vm              ${NET_VM}
    Run Command               ipset list   sudo=True
    Sleep                     3
    ${found}  ${logs}         Get logs by key words  ipset   15s   ${False}
    Should Be True            ${found}    No log entry for 'ipset' found in Grafana during the last 15 seconds
    Run Keyword And Continue On Failure   Should Contain    ${logs}    USER=root
    Run Keyword And Continue On Failure   Should Contain    ${logs}    ipset list

Check audit update logging
    [Documentation]         Verify that interrupted nixos-rebuild (system update) is properly logged
    [Tags]                  SP-T276
    [Setup]                 Prepare Rebuild Audit Test
    [Timeout]               10 minutes
    ${audit_start}            Get Audit Search Timestamp
    Log To Console            Starting nixos-rebuild and interrupting when copying started
    Run Nixos Rebuild         ${repository_path}  ${target_name}  copied
    Wait Until Keyword Succeeds    10s    1s
    ...                       Find Audit Logs   since=${audit_start}   key=nixos_rebuild_store


*** Keywords ***

Rebuild Setup
    ${setup_ok}    Run Keyword And Return Status    Enable audit logging and nix-store-watch
    IF  not ${setup_ok}
        Set Suite Variable    ${setup_skipped}    ${True}
        Skip                  Something went wrong in 'Enable audit logging and nix-store-watch'. Skipping the suite.
    END

Enable audit logging and nix-store-watch
    [Timeout]               50 minutes
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        ${target_name}      Set Variable    lenovo-x1-carbon-gen11-debug
    ELSE IF  "${DEVICE_TYPE}" == "darter-pro"
        ${target_name}      Set Variable    system76-darp11-b-debug
    ELSE
        FAIL                Test case does not support device type ${DEVICE_TYPE}
    END
    Set Suite Variable        ${target_name}
    Switch to vm              ${NET_VM}
    Set Suite Variable        ${netvm_hostname_before}    ${NETVM_NAME}
    Switch to vm              ${HOST}
    ${device_id}              Get Actual Device ID
    Set Suite Variable        ${device_id}
    ${gen_before}             Get current generation
    Set Suite Variable        ${gen_before}
    Elevate to superuser
    Run Nix Shell             git

    Clone Ghaf Repository     ${repository_path}    ${COMMIT_HASH}
    Log To Console            Making changes to the local ghaf repository
    Edit file                 ${repository_path}/modules/reference/profiles/mvp-user-trial.nix  security.audit.enable = false;  security.audit.enable = true;
    Edit file                 ${repository_path}/modules/common/security/audit/default.nix  ghaf.security.audit.enableOspp  ghaf.security.audit.enableVerboseRebuild = true;  ${False}
    Edit file                 ${repository_path}/modules/common/security/audit/default.nix  ghaf.security.audit.enableOspp  ghaf.security.audit.enableVerboseOspp = true;  ${False}
    Edit file                 ${repository_path}/modules/common/security/audit/default.nix  ghaf.security.audit.enableOspp = mkIf cfg.enableVerboseOspp true;  ghaf.security.audit.enableOspp = true;
    Edit file                 ${repository_path}/modules/microvm/host/microvm-host.nix  storeWatcher.enable = false;  storeWatcher.enable = true;
    Log To Console            Switching to audit mode
    Run Nixos Rebuild         ${repository_path}  ${target_name}

    Switch to vm              ${HOST}

Run Nixos Rebuild
    [Arguments]      ${repository_path}  ${target_name}  ${interrupt}=${EMPTY}
    ${no_output_timeout}  Set Variable    240
    ${no_output_start}    Set Variable    ${EMPTY}
    Elevate to superuser
    Run Nix Shell    git
    Write            cd ${repository_path}
    Sleep            0.5
    ${output}        SSHLibrary.Read
    Write            nixos-rebuild --flake .#${target_name} boot
    ${rebuild_ok}    Set Variable  ${False}
    FOR   ${i}  IN RANGE  300
        ${output}               SSHLibrary.Read
        IF  'exit status 1' in $output
            FAIL  error in nixos-rebuild
        END
        IF  ${i} > 0 and '[nix-shell:' in $output
            Log To Console      .
            Log To Console      nixos-rebuild finished
            ${rebuild_ok}    Set Variable  ${True}
            BREAK
        END
        # May have to answer "y" to multiple y/N questions
        IF  '(y/N)' in $output
            Write   y
            Sleep   0.5
        END
        IF  $output == '${EMPTY}'
            IF  $no_output_start == '${EMPTY}'
                ${no_output_start}      Get current timestamp
                Log To Console          No output
            ELSE
                ${current_time}         Get current timestamp
                ${no_output_time}       DateTime.Subtract Date From Date   ${current_time}  ${no_output_start}  exclude_millis=True
                IF  ${no_output_time} > ${no_output_timeout}
                    FAIL   nixos-rebuild was running without output ${no_output_timeout}s\nMight be stuck. Interrupting.
                END
            END
            # Ensure that the device is still alive
            Wait Until Keyword Succeeds  15s  3s  Ping Host  ${DEVICE_IP_ADDRESS}  allow_fail=${True}
            Sleep                   10
            Log To Console          .   no_newline=true
        ELSE
            ${no_output_start}      Set Variable    ${EMPTY}
            Log To Console          Output received
            Sleep                   10
        END
        IF  $interrupt != '${EMPTY}'
            IF  '${interrupt}' in $output
                Log To Console           Interrupting nixos-rebuild
                ${ctrl_c}                Evaluate    chr(int(3))
                SSHLibrary.Write Bare    ${ctrl_c}
                SSHLibrary.Read Until    [nix-shell:
                RETURN
            END
        END
    END
    IF  not ${rebuild_ok}
        FAIL  nixos-rebuild didn't finish successfully withing the given time
    END
    Soft Reboot Device And Connect
    Login to laptop

Clone Ghaf Repository
    [Arguments]               ${repository_path}    ${commit}=${EMPTY}
    Log To Console            Cloning ghaf repository
    SSHLibrary.Read
    Write                     git clone https://github.com/tiiuae/ghaf.git ${repository_path}
    SSHLibrary.Read Until     Cloning
    SSHLibrary.Read Until     [nix-shell:
    Sleep                     0.5
    Write                     cd ${repository_path}
    IF  $commit != '${EMPTY}' and $commit != 'NONE'
        Log                       Checking out commit ${commit}  console=True
        Write                     git checkout ${commit}
        SSHLibrary.Read Until     HEAD is now at
        SSHLibrary.Read Until     [nix-shell:
    END

Remove Ghaf Repository
    Run Command     rm -r ${repository_path}   sudo=True

Rebuild Teardown
    Set Client Configuration      timeout=10
    IF  ${setup_skipped} or '${PREV_TEST_STATUS}'=='FAIL'
        Reboot Laptop
        Close All Connections
        Connect After Reboot
        Login to laptop
    END
    Switch to vm    ${HOST}
    Remove Ghaf Repository
    Roll back to original generation
    Soft Reboot Device And Connect
    Login to laptop

Check That Logging Is Working in VM
    [Documentation]  Check that the test log is sent to Grafana
    [Arguments]      ${vm}   ${log_vm}=${vm}   ${since}=1m
    Switch to vm   ${vm}
    Run Command  logger --priority=user.info "Rebuild_test_log"
    ${id}   Get Actual Device ID
    ${status}  Run Keyword And Return Status  Wait Until Keyword Succeeds  15s  2s
    ...  Check VM Log on Grafana  ${id}  ${log_vm}  ${since}  ${True}  Rebuild_test_log
    IF  not ${status}
        FAIL    Log sent from ${vm} was not found in Grafana.\nCheck if log forwarding is broken.
    END

Prepare File Audit Test
    Switch to vm              ${HOST}
    Verify service status     range=60  service=microvm@${CHROME_VM}.service  expected_state=active  expected_substate=running
    Switch to vm              ${CHROME_VM}
    Verify Audit Rule Is Loaded    successful-modification

Prepare Rebuild Audit Test
    Switch to vm              ${HOST}
    Verify service status     range=10  service=nixos-rebuild-watch.service
    Verify Audit Rule Is Loaded    nixos_rebuild_store
    Prepare Rebuild Audit Event

Prepare Rebuild Audit Event
    [Documentation]  Add a harmless package to make nixos-rebuild copy store paths and emit audit logs.
    Elevate to superuser
    Log To Console   Adding package to trigger nixos-rebuild audit event
    Edit file        ${repository_path}/modules/development/debug-tools.nix  pkgs.file  pkgs.xdiskusage  ${False}

Get Audit Search Timestamp
    [Documentation]  Return timestamp in a format accepted by ausearch -ts.
    ${timestamp}     Run Command    date '+%m/%d/%Y %H:%M:%S'
    RETURN           ${timestamp}

Find Audit Logs
    [Documentation]  Find a matching local audit log entry by file or key since the given timestamp.
    ...              Pass either file or key; but if both are set, file is preferred.
    ...              Key searches use --just-one because rebuild audit logs can be large and the test only needs one matching event.
    [Arguments]      ${since}   ${key}=${EMPTY}   ${file}=${EMPTY}
    ${filter}        Set Variable If    $file    -f ${file}    -k ${key} --just-one
    ${expected}      Set Variable If    $file    ${file}    ${key}
    Should Not Be Empty    ${expected}  Provide either file or key to search audit logs.
    ${cmd}           Set Variable       ausearch -if /var/log/audit/audit.log -ts ${since} ${filter} -i
    ${logs}  ${err}  ${rc}    Run Command    ${cmd}    return=out,err,rc    sudo=True    rc_match=skip
    Should Be True   ${rc} in [0, 1]    ausearch failed with unexpected return code ${rc}:\n${err}
    Should Contain   ${logs}    ${expected}    No log entry for '${expected}' found in local audit logs.
    RETURN           ${logs}

Verify Audit Rule Is Loaded
    [Documentation]  Ensure audit is enabled and the expected rule is loaded on the current VM.
    [Arguments]      ${expected_rule}
    ${status}        Run Command    auditctl -s    sudo=True
    IF  'enabled 0' in $status
        Run Command    auditctl -e 1    sudo=True
        ${status}      Run Command    auditctl -s    sudo=True
    END
    Should Match Regexp    ${status}    (?m)^enabled\\s+[12]    Audit is not enabled:\n${status}
    ${rules}         Run Command    auditctl -l    sudo=True
    Should Contain   ${rules}    ${expected_rule}    Audit rule '${expected_rule}' is not loaded on the current VM.\nLoaded rules:\n${rules}
