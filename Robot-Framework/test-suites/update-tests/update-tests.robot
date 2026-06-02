# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for update tooling
Test Tags           cachix-update  regression
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/update_keywords.resource

Test Teardown       Roll back to original generation
Test Timeout        15 minutes


*** Test Cases ***

Test ota update
    [Documentation]  Check that ota-update tooling works and new revision shows up in the bootloader list.
    ...              Do not try boot to the new revision. After test unlink the new revision.
    [Tags]           SP-T147  ota-update
    Update with      ota-update

Update via givc-cli
    [Documentation]  Check that update succeeds via givc-cli and new revision shows up in the bootloader list.
    ...              Do not try boot to the new revision. After test unlink the new revision.
    [Tags]           SP-T148  givc-cli-update
    Update with      givc-cli


*** Keywords ***

Update with
    [Arguments]           ${update_method}
    ${release_name}       Set Variable    intel-laptop-debug
    Switch to vm          ${HOST}
    Compare current with cachix revision    ${release_name}
    # Get bootloader generations
    ${gen_before}         Get current generation
    Log                   Generation before update: ${gen_before}    console=True
    Set Suite Variable    ${gen_before}
    Log To Console        Updating...
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

Compare current with cachix revision
    [Documentation]  Make sure that pinned cachix revision differs from current running ghaf version.
    [Arguments]      ${release_name}
    ${current_rev}  Run Command  readlink -f /run/current-system
    ${cachix_rev}   Run Command  nix-shell -p jq --run "curl -sL https://cachix.org/api/v1/cache/ghaf-release/pin | jq -r '.[] | select(.name==\\"${release_name}\\") | .lastRevision.storePath'"
    IF  $current_rev == $cachix_rev
        SKIP    Identical ghaf revision pinned in cachix. Nothing to update.
    END
