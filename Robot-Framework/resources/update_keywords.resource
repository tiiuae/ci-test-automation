# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             String
Library             Collections
Resource            ../resources/common_keywords.resource


*** Keywords ***

Get current generation
    [Documentation]        Extract the number of current generation
    ${output}              Run Command  nix-env -p /nix/var/nix/profiles/system --list-generations  sudo=True
    ${current_line}        Get Lines Containing String  ${output}  (current)
    ${current_generation}  ${rest}  Split String   ${current_line}  max_split=1
    RETURN                 ${current_generation}

Roll back to original generation
    ${gen_at_teardown}    Get current generation
    IF  ${gen_at_teardown}!=${gen_before}
        Log To Console    Rolling back to original generation and removing the new generation
        ${new_boot_id}    Get Bootctl Generation Id    ${gen_at_teardown}
        Run Command       bootctl unlink ${new_boot_id}  sudo=True
        Run Command       nix-env -p /nix/var/nix/profiles/system --switch-generation ${gen_before}  sudo=True
        Run Command       nix-env -p /nix/var/nix/profiles/system --delete-generations ${gen_at_teardown}  sudo=True
    ELSE
        Log To Console    New generation not found. Skipping roll back.
    END
    Log To Console        Running garbage collect
    Run Command           nix-collect-garbage  sudo=True  timeout=180
    Close All Connections

Get Bootctl Generation Id
    [Documentation]    Return bootctl entry id for a NixOS generation from `bootctl list` output.
    [Arguments]        ${generation}
    ${bootctl_list}    Run Command    bootctl list    sudo=True
    @{lines}           Split To Lines    ${bootctl_list}
    ${entry_id}        Set Variable    ${EMPTY}
    FOR    ${line}    IN    @{lines}
        ${is_new_entry}    Run Keyword And Return Status    Should Match Regexp    ${line}    ^\\s*type:
        IF    ${is_new_entry}
            ${entry_id}    Set Variable    ${EMPTY}
        END
        @{id_match}         Get Regexp Matches    ${line}    ^\\s*id:\\s*(\\S+)    1
        ${id_found}         Get Length    ${id_match}
        IF    ${id_found} > 0
            ${entry_id}     Get From List    ${id_match}    0
        END
        ${generation_match}    Run Keyword And Return Status
        ...                 Should Match Regexp    ${line}    ^\\s*version:\\s*Generation ${generation}\\b
        IF    ${generation_match}
            Should Not Be Empty    ${entry_id}    Could not find bootctl id for generation ${generation}
            RETURN    ${entry_id}
        END
    END
    FAIL    Could not find bootctl entry for generation ${generation}
