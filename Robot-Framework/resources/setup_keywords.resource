# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Resource            ../resources/gui_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Keywords ***

Prepare Test Environment
    [Arguments]   ${login}=True   ${enable_dnd}=False
    Connect to device
    Log versions
    Start journalctl recording

    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Switch to vm    gui-vm
        Create test user
        IF  ${login}
            Save gui icons and icon path
            Start ydotoold
            Log in, unlock and verify   ${enable_dnd}
        END
    END

Clean Up Test Environment
    [Timeout]     5 minutes
    [Arguments]   ${disable_dnd}=False
    Connect to ghaf host
    Stop journalctl recording
    IF  "Lenovo" in "${DEVICE}" or "Dell" in "${DEVICE}"
        Switch to vm    gui-vm
        Start ydotoold
        Log out and verify   ${disable_dnd}
        Stop ydotoold
    END
    Close All Connections

Connect to device
    [Documentation]  Connect to device
    Close All Connections
    Run Keyword If  "${DEVICE_IP_ADDRESS}" == "NONE"    Get ethernet IP address
    ${port_22_is_available}     Check if ssh is ready on device   timeout=60
    IF  ${port_22_is_available} == False
        FAIL    Failed because port 22 of device was not available, tests can not be run.
    END
    ${CONNECTION}        Connect to ghaf host
    Set Global Variable  ${CONNECTION}

Start journalctl recording
    ${output}     Execute Command    nohup journalctl -f >> /tmp/jrnl.txt 2>&1 &

Stop journalctl recording
    ${jrnl_size}  Execute Command    ls -lh /tmp/jrnl.txt
    Log           ${jrnl_size}
    # Copy journal log file to Robot outputs
    SSHLibrary.Get file   /tmp/jrnl.txt   ${OUTPUT_DIR}/jrnl.txt
    OperatingSystem.File Should Exist     ${OUTPUT_DIR}/jrnl.txt
    @{pid}        Find pid by name   journalctl
    Kill process  @{pid}

Log versions
    ${ghaf_version}     Execute Command   ghaf-version
    Log To Console      Ghaf version: ${ghaf_version}
    ${nixos_version}    Execute Command   nixos-version
    Log To Console      Nixos version: ${nixos_version}
    ${device_id}        Execute Command   cat /persist/common/device-id
    Log To Console      Device ID: ${device_id}