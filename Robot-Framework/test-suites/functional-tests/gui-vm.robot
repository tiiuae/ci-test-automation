# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Gui-vm
Test Tags           gui-vm  pre-merge

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource

Suite Setup         Switch to vm    ${GUI_VM}  user=${USER_LOGIN}


*** Test Cases ***

Check user systemctl status
    [Documentation]   Verify systemctl status --user is running
    [Tags]            SP-T260  systemctl  darter-pro  lenovo-x1  dell-7330  fmo
    [Teardown]        Set Test Message    append=${True}  separator=\n    message=${found_known_issues_message}
    Set Test Variable   ${found_known_issues_message}   ${EMPTY}

    ${known_issues}=    Create List
    # Add any known failing services here with the target device and bug ticket number.
    # ...    device|gui-vm|service-name|ticket-number

    ${status}     ${failed_units}=  Verify Systemctl status    range=3   add_params=--user
    Should not be true    '${status}' == 'starting'      msg=Current systemctl status is ${status}. Failed processes?: ${failed_units}

    Log    ${failed_units}

    # Filter out Cosmic Initial Setup (we kill it at the beginning of the tests)
    ${filtered_failed_units}    Evaluate   [u for u in ${failed_units} if "app-com.system76.CosmicInitialSetup@autostart.service" not in u]
    Log   ${filtered_failed_units}

    IF    ${filtered_failed_units}
        Check systemctl status for known issues  ${DEVICE_TYPE}  ${GUI_VM}  ${known_issues}  ${filtered_failed_units}   user=True
    END

Givc-cli shows Ghaf version
    [Documentation]    Verify that givc-cli sysinfo shows current Ghaf version.
    [Tags]             SP-T369  SP-T369-1  darter-pro  lenovo-x1
    ${version}         Get Ghaf Version
    Verify givc-cli sysinfo field    Ghaf Version    ${version}

Givc-cli shows Secure Boot enabled
    [Documentation]    Verify that givc-cli sysinfo shows Secure Boot enabled on Secure Boot devices.
    [Tags]             SP-T369  SP-T369-2  lenovo-x1  secboot-only
    Verify givc-cli sysinfo field    Secure Boot    enabled

Givc-cli shows Secure Boot disabled
    [Documentation]    Verify that givc-cli sysinfo shows Secure Boot disabled on non-Secure Boot devices.
    [Tags]             SP-T369  SP-T369-3  darter-pro  lenovo-x1  excl-secboot
    Verify givc-cli sysinfo field    Secure Boot    disabled

Givc-cli shows Disk Encryption
    [Documentation]    Verify that givc-cli sysinfo shows Disk Encryption enabled on installer images and disabled on non-installers.
    [Tags]             SP-T369  SP-T369-4  darter-pro  lenovo-x1
    IF    "installer" in "${JOB}"
        Verify givc-cli sysinfo field    Disk Encryption    enabled
    ELSE
        Verify givc-cli sysinfo field    Disk Encryption    disabled
    END

*** Keywords ***

Verify givc-cli sysinfo field
    [Arguments]    ${field}    ${expected}
    ${output}      Run Command    givc-cli sysinfo
    ${actual}      Get givc-cli sysinfo field    ${output}    ${field}
    Should Be Equal As Strings    ${actual}    ${expected}    ignore_case=True    msg=${field} value in givc-cli sysinfo is ${actual}, expected ${expected}.

Get givc-cli sysinfo field
    [Arguments]    ${output}    ${field}
    ${matches}     Get Regexp Matches    ${output}    (?m)^${field}:\\s*(\\S(?:.*\\S)?)\\s*$    1
    Should Not Be Empty    ${matches}    Could not find ${field} in givc-cli sysinfo output:\n${output}
    RETURN         ${matches}[0]
