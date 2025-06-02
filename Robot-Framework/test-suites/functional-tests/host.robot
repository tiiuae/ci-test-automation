# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Common system tests on host
Force Tags          host
Resource            ../../__framework__.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Library             ../../lib/output_parser.py
Suite Setup         Connect to ghaf host
Suite Teardown      Close All Connections

*** Test Cases ***

Test ghaf version format
    [Documentation]    Test getting Ghaf version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash
    [Tags]             bat  regression   pre-merge   SP-T54  nuc  orin-agx  orin-agx-64  orin-nx  riscv  lenovo-x1   dell-7330
    Verify Ghaf Version Format

Test nixos version format
    [Documentation]    Test getting Nixos version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash (name)
    [Tags]             bat  regression   pre-merge   SP-T55  nuc  orin-agx  orin-agx-64  orin-nx  riscv  lenovo-x1   dell-7330
    Verify Nixos Version Format

Check QSPI version
    [Documentation]    QSPI version should be up-to-date
    [Tags]             bat  regression   pre-merge  SP-T95  orin-agx  orin-agx-64  orin-nx
    Check QSPI Version is up to date

Check systemctl status
    [Documentation]    Verify systemctl status is running
    [Tags]             bat  regression   pre-merge  SP-T98  nuc  orin-agx  orin-agx-64  orin-nx  riscv  lenovo-x1   dell-7330
    ${status}   ${output}   Run Keyword And Ignore Error    Verify Systemctl status

    IF    '${status}' == 'FAIL'
        ${known_issues}=    Create List
        ...    NUC|ANY|SSRCSP-4632
        ...    NX|nvfancontrol.service|SSRCSP-6303
        ...    AGX|nvfancontrol.service|SSRCSP-6303
        ...    AGX|systemd-rfkill.service|SSRCSP-6303
        ...    Dell|autovt@ttyUSB0.service|SSRCSP-6450

        FOR    ${entry}    IN    @{known_issues}
            ${parts}=    Split String    ${entry}    |
            ${list_device}=    Set Variable    ${parts[0]}
            ${service}=   Set Variable    ${parts[1]}
            ${issue}=     Set Variable    ${parts[2]}

            ${device_match}=    Run Keyword And Return Status    Should Contain    ${DEVICE}    ${list_device}
            Run Keyword If    '${device_match}' == 'True' and '${service}' == 'ANY'    Skip    Known issue: ${issue}

            ${service_match}=    Run Keyword And Return Status    Should Contain    ${output}    ${service}
            Run Keyword If    '${device_match}' == 'True' and '${service_match}' == 'True'    Skip    Known issue: ${issue}
        END
        FAIL    ${output}
    END

Check all VMs are running
    [Documentation]    Check that all VMs are running.
    [Tags]             bat  regression  SP-T68  lenovo-x1   dell-7330
    ${output}   Execute Command    microvm -l
    @{vms}      Extract VM names   ${output}
    Should Not Be Empty   ${vms}  VM list is empty
    FOR   ${vm}  IN  @{vms}
        ${status}=    Run Keyword And Continue On Failure    Verify service status  service=microvm@${vm}
    END

Check serial connection
    [Documentation]    Check serial connection
    [Tags]             bat  regression  nuc  orin-agx  orin-agx-64  orin-nx  riscv  SP-T51  SP-T170
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

Check Memory status
    [Documentation]  Check that there is enough memory available
    [Tags]  bat  regression  lenovo-x1   dell-7330  SP-5321
    ${lsblk}  Execute Command  lsblk
    log       ${lsblk}
    ${SSD}    run keyword and return status  should contain   ${lsblk}   sda
    ${eMMC}   run keyword and return status  should contain   ${lsblk}   nvme0n1p

    ${memory}  run keyword if  ${SSD}   Check External SSD Size
    ...    ELSE IF             ${eMMC}  Check Internal eMMC Size
    ...    ELSE                Fail     Failure. Something missing? No SSD or eMMC partitions captured!

    ${storage}  Check Persist Storage Size
    Should Be True  ${memory} > ${storage} > ${100}
    Should Be True  ${${memory}*${0.80}} <= ${storage}
