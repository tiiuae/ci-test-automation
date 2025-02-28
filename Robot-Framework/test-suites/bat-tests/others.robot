# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Common system tests
Force Tags          others
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/serial_keywords.resource
Library             ../../lib/output_parser.py
Suite Setup         Connect to ghaf host
Suite Teardown      Close All Connections

*** Test Cases ***

Test ghaf version format
    [Documentation]    Test getting Ghaf version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash
    [Tags]             bat   pre-merge   SP-T54  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    Verify Ghaf Version Format

Test nixos version format
    [Documentation]    Test getting Nixos version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash (name)
    [Tags]             bat   pre-merge   SP-T55  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    Verify Nixos Version Format

Check QSPI version
    [Documentation]    QSPI version should be up-to-date
    [Tags]             bat   SP-T95   orin-agx  orin-nx
    Check QSPI Version is up to date

Check systemctl status
    [Documentation]    Verify systemctl status is running
    [Tags]             bat   pre-merge  SP-T98  nuc  orin-agx  orin-nx  riscv  lenovo-x1
    ${status}   ${output}   Run Keyword And Ignore Error    Verify Systemctl status  close_conn=false
    IF  '${status}' == 'FAIL'
        IF  "NUC" in "${DEVICE}"
            Skip    "Known issue: SSRCSP-4632"
        ELSE IF   "NX" in "${DEVICE}"
            Skip    "Known issue: SSRCSP-6303"
        ELSE IF   "AGX" in "${DEVICE}"
            Skip    "Known issue: SSRCSP-6303"
        ELSE
            FAIL    ${output}
        END
    END

Check all VMs are running
    [Documentation]    Check that all VMs are running.
    [Tags]             bat  SP-T68  lenovo-x1
    ${output}   Execute Command    microvm -l
    @{vms}      Extract VM names   ${output}
    Should Not Be Empty   ${vms}  VM list is empty
    FOR   ${vm}  IN  @{vms}
        ${status}=    Run Keyword And Continue On Failure    Verify service status  service=microvm@${vm}
    END

Check serial connection
    [Documentation]    Check serial connection
    [Tags]             bat  nuc  orin-agx  orin-nx  riscv  SP-T51  SP-T170
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
    [Tags]  bat  lenovo-x1  SSRCSP-5321
    ${lsblk}  Execute Command  lsblk
    log       ${lsblk}
    ${SSD}    run keyword and return status  should contain   ${lsblk}   sda
    ${eMMC}   run keyword and return status  should contain   ${lsblk}   nvme0n1p

    ${memory}  run keyword if  ${SSD}   Check External SSD Size
    ...    ELSE IF             ${eMMC}  Check Internal eMMC Size
    ...    ELSE                Fail     Failure. Something missing? No SSD or eMMC partitions captured!

    ${storage}  Check Storagevm Size
    Should Be True  ${memory} > ${storage} > ${100}
    Should Be True  ${${memory}*${0.80}} <= ${storage}
