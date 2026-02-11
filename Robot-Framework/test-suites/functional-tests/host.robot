# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Common system tests on host
Test Tags           host

Library             ../../lib/output_parser.py
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/ssh_keywords.resource

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

Check host systemctl status
    [Documentation]    Verify systemctl status is running on host
    [Tags]             SP-T98  SP-T98-1  systemctl  pre-merge  bat  orin-agx  orin-agx-64  orin-nx  fmo
    [Teardown]         Set Test Message    append=${True}  separator=\n    message=${found_known_issues_message}
    Set Test Variable       ${found_known_issues_message}   ${EMPTY}

    ${status}   ${output}   Run Keyword And Ignore Error    Verify Systemctl status
    Log   ${output}

    IF    '${status}' == 'FAIL'
        ${failing_services}    Parse Services To List    ${output}

        ${known_issues}=    Create List
        ...    Orin|nvfancontrol.service|SSRCSP-6303
        ...    AGX|systemd-rfkill.service|SSRCSP-6303
        ...    Orin|systemd-oomd.service|SSRCSP-6685

        Check systemctl status for known issues    ${DEVICE}   ${known_issues}   ${failing_services}
    END

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
    ${lsblk}  Run Command  lsblk
    ${SSD}    Run Keyword And Return Status  Should Contain   ${lsblk}   sda
    ${eMMC}   Run Keyword And Return Status  Should Contain   ${lsblk}   nvme0n1p

    ${total_storage}  Run Keyword If  ${SSD}   Check External SSD Size
    ...    ELSE IF      ${eMMC}  Check Internal eMMC Size
    ...    ELSE         FAIL     Failure. Something missing? No SSD or eMMC partitions captured!

    ${persistent_storage}  Check Persistent Storage Size
    Should Be True  ${total_storage} > ${persistent_storage} > ${100}
    Should Be True  ${${total_storage}-250} <= ${persistent_storage}

Check veritysetup status
    [Documentation]  Check that VERITY status is verified
    [Tags]           hardening-installer  bat
    ${output}        Run Command    veritysetup status root  sudo=True
    ${status}        Get Verity Status  ${output}
    Should Be True   '${status}' == 'verified'


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

Check External SSD Size
    [Documentation]  Check the size of ssd used in setup
    Log To Console   Memory to be checked: SSD
    ${size}          Run Command  lsblk -b -dn -o NAME,SIZE | awk '$1=="sda" {print int(($2/1024/1024/1024)+0.5)}'
    RETURN           ${size}

Check Internal eMMC Size
    [Documentation]  Check the size of eMMC used in setup
    Log To Console   Memory to be checked: eMMC
    ${size}          Run Command  lsblk -b -dn -o NAME,SIZE | awk '$1=="nvme0n1" {print int(($2/1024/1024/1024)+0.5)}'
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
    END
