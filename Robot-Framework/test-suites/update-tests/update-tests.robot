# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Tests for update tooling
Force Tags          regression  update
Test Timeout        10 minutes

Resource            ../../resources/ssh_keywords.resource


*** Test Cases ***

Test ota update
    [Documentation]  Check that ota-update tooling works and new revision shows up in the bootloader list.
    ...              Do not try boot to the new revision. After test unlink the new revision.
    [Tags]           ota-update  SP-T147
    Update with      ota-update

Test ota update
    [Documentation]  Check that update succeeds via givc-cli and new revision shows up in the bootloader list.
    ...              Do not try boot to the new revision. After test unlink the new revision.
    [Tags]           givc-cli-update  SP-T148
    Update with      givc-cli


*** Keywords ***

Get generation count
    [Documentation]  Parse 'bootctl list' output to get the number of generations
    ${output}              Execute Command  bootctl list  sudo=True  sudo_password=${PASSWORD}
    ${ids} 	               Get Lines Containing String  ${output}  id: nixos-generation
    Should Not Be Empty    ${ids}
    ${generation_count}    Get Line Count   ${ids}
    RETURN                 ${generation_count}

Update with
    [Arguments]      ${update_method}
    Switch to vm          ${HOST}
    ${gen_count_before}   Get generation count
    IF  "${update_method}"=="ota-update"
        ${output}             Execute Command  ota-update cachix --cache ghaf-release lenovo-x1-carbon-gen11-debug  sudo=True  sudo_password=${PASSWORD}
        Should Not Contain    ${output}  Error
    ELSE IF  "${update_method}"=="givc-cli"
        Switch to vm          ${GUI_VM}
        ${output}             Execute Command  givc-cli update cachix --cache ghaf-release lenovo-x1-carbon-gen11-debug  sudo=True  sudo_password=${PASSWORD}
        Should Not Contain    ${output}  Error
        Switch to vm          ${HOST}
    ELSE
        FAIL   Incorrect update method
    END
    ${gen_count_after}   Get generation count
    IF  ${gen_count_before}==${gen_count_after}
        FAIL    Update via ${update_method} failed OR attempted updating to already existing revision
    ELSE
        Execute Command  bootctl unlink nixos-generation-${gen_count_after}.conf  sudo=True  sudo_password=${PASSWORD}
    END
