# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Common system tests
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Library             ../../lib/output_parser.py

*** Test Cases ***

Test ghaf version format
    [Documentation]    Test getting Ghaf version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash
    [Tags]             bat   SP-T59  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    [Setup]     Connect
    Verify Ghaf Version Format
    [Teardown]  Close All Connections

Test nixos version format
    [Documentation]    Test getting Nixos version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash (name)
    [Tags]             bat   SP-T60  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    [Setup]     Connect
    Verify Nixos Version Format
    [Teardown]  Close All Connections

Check QSPI version
    [Documentation]    QSPI version should be up-to-date
    [Tags]             bat   SP-T100   orin-agx  orin-nx
    [Setup]     Connect
    Check QSPI Version is up to date
    [Teardown]  Close All Connections

Check systemctl status
    [Documentation]    Verify systemctl status is running
    [Tags]             bat  SP-T104  nuc  orin-agx  orin-nx  riscv
    [Setup]     Connect
    Verify Systemctl status
    [Teardown]  Close All Connections

Check all VMs are running
    [Documentation]    Verify systemctl status of all VMs is running
    [Tags]             bat  SP-T73  lenovo-x1
    [Setup]     Connect
    ${output}   Execute Command    microvm -l
    @{vms}      Extract VM names   ${output}
    FOR   ${vm}  IN  @{vms}
        ${status}=    Run Keyword And Continue On Failure    Verify service status  service=microvm@${vm}
    END
    [Teardown]  Close All Connections

Check serial connection
    [Documentation]    Check serial connection
    [Tags]             bat  nuc  orin-agx  orin-nx  riscv  SP-T56  SP-T179
    [Setup]     Open Serial Port
    FOR    ${i}    IN RANGE    120
        Write Data    ${\n}
        ${output} =    SerialLibrary.Read Until
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ghaf
        IF    ${status}    BREAK
        Sleep   1
    END
    IF    ${status} == False   Fail  Device is not available via serial port, used port: ${SERIAL_PORT}
    [Teardown]  Delete All Ports

