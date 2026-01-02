# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Common system tests on host
Force Tags          host  regression

Library             ../../lib/output_parser.py
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Switch to vm   ${HOST}


*** Test Cases ***

Test ghaf version format
    [Documentation]    Test getting Ghaf version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash
    [Tags]             SP-T54  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330  fmo  pre-merge  bat
    Verify Ghaf Version Format

Test nixos version format
    [Documentation]    Test getting Nixos version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash (name)
    [Tags]             SP-T55  nuc  orin-agx  orin-agx-64  orin-nx  lenovo-x1  darter-pro  dell-7330  fmo  pre-merge  bat
    Verify Nixos Version Format

Check QSPI version
    [Documentation]    QSPI version should be up-to-date
    [Tags]             SP-T95  orin-agx  orin-agx-64  orin-nx  pre-merge  bat
    Check QSPI Version is up to date

Check host systemctl status
    [Documentation]    Verify systemctl status is running on host
    [Tags]             SP-T98  systemctl  nuc  orin-agx  orin-agx-64  orin-nx  fmo  pre-merge  bat
    ${status}   ${output}   Run Keyword And Ignore Error    Verify Systemctl status
    Log   ${output}

    IF    '${status}' == 'FAIL'
        ${failing_services}    Parse Services To List    ${output}

        ${known_issues}=    Create List
        ...    NUC|ANY|SSRCSP-4632
        ...    Orin|nvfancontrol.service|SSRCSP-6303
        ...    AGX|systemd-rfkill.service|SSRCSP-6303
        ...    Orin|systemd-oomd.service|SSRCSP-6685

        Check systemctl status for known issues    ${known_issues}   ${failing_services}
    END

Check all VMs are running
    [Documentation]    Check that all VMs are running.
    [Tags]             SP-T68  lenovo-x1  darter-pro  dell-7330  fmo  pre-merge  bat
    @{vms}      Get VM list
    FOR   ${vm}  IN  @{vms}
        ${status}=    Run Keyword And Continue On Failure    Verify service status  service=microvm@${vm}
    END

Check serial connection
    [Documentation]    Check serial connection
    [Tags]             nuc  orin-agx  orin-agx-64  orin-nx  darter-pro  SP-T51  SP-T170  pre-merge  bat  lab-only
    [Setup]            Serial setup
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
    [Tags]           lenovo-x1  darter-pro  dell-7330  SP-5321  pre-merge  bat
    ${lsblk}  Execute Command  lsblk
    Log       ${lsblk}
    ${SSD}    Run Keyword And Return Status  should contain   ${lsblk}   sda
    ${eMMC}   Run Keyword And Return Status  should contain   ${lsblk}   nvme0n1p

    ${memory}  Run Keyword If  ${SSD}   Check External SSD Size
    ...    ELSE IF             ${eMMC}  Check Internal eMMC Size
    ...    ELSE                Fail     Failure. Something missing? No SSD or eMMC partitions captured!

    ${storage}  Check Persist Storage Size
    Should Be True  ${memory} > ${storage} > ${100}
    Should Be True  ${${memory}*${0.80}} <= ${storage}

Check veritysetup status
    [Documentation]  Check that VERITY status is verified
    [Tags]           bat    hardening-installer
    ${output}        Execute Command    veritysetup status root  sudo=True  sudo_password=${PASSWORD}
    ${status}        Get Verity Status  ${output}
    Should Be True   '${status}' == 'verified'


*** Keywords ***

Serial setup
    IF  "${SERIAL_PORT}" == "NONE"
        Skip    There is no address for serial connection
    ELSE
        Open Serial Port
    END

Verify Ghaf Version Format
    [Documentation]    Check that ghaf-version contains version number in the format:"dd.dd"
    ${version}   Get Ghaf Version
    Should Match Regexp	  ${version}  \\d{2}.\\d{2}.?\\d{0,2}\$

Verify Nixos Version Format
    [Documentation]    Check that nixos-version contains version number in the format:"dd.dd",
    ...                date of commit in format yyyymmdd, 7 symbols of hash commit and version name in brackets
    ${major}  ${minor}  ${date}  ${commit}  ${name}    Get Nixos Version
    Should Match Regexp	  ${major}   ^\\d{2}$
    Should Match Regexp	  ${minor}   ^\\d{2}$
    Verify Date Format    ${date}
    Should Match Regexp	  ${commit}   ^[0-9a-f]{7}$
    IF  '${name}' == 'None'
        FAIL    Expected NixOS version name, but there is None
    END

Get Ghaf Version
    [Documentation]    Get version of Ghaf system, Example:
    ...     "ghaf-version"    output: 23.05   parse result: 23.05
    ${output}   ${rc}    Execute Command   ghaf-version   return_rc=True
    Should Be Equal As Integers     ${rc}   0   Couldn't get ghaf version, command return code
    Log To Console    ghaf-version: ${output}
    RETURN    ${output}

Get Nixos Version
    [Documentation]    Get version of NixOS, Example:
    ...     "nixos-version"   output: 23.05.20230625.35130d4 (Stoat)    parse result: 23.05, 20230625, 35130d4, Stoat
    ${output}   ${rc}    Execute Command   nixos-version   return_rc=True
    Should Be Equal As Integers     ${rc}   0   Couldn't get ghaf version, command return code
    Log To Console    nixos-version: ${output}
    ${major}  ${minor}  ${date}  ${commit}  ${name}     Parse Nixos Version   ${output}
    RETURN    ${major}  ${minor}  ${date}  ${commit}  ${name}

Check QSPI Version is up to date
    ${output}      Execute Command    ota-check-firmware
    ${fw_version}  ${sw_version}      Get qspi versions   ${output}
    Should Be True	'${fw_version}' == '${sw_version}'	  Update QSPI version! Test results can be wrong!

Check External SSD Size
    [Documentation]  Check the size of ssd used in setup
    Log To Console   Memory to be checked: SSD
    ${lsblk}  Execute Command  lsblk
    ${size}  Get Regexp Matches  ${lsblk}  (?im)(sda .*\\d*:\\d{1}.*\\d{1}\\s)(\\d{1,3})  2
    RETURN  ${size}[0]

Check Internal eMMC Size
    [Documentation]  Check the size of eMMC used in setup
    Log To Console   Memory to be checked: eMMC
    ${lsblk}  Execute Command  lsblk
    ${size}   Get Regexp Matches  ${lsblk}  (?im)(nvme0n1 .*\\d*:\\d{1}.*\\d{1}\\s)(\\d{1,3})  2
    RETURN    ${size}[0]

Check Persist Storage Size
    [Documentation]  Check the size of persistent storage
    ${storage}  Execute Command  df -h
    Log  ${storage}
    ${size}  Get Regexp Matches  ${storage}  (?im)(\\d{1,3}G)\(\\s*.*\\s)(\\d{1,3})(G)(\\s*.*\\s)/persist  3
    RETURN  ${size}[0]
