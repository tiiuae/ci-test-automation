# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/common_keywords.resource
Library             ../../lib/gui_testing.py
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables           ${DEVICE}
    Run Keyword If          "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    ${port_22_is_available}     Check if ssh is ready on device   timeout=180
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Verify service status   range=15  service=microvm@gui-vm.service  expected_status=active  expected_state=running
        Connect to netvm
        Connect to VM           ${GUI_VM}
    END
    Run journalctl recording
    Save most common icons and paths to icons
    Log To Console              Check if the screen is in locked state
    ${lock}                     Check if locked
    IF  ${lock}
        Log To Console          Screen lock detected
        Unlock
    ELSE
        Log To Console          Screen lock not active
        GUI Log in
    END
    Verify login

Common Teardown
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Connect to netvm
        Connect to VM       ${GUI_VM}
    END
    Log journctl
    Close All Connections

Save most common icons and paths to icons
    [Documentation]         Save those icons by name which will be used in multiple test cases
    ...                     Śave paths to icon packs in gui-vm nix store
    Set Global Variable     ${ADWAITA}        /run/current-system/sw/share/icons/Adwaita
    Log To Console          Saving path to icon-pack
    ${app_icon_pack_path}   Execute Command   echo /nix/store/$(ls /nix/store | grep icon-pack | grep -v .drv)
    Set Global Variable     ${APP_ICON_PATH}  ${app_icon_pack_path}
    Log To Console          ${APP_ICON_PATH}
    Log To Console          Saving path to ghaf-artwork icons
    ${ghaf_artwork_path}    Execute Command   echo /nix/store/$(ls /nix/store | grep ghaf-artwork- | grep -v .drv)/icons
    Set Global Variable     ${ARTWORK_PATH}  ${ghaf_artwork_path}
    Log To Console          ${ARTWORK_PATH}
    Log To Console          Saving gui icons
    Get icon                ghaf-artwork  launcher.svg  crop=0  background=black  output_filename=launcher.png
    Get icon                ${ADWAITA}/symbolic/ui  window-close-symbolic.svg  crop=0  output_filename=window-close.png  background=white
    Negate app icon         window-close.png  window-close-neg.png
