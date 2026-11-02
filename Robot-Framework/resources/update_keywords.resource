# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Library             Collections
Library             String
Resource            ../resources/common_keywords.resource


*** Variables ***
${REPOSITORY_PATH}      /persist/ghaf


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
        IF  $new_boot_id
            Run Command       bootctl unlink ${new_boot_id}  sudo=True
        END
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

Run Nixos Rebuild
    [Arguments]      ${target_name}  ${repo_path}=${REPOSITORY_PATH}  ${interrupt}=${EMPTY}
    ${no_output_timeout}  Set Variable    240
    ${no_output_start}    Set Variable    ${EMPTY}
    Elevate to superuser
    Run Nix Shell    git
    Write            cd ${repo_path}
    Sleep            0.5
    ${output}        SSHLibrary.Read
    Log To Console   Starting nixos-rebuild and monitoring build output
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
            Wait Until Keyword Succeeds  15s  3s  Verify Ping Host  ${DEVICE_IP_ADDRESS}  expected_status=${True}
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

Clone Ghaf Repository
    [Arguments]               ${repo_path}=${REPOSITORY_PATH}    ${commit}=${EMPTY}
    Log To Console            Cloning ghaf repository
    # In case repository already exists (from earlier test runs) remove it
    Run Keyword And Ignore Error    Remove Ghaf Repository
    SSHLibrary.Read
    Write                     git clone https://github.com/tiiuae/ghaf.git ${repo_path}
    SSHLibrary.Read Until     Cloning
    Wait Until Keyword Succeeds    120s    1s    SSHLibrary.Read Until     [nix-shell:
    Sleep                     0.5
    Write                     cd ${repo_path}
    IF  $commit != '${EMPTY}' and $commit != 'NONE'
        Log                       Checking out commit ${commit}  console=True
        Write                     git checkout ${commit}
        SSHLibrary.Read Until     HEAD is now at
        SSHLibrary.Read Until     [nix-shell:
    END

Remove Ghaf Repository
    [Arguments]     ${repo_path}=${REPOSITORY_PATH}
    Run Command     rm -r ${repo_path}   sudo=True
