# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for update tooling
Test Tags           lenovo-x1  darter-pro

Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/setup_keywords.resource

Test Teardown       Update teardown
Test Timeout        10 minutes


*** Variables ***

${repository_path}      /persist/ghaf
${device_id_unchanged}  ${True}
${preparation_ok}       ${False}


*** Test Cases ***

Test ota update
    [Documentation]  Check that ota-update tooling works and new revision shows up in the bootloader list.
    ...              Do not try boot to the new revision. After test unlink the new revision.
    [Tags]           SP-T147  ota-update
    Run Keyword If   "${DEVICE_TYPE}" == "x1-sec-boot"   Skip   Updating is not supported by signed images.
    Update with      ota-update

Update via givc-cli
    [Documentation]  Check that update succeeds via givc-cli and new revision shows up in the bootloader list.
    ...              Do not try boot to the new revision. After test unlink the new revision.
    [Tags]           SP-T148  givc-cli-update
    Run Keyword If   "${DEVICE_TYPE}" == "x1-sec-boot"   Skip   Updating is not supported by signed images.
    Update with      givc-cli

Check audit update logging and device-id immutability
    [Documentation]         Enable audit logging and verify that system updates are properly logged
    ...                     Check also that device-id does not change over nixos-rebuild
    [Tags]                  SP-T276
    [Timeout]               60 minutes

    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        ${target_name}      Set Variable    lenovo-x1-carbon-gen11-debug
    ELSE IF  "${DEVICE_TYPE}" == "darter-pro"
        ${target_name}      Set Variable    system76-darp11-b-debug
    ELSE
        Skip                Test case not supporting this device type
    END

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
    ${device_id_check}        Run Command            cat /persist/common/device-id
    IF  $device_id_check != '${device_id}'
        Run Keyword And Continue On Failure    FAIL    Device ID has changed over nixos-rebuild boot
        Set Suite Variable      ${device_id_unchanged}    ${False}
        Log To Console          Device ID immutability check FAILED. Continuing still with audit logging test.
        Set Suite Variable      ${device_id}   ${device_id_check}
    END
    Elevate to superuser
    Run Nix Shell             git
    Log To Console            Modifying modules/development/debug-tools.nix
    Edit file                 ${repository_path}/modules/development/debug-tools.nix  pkgs.file  pkgs.git  ${False}
    ${before_rebuild}         Get current timestamp
    Log To Console            Starting nixos-rebuild and interrupting when copying started
    Run Nixos Rebuild         ${repository_path}  ${target_name}  copied
    ${after_rebuild}          Get current timestamp
    ${log_search_window}      DateTime.Subtract Date From Date   ${after_rebuild}  ${before_rebuild}   exclude_millis=True
    Sleep                     5
    Set Suite Variable        ${preparation_ok}  ${True}
    ${found}  ${logs}         Get logs by key words   nixos_rebuild_store   ${log_search_window}s   ${False}
    Should Be True            ${found}
    Log                       ${logs}

    [Teardown]                Teardown Audit Update Logging


*** Keywords ***

Get current generation
    [Documentation]        Extract the number of current generation
    ${output}              Run Command  nix-env -p /nix/var/nix/profiles/system --list-generations  sudo=True
    ${current_line}        Get Lines Containing String  ${output}  (current)
    ${current_generation}  ${rest}  Split String   ${current_line}  max_split=1
    RETURN                 ${current_generation}

Update with
    [Arguments]           ${update_method}
    Switch to vm          ${HOST}
    # Get bootloader generations
    ${gen_before}         Get current generation
    Log                   Generation before update: ${gen_before}    console=True
    Set Suite Variable    ${gen_before}
    Log To Console        Updating...
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        ${release_name}   Set Variable  lenovo-x1-carbon-gen11-debug
    ELSE IF  "${DEVICE_TYPE}" == "darter-pro"
        ${release_name}   Set Variable  system76-darp11-b-debug
    ELSE
        Log               DEVICE_TYPE: ${DEVICE_TYPE} not allowed in update tests   console=True
    END
    IF  "${update_method}"=="ota-update"
        ${output}             Run Command  ota-update cachix --cache ghaf-release ${release_name}  sudo=True   timeout=600
        Should Not Contain    ${output}  Error
    ELSE IF  "${update_method}"=="givc-cli"
        Switch to vm          ${GUI_VM}
        ${output}             Run Command  givc-cli update cachix --cache ghaf-release ${release_name}  sudo=True   timeout=600
        Should Not Contain    ${output}  Error
        Switch to vm          ${HOST}
    ELSE
        FAIL   Incorrect update method
    END
    ${gen_after}          Get current generation
    Log                   Generation after update: ${gen_after}    console=True
    Set Suite Variable    ${gen_after}
    IF  ${gen_before}==${gen_after}
        FAIL    Update via ${update_method} failed OR attempted updating to already existing revision
    END

Update Teardown
    IF   "${DEVICE_TYPE}" != "x1-sec-boot"
        ${gen_at_teardown}    Get current generation
        IF  ${gen_at_teardown}!=${gen_before}
            Log To Console    Rolling back to original generation and removing the new generation
            Run Command   bootctl unlink nixos-generation-${gen_at_teardown}.conf  sudo=True
            Run Command   nix-env -p /nix/var/nix/profiles/system --switch-generation ${gen_before}  sudo=True
            Run Command   nix-env -p /nix/var/nix/profiles/system --delete-generations ${gen_at_teardown}  sudo=True
        ELSE
            Log To Console    New generation not found. Skipping roll back.
        END
        Log To Console        Running garbage collect
        Run Command           nix-collect-garbage  sudo=True
        Close All Connections
    END

Run Nixos Rebuild
    [Arguments]      ${repository_path}  ${target_name}  ${interrupt}=${EMPTY}
    ${no_output_timeout}  Set Variable    240
    ${no_output_start}    Set Variable    ${EMPTY}
    Elevate to superuser
    Run Nix Shell    git
    Write            cd ${repository_path}
    Sleep            0.5
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
    Wait Until Device Is Down
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
    Run Keyword If Test Failed    Reboot Laptop
    Run Keyword If Test Failed    Close All Connections
    Run Keyword If Test Failed    Connect After Reboot
    Switch to vm    ${HOST}
    Remove Ghaf Repository
    Update Teardown
    Soft Reboot Device
    Wait Until Device Is Down
    Close All Connections
    Sleep                         20
    Connect After Reboot
    Close All Connections
    Run Keyword If Test Failed    Check Skip Conditions

Check Skip Conditions
    IF  ${device_id_unchanged} and not ${preparation_ok}
        Skip    Something went wrong in preparation stages of the test. Could not check nixos-rebuild logging.
    END
