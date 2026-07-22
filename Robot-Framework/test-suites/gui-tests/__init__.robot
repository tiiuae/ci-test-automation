# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Test Tags           regression  gui

Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/setup_keywords.resource

Suite Setup         GUI Tests Setup
Suite Teardown      GUI Tests Teardown
Test Timeout        5 minutes


*** Keywords ***

GUI Tests Setup
    [Timeout]    5 minutes
    Prepare Test Environment   enable_dnd=True
    Save gui icons and icon path

GUI Tests Teardown
    [Timeout]    5 minutes
    # In case the screen recording was not stopped
    Stop screen recording service
    Clean Up Test Environment   disable_dnd=True

Save gui icons and icon path
    [Documentation]         Save the icons that are used in GUI tests
    Log To Console          Saving GUI test icons
    ${icons}                Run Command   find $(echo $XDG_DATA_DIRS | tr ':' ' ') -type d -name "icons" 2>/dev/null   rc_match=skip
    # Window controls
    Get icon                ${icons}/Cosmic/scalable/actions  window-close-symbolic.svg  crop=0  background=white  output_filename=window-close.png
    Negate app icon         ${ICONS_DIR}/window-close.png  ${ICONS_DIR}/window-close-neg.png
    OperatingSystem.Copy File    ../test-files/ghaf-close.png    ${ICONS_DIR}/
    OperatingSystem.Copy File    ../test-files/gala_signin_arrow.png    ${ICONS_DIR}/
    ${open_normal_icon}     Run Command   ls -d /nix/store/*-open-normal/ghaf-logo-512px.png
    SSHLibrary.Get File     ${open_normal_icon}    ${ICONS_DIR}/open-normal-browser.png
    OperatingSystem.Run     magick ${ICONS_DIR}/open-normal-browser.png -resize 16x16 -background white -alpha remove ${ICONS_DIR}/open-normal-browser.png
    # Desktop
    Get icon                ${icons}/Cosmic/scalable/actions  system-search-symbolic.svg  crop=0  background=white  output_filename=search.png
    Negate app icon         ${ICONS_DIR}/search.png  ${ICONS_DIR}/search-neg.png
    Get icon                ${icons}/Papirus/24x24/actions  system-shutdown.svg  crop=0  background=black  output_filename=power.png
    # App icons
    Get icon                ${icons}/Papirus/48x48/apps  Zoom.svg  crop=0  background=black  output_filename=${Zoom}[icon]
    Get icon                ${icons}/hicolor/48x48/apps  com.system76.CosmicSettings.svg  background=black  output_filename=${COSMIC Settings}[icon]
