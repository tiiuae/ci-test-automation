# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       GUI tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/gui_keywords.resource
Suite Setup         Common Setup
Suite Teardown      Common Teardown


*** Keywords ***

Common Setup
    Set Variables   ${DEVICE}
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == ""    Get ethernet IP address
    ${port_22_is_available}     Check if ssh is ready on device   timeout=180
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Verify service status  range=15  service=microvm@gui-vm.service  expected_status=active  expected_state=running
        Connect to netvm
        Connect to VM       ${GUI_VM}
    END
    Run journalctl recording
    Verify logout
    Log To Console    logged_in_status
    Log To Console    ${logged_in_status}
    IF  ${logged_in_status}
        Log To Console    Already logged in. Skipping login at suite setup.
    ELSE
        Log To Console    Logging in
        GUI Log in
    END

Common Teardown
    Connect
    IF  "Lenovo" in "${DEVICE}"
        Connect to netvm
        Connect to VM       ${GUI_VM}
    END
    GUI Log out
    Log journctl
    Close All Connections

Run journalctl recording
    ${output}     Execute Command    journalctl > jrnl.txt
    ${output}     Execute Command    nohup journalctl -f >> jrnl.txt 2>&1 &

Log journctl
    ${output}     Execute Command    cat jrnl.txt
    Log           ${output}
    @{pid}        Find pid by name   journalctl
    Kill process  @{pid}
