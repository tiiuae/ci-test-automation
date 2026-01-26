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

Suite Setup          Rebuild Setup
Suite Teardown       Teardown Audit Update Logging

*** Variables ***
${repository_path}      /persist/ghaf
${setup_skipped}        ${False}


*** Test Cases ***

Check device-id persistence over nixos-rebuild
    [Documentation]         Verify that device-id has not changed over nixos-rebuild and reboot
    [Tags]                  SP-T351
    [Timeout]               1 minutes
    ${device_id_check}        Run Command            cat /persist/common/device-id
    IF  $device_id_check != '${device_id}'
        Set Suite Variable      ${device_id}   ${device_id_check}
        FAIL    Device ID has changed over nixos-rebuild and reboot
    END

Check net-vm hostname persistence over nixos-rebuild
    [Documentation]         Verify that net-vm hostname has not changed over nixos-rebuild and reboot
    [Tags]                  SP-T352
    [Timeout]               1 minutes
    IF  "${netvm_hostname_before}" != "${NETVM_NAME}"
        FAIL    Net-vm hostname has changed over nixos-rebuild and reboot
    END

Check audit update logging
    [Documentation]         Verify that interrupted nixos-rebuild (system update) is properly logged
    [Tags]                  SP-T276
    [Timeout]               10 minutes
    Switch to vm              ${HOST}
    Elevate to superuser
    Run Nix Shell             git
    Log To Console            Modifying modules/development/debug-tools.nix
    Edit file                 ${repository_path}/modules/development/debug-tools.nix  pkgs.file  pkgs.xdiskusage  ${False}
    ${before_rebuild}         Get current timestamp
    Log To Console            Starting nixos-rebuild and interrupting when copying started
    Run Nixos Rebuild         ${repository_path}  ${target_name}  copied
    ${after_rebuild}          Get current timestamp
    ${log_search_window}      DateTime.Subtract Date From Date   ${after_rebuild}  ${before_rebuild}   exclude_millis=True
    Sleep                     5
    ${any_logs_found}         Check VM Log on Grafana   ${device_id}  ${HOST}  ${log_search_window}s
    IF  not ${any_logs_found}
        Skip                  Known issue SSRCSP-7612 'Grafana logging stops from a VM' spoiled the test. Skipping.
    END
    ${found}  ${logs}         Get logs by key words   nixos_rebuild_store   ${log_search_window}s   ${False}
    Should Be True            ${found}
    Log                       ${logs}


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
        Skip                Test case not supporting this device type
    END
    Set Suite Variable        ${target_name}
    Switch to vm              ${NET_VM}
    Set Suite Variable        ${netvm_hostname_before}    ${NETVM_NAME}
    Switch to vm              ${HOST}
    ${device_id}              Run Command            cat /persist/common/device-id
    Set Suite Variable        ${device_id}
    ${gen_before}             Get current generation
    Set Suite Variable        ${gen_before}
    Elevate to superuser
    Run Nix Shell             git

    Clone Ghaf Repository     ${repository_path}    ${COMMIT_HASH}
    Log To Console            Making changes to the local ghaf repository
    Edit file                 ${repository_path}/modules/reference/profiles/mvp-user-trial.nix  security.audit.enable = false;  security.audit.enable = true;
    Edit file                 ${repository_path}/modules/common/security/audit/default.nix  ghaf.security.audit.enableOspp  ghaf.security.audit.enableVerboseRebuild = true;  ${False}
    Edit file                 ${repository_path}/modules/microvm/host/microvm-host.nix  storeWatcher.enable = false;  storeWatcher.enable = true;
    Log To Console            Switching to audit mode
    Run Nixos Rebuild         ${repository_path}  ${target_name}

    Switch to vm              ${HOST}
    ${state}  ${substate}     Verify service status  range=10  service=nixos-rebuild-watch.service

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
    Soft Reboot Device
    Verify shutdown via network
    Close All Connections
    Sleep                           20
    Connect After Reboot

Run Nix Shell
    [Arguments]      ${package}
    SSHLibrary.Read
    Set Client Configuration  timeout=60
    Write                     nix-shell -p ${package}
    SSHLibrary.Read Until     [nix-shell:

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

Teardown Audit Update Logging
    Set Client Configuration      timeout=10
    IF  ${setup_skipped} or '${PREV_TEST_STATUS}'=='FAIL'
        Reboot Laptop
        Close All Connections
        Connect After Reboot
    END
    Switch to vm    ${HOST}
    Remove Ghaf Repository
    Roll back to original generation
    Soft Reboot Device
    Verify shutdown via network
    Close All Connections
    Sleep                         20
    Connect After Reboot
    Close All Connections
