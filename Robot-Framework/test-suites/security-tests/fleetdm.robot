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
    Set Log Level         NONE
    ${get_hosts_cmd}    Set Variable  curl https://fleetdm.vedenemo.dev/api/v1/fleet/hosts?query=${NETVM_NAME} -H "Authorization: Bearer ${FLEETDM_API_TOKEN}"
    ${output} 	        Run Process   sh    -c    ${get_hosts_cmd}    shell=true
    Set Log Level       INFO
    ${status_ok}        Run Keyword And Return Status    Should Contain    ${output.stdout}  "status": "online",
    ${fleet_restart}    Get Lines Containing String  ${output.stdout}  "last_restarted_at":
    ${device_restart}   Get Timestamp of Last Boot
    ${difference}       DateTime.Subtract Date From Date    ${fleet_restart}  ${device_restart}   exclude_millis=True
    IF  ${difference} > 100 or ${difference} < -100
        FAIL
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
