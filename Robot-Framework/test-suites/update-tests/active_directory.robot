# SPDX-FileCopyrightText: 2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Test Active Directory with AD user

Resource            ../../resources/active-directory.resource
Resource            ../../resources/device_control.resource
Resource            ../../resources/update_keywords.resource

Suite Setup          Prepare Active Directory Rebuild
Suite Teardown       Roll back to original generation after rebuild

Test Tags            ad-user  regression  lenovo-x1  darter-pro  lab-only


*** Test Cases ***
Confirm Active Directory connectivity with AD user
    [Documentation]    Navigate the interactive provisioning script and exit after its AD connectivity success message.
    [Tags]             SP-T519
    [Timeout]          20 minutes
    [Setup]            Switch to vm  ${GUI_VM}
    Check AD Connectivity Through User Provisioning    Join Active Directory domain


*** Keywords ***
Prepare Active Directory Rebuild
    Switch to vm              ${HOST}
    ${gen_before}             Get current generation
    Set Suite Variable        ${gen_before}
    Elevate to superuser
    Run Nix Shell             git
    Clone Ghaf Repository     ${REPOSITORY_PATH}   ${COMMIT_HASH}
    # Disable homed-user and enable ad-users
    Edit File                 ${REPOSITORY_PATH}/modules/reference/profiles/mvp-user-trial.nix  homed-user.enable = true;  homed-user.enable = false;
    Edit File                 ${REPOSITORY_PATH}/modules/reference/profiles/mvp-user-trial.nix  ad-users.enable = false;  ad-users.enable = true;
    # Disable interactive user provision screen, it blocks SSH connections to gui-vm
    Edit File                 ${REPOSITORY_PATH}/modules/reference/profiles/mvp-user-trial.nix  Reference services and personalization
    ...                       { systemd.services.user-provision-interactive.enable = lib.mkForce false; }  ${False}
    Run Nixos Rebuild         intel-laptop-debug  ${REPOSITORY_PATH}  login=False
