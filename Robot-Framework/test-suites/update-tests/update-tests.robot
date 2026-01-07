# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for update tooling
Force Tags          regression  update  lenovo-x1  darter-pro

Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource

Test Teardown       Update teardown
Test Timeout        10 minutes


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


*** Keywords ***

Get current generation
    [Documentation]        Extract the number of current generation
    ${output}              Execute Command  nix-env -p /nix/var/nix/profiles/system --list-generations  sudo=True  sudo_password=${PASSWORD}
    ${current_line}        Get Lines Containing String  ${output}  (current)
    ${current_generation}  ${rest}  Split String   ${current_line}  max_split=1
    RETURN                 ${current_generation}

Update with
    [Arguments]           ${update_method}
    Switch to vm          ${HOST}
    # Get bootloader generations
    ${gen_before}         Get current generation
    Log                   Generation before update: ${gen_before}    console=True
    Set Suite Variable    ${gen_before}    ${gen_before}
    Log To Console        Updating...
    IF  "${DEVICE_TYPE}" == "lenovo-x1"
        ${release_name}   Set Variable  lenovo-x1-carbon-gen11-debug
    ELSE IF  "${DEVICE_TYPE}" == "darter-pro"
        ${release_name}   Set Variable  system76-darp11-b-debug
    ELSE
        Log               DEVICE_TYPE: ${DEVICE_TYPE} not allowed in update tests   console=True
    END
    IF  "${update_method}"=="ota-update"
        ${output}             Execute Command  ota-update cachix --cache ghaf-release ${release_name}  sudo=True  sudo_password=${PASSWORD}
        Should Not Contain    ${output}  Error
    ELSE IF  "${update_method}"=="givc-cli"
        Switch to vm          ${GUI_VM}
        ${output}             Execute Command  givc-cli update cachix --cache ghaf-release ${release_name}  sudo=True  sudo_password=${PASSWORD}
        Should Not Contain    ${output}  Error
        Switch to vm          ${HOST}
    ELSE
        FAIL   Incorrect update method
    END
    ${gen_after}          Get current generation
    Log                   Generation after update: ${gen_after}    console=True
    Set Suite Variable    ${gen_after}    ${gen_after}
    IF  ${gen_before}==${gen_after}
        FAIL    Update via ${update_method} failed OR attempted updating to already existing revision
    END

Update teardown
    IF   "${DEVICE_TYPE}" != "x1-sec-boot"
        ${gen_at_teardown}    Get current generation
        IF  ${gen_at_teardown}!=${gen_before}
            Log To Console    Rolling back to original generation and removing the new generation
            Execute Command   bootctl unlink nixos-generation-${gen_at_teardown}.conf  sudo=True  sudo_password=${PASSWORD}
            Execute Command   nix-env -p /nix/var/nix/profiles/system --switch-generation ${gen_before}  sudo=True  sudo_password=${PASSWORD}
            Execute Command   nix-env -p /nix/var/nix/profiles/system --delete-generations ${gen_at_teardown}  sudo=True  sudo_password=${PASSWORD}
        ELSE
            Log To Console    New generation not found. Skipping roll back.
        END
        Log To Console        Running garbage collect
        Execute Command       nix-collect-garbage  sudo=True  sudo_password=${PASSWORD}
        Close All Connections
    END
