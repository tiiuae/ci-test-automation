# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Test device visibility in fleetdm
Test Tags           fleetdm  lenovo-x1  darter-pro

Library             Process
Library             String
Library             DateTime
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource

Suite Setup         FleetDM Setup

*** Test Cases ***

Check device status on FleetDM
    [Documentation]     Verify that the device gets listed in fleetdm with correct details:
    ...                 status: online
    ...                 last_restarted_at: close to the actual boot time
    [Tags]              SP-T347
    # FleetDM server detail_update_interval is 1h
    ${tolerance}        Set Variable    3700
    Log To Console      Verifying device online status at fleetdm
    ${output}           Wait Until Keyword Succeeds  31s  10s  Check device on fleetdm
    ${fleet_restart}    Get Lines Containing String  ${output.stdout}  "last_restarted_at":
    ${device_restart}   Get Timestamp of Last Boot
    ${difference}       DateTime.Subtract Date From Date    ${fleet_restart}  ${device_restart}   exclude_millis=True
    IF  ${difference} > ${tolerance} or ${difference} < -${tolerance}
        FAIL    FleetDM last_restarted_at differs more than an hour from the actual device start time
    END


*** Keywords ***

FleetDM Setup
    Switch to vm          ${GUI_VM}
    Run Command           mkdir -p /etc/common/ghaf/fleet                            sudo=True
    Elevate to superuser
    Write                 install -m 600 /dev/stdin /etc/common/ghaf/fleet/enroll
    Sleep                 2
    Set Log Level         NONE
    Write                 ${FLEETDM_ENROLL_SECRET}
    Set Log Level         INFO
    Write Bare            \x04
    SSHLibrary.Read
    Run Command           systemctl restart orbit   sudo=True

Check device on fleetdm
    [Arguments]         ${expected_online}=${True}
    Set Log Level       NONE
    ${get_hosts_cmd}    Set Variable  curl https://fleetdm.vedenemo.dev/api/v1/fleet/hosts?query=${NETVM_NAME} -H "Authorization: Bearer ${FLEETDM_API_TOKEN}"
    ${output} 	        Run Process   sh    -c    ${get_hosts_cmd}    shell=true
    Set Log Level       INFO
    Log                 ${output.stdout}
    IF  ${expected_online}
        Should Contain      ${output.stdout}  "status": "online",
    ELSE
        Should Contain      ${output.stdout}  "status": "offline",
    END
    RETURN              ${output}