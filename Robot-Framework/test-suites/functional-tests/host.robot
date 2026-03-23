# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Common system tests on host
Test Tags           host

Library             ../../lib/output_parser.py
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource

Suite Setup         Switch to vm   ${HOST}


*** Test Cases ***

Check device id
    [Documentation]    Compare actual device id with expected one from the config file,
    ...                It should never change.
    [Tags]             SP-T351  SP-T351-1  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  lab-only
    ${actual_device_id}          Get Actual Device ID
    Log                Comparing actual device ID ${actual_device_id} and expected ${STATIC_DEVICE_ID}     console=True
    Should Be Equal As Strings   ${actual_device_id}    ${STATIC_DEVICE_ID}    ignore_case=True
    ...                          msg=Actual device ID != Expected
    [Teardown]         Run Keyword If Test Failed    Check device id failure    ${actual_device_id}

Test ghaf version format
    [Documentation]    Test getting Ghaf version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash
    [Tags]             SP-T54  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  fmo
    Verify Ghaf Version Format

Test nixos version format
    [Documentation]    Test getting Nixos version and verify its format:
    ...                Expected format: major.minor.yyyymmdd.commit_hash (name)
    [Tags]             SP-T55  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  orin-agx  orin-agx-64  orin-nx  fmo
    Verify Nixos Version Format

Check QSPI version
    [Documentation]    QSPI version should be up-to-date
    [Tags]             SP-T95  pre-merge  bat  orin-agx  orin-agx-64  orin-nx
    Check QSPI Version is up to date
    [Teardown]   Run Keyword If Test Failed    SKIP    QSPI needs to be flashed

Check all VMs are running
    [Documentation]    Check that all VMs are running.
    [Tags]             SP-T68  SP-T68-1  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  fmo
    @{vms}      Get VM list
    FOR   ${vm}  IN  @{vms}
        ${status}=    Run Keyword And Continue On Failure    Verify service status  service=microvm@${vm}
    END

Check all VMs are running on Orins
    [Documentation]    Check that all VMs are running.
    [Tags]             SP-T68  SP-T68-2  pre-merge  bat  orin-nx  orin-agx  orin-agx-64
    Switch to vm    ${HOST}
    ${output}       Run Command        microvm -l
    ${output}       Replace String Using Regexp    ${output}    \x1b\\[[0-9;]*m    ${EMPTY}
    @{lines}        Split To Lines     ${output}
    Should Not Be Empty     ${lines}   VM list is empty
    FOR   ${line}  IN  @{lines}
        ${status}    Run Keyword And Continue On Failure    Should Not Contain   ${line}   not booted
    END

Check serial connection
    [Documentation]    Check serial connection
    [Tags]             SP-T170  SP-T51  pre-merge  bat  darter-pro  orin-agx  orin-agx-64  orin-nx  lab-only
    [Setup]            Serial setup
    Log    Reading serial console...     console=True
    FOR    ${i}    IN RANGE    30
        Write Data     ${\n}
        ${output}      SerialLibrary.Read Until
        ${status}      Run Keyword And Return Status    Should Contain    ${output}    ghaf
        IF  ${status}  BREAK
        Sleep   1
    END
    IF    ${status} == False   Fail  Device is not available via serial port, used port: ${SERIAL_PORT}
    [Teardown]  Delete All Ports

Check storage size
    [Documentation]  Check that there is enough persistent storage available
    [Tags]           SP-T342  pre-merge  bat  lenovo-x1  darter-pro  dell-7330
    ${total_storage}       Check Boot Disk Size
    ${persistent_storage}  Check Persistent Storage Size
    Should Be True  ${total_storage} > ${persistent_storage} > ${100}
    Should Be True  ${${total_storage}-250} <= ${persistent_storage}

Check veritysetup status
    [Documentation]  Check that VERITY status is verified
    [Tags]           hardening-installer  bat
    ${output}        Run Command    veritysetup status root  sudo=True
    ${status}        Get Verity Status  ${output}
    Should Be True   '${status}' == 'verified'

Check full disk encryption
    [Documentation]  Check that full disk encryption was done for images installed with "ghaf-installer -e"
    [Tags]           SP-T348  lenovo-x1  darter-pro  installer-only
    ${output}        Run Command    lsblk -dno FSTYPE /dev/nvme0n1p2
    Should Be Equal  ${output}      crypto_LUKS    /dev/nvme0n1p2 FSTYPE is ${output}, expected crypto_LUKS
    ${output}        Run Command    lsblk -dno TYPE /dev/mapper/crypted
    Should Be Equal  ${output}      crypt          /dev/mapper/crypted TYPE is ${output}, expected crypt

Check Secure Boot is enabled
    [Documentation]  To be run only on Secure Boot X1
    ...              Install sbctl and check that Secure Boot is enabled
    [Tags]           SP-T341  lenovo-x1  secboot-only
    ${sb_status}      Get Secure Boot Status
    Should Be Equal   ${sb_status}   Enabled   Secure Boot is not enabled

Check that laptop booted from Internal Memory
    [Documentation]  Check that laptop booted and is running from the internal memory when running tests with installer
    [Tags]           SP-T130  SP-T130-1  lenovo-x1  darter-pro  installer-only
    Check that System And Boot Disk Match    nvme0n1

Check that laptop booted from SSD
    [Documentation]  Check that laptop booted and is running from the SSD when running tests without installer
    [Tags]           SP-T130  SP-T130-2  pre-merge  bat  lenovo-x1  darter-pro  excl-installer
    Check that System And Boot Disk Match    sda

*** Keywords ***

Serial setup
    IF  "${SERIAL_PORT}" == "NONE"
        Skip    There is no address for serial connection
    ELSE
        ${status}   Open Serial Port
        IF    ${status}==False    SKIP    Serial Port is not available
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
    ${output}   Run Command   ghaf-version
    Log To Console    ghaf-version: ${output}
    RETURN    ${output}

Get Nixos Version
    [Documentation]    Get version of NixOS, Example:
    ...     "nixos-version"   output: 23.05.20230625.35130d4 (Stoat)    parse result: 23.05, 20230625, 35130d4, Stoat
    ${output}   Run Command   nixos-version
    Log To Console    nixos-version: ${output}
    ${major}  ${minor}  ${date}  ${commit}  ${name}     Parse Nixos Version   ${output}
    RETURN    ${major}  ${minor}  ${date}  ${commit}  ${name}

Check QSPI Version is up to date
    ${output}      Run Command     ota-check-firmware  rc_match=skip
    ${fw_version}  ${sw_version}   Get qspi versions   ${output}
    Should Be True	'${fw_version}' == '${sw_version}'	  Update QSPI version! Test results can be wrong!

Check that System And Boot Disk Match
    [Documentation]    Check that /boot and / are backed by the same physical disk and match the expected disk.
    [Arguments]        ${expected_disk}
    ${boot_disk}       Get Backing Disk For Mountpoint    /boot
    ${root_disk}       Get Backing Disk For Mountpoint    /
    Should Be Equal    ${boot_disk}       ${expected_disk}    Laptop booted from ${boot_disk}, expected ${expected_disk}
    Should Be Equal    ${root_disk}       ${boot_disk}        / is mounted from ${root_disk}, expected ${boot_disk}

Get Backing Disk For Mountpoint
    [Documentation]    Resolve the physical disk backing the given mountpoint.
    [Arguments]        ${mountpoint}
    ${device}          Run Command    findmnt -no SOURCE ${mountpoint}
    ${disk_info}       Run Command    lsblk --json -s -o NAME,TYPE ${device}
    ${disk}            Get Backing Disk From Lsblk    ${disk_info}
    RETURN             ${disk}

Check Boot Disk Size
    [Documentation]  Check the size of the disk the system booted from.
    ${disk}          Get Backing Disk For Mountpoint    /boot
    Log To Console   Disk to be checked: ${disk}
    ${size}          Run Command  lsblk -b -dn -o NAME,SIZE | awk '$1=="${disk}" {print int(($2/1024/1024/1024)+0.5)}'
    RETURN           ${size}

Check Persistent Storage Size
    [Documentation]  Check the size of persistent storage
    ${size}          Run Command  df -B1G --output=avail /persist | tail -1
    RETURN           ${size}

Check device id failure
    [Arguments]    ${actual_device_id}
    IF    "system76-darp11-b-storeDisk-debug-installer" in "${JOB}"
        &{ids}    Create Dictionary
        ...    DarterPRO-prod=00-c0-44-19-76
        ...    DarterPRO-rel=00-89-3c-52-5d
        ...    DarterPRO-dev=00-e7-04-ed-e3
        ${expected_wrong_id}    Get From Dictionary    ${ids}    ${SWITCH_BOT}
        IF    "${actual_device_id}" == "${expected_wrong_id}"
            SKIP   Known issue: SSRCSP-7997
        ELSE
            FAIL   Actual device ID: ${actual_device_id}, Should be: ${STATIC_DEVICE_ID}, expected to fail with ${expected_wrong_id}
        END
    ELSE
        SKIP    Device ID needs to be updated
    END

Get Secure Boot Status
    [Documentation]    Install sbctl, get status and returns Secure Boot state (Enabled/Disabled)
    SSHLibrary.Read
    Set Client Configuration  timeout=60
    Write              nix-shell -p sbctl
    ${output} 	       SSHLibrary.Read Until     [nix-shell:
    Write              sbctl status
    ${output} 	       SSHLibrary.Read Until     [nix-shell:
    ${clean}           Replace String Using Regexp    ${output}    \x1B\[[0-9;?]*[ -/]*[@-~]    ${EMPTY}
    ${line}            Get Lines Containing String    ${clean}     Secure Boot:
    Should Not Be Empty    ${line}    Could not find Secure Boot line in sbctl output
    IF    'Enabled' in $line
        RETURN    Enabled
    ELSE IF    'Disabled' in $line
        RETURN    Disabled
    ELSE
        FAIL      Could not determine Secure Boot state from line: ${line}
    END
