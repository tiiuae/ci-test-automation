# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing logout and login via GUI
Force Tags          gui
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/gui_keywords.resource
Suite Teardown      Close All Connections


*** Test Cases ***

Boot to login screen
    [Documentation]   Check that device booted to login screen
    [Tags]            lenovo-x1   SP-T2
    Run Keyword If    ${LOGGED_IN_STATUS}  FAIL  Desktop was detected at setup. Device failed to boot to login screen.

Log out and log in
    [Tags]            lenovo-x1   SP-T149
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Connect to netvm
        Connect to VM       ${GUI_VM}
    END
    GUI Log out
    GUI Log in