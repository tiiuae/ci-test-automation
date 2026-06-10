# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Gui-vm
Test Tags           gui-vm  pre-merge  lenovo-x1  darter-pro  dell-7330  fmo

Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource


*** Test Cases ***

Check user systemctl status
    [Documentation]   Verify systemctl status --user is running
    [Tags]            SP-T260  systemctl
    [Setup]           Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
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
