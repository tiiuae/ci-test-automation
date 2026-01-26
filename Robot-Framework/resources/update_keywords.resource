# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             String
Resource            ../resources/common_keywords.resource


*** Keywords ***

Get current generation
    [Documentation]        Extract the number of current generation
    ${output}              Run Command  nix-env -p /nix/var/nix/profiles/system --list-generations  sudo=True
    ${current_line}        Get Lines Containing String  ${output}  (current)
    ${current_generation}  ${rest}  Split String   ${current_line}  max_split=1
    RETURN                 ${current_generation}

Roll back to original generation
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
