# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Validates that individual VM failures are isolated and do not impact
...                 the availability, performance, or security of other VMs or the host system.
Force Tags          security  regression  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Switch to vm   ${NET_VM}


*** Test Cases ***

Stopping one VM does not affect others
    [Documentation]     Run application in some VM, stop another VM and check
    ...                 that it doesn't affect the first VM and app running
    [Tags]              SP-T286
    [Template]          Stopping one VM does not affect another
    ${BUSINESS_VM}  ${COMMS_VM}     Slack            slack
    ${CHROME_VM}    ${ZATHURA_VM}   "PDF Viewer"     zathura
    ${ZATHURA_VM}   ${BUSINESS_VM}  Gala             gala
    ${COMMS_VM}     ${CHROME_VM}    "Google Chrome"  chrome


*** Keywords ***

Stopping one VM does not affect another
    [Arguments]     ${one_vm}    ${another_vm}    ${app_name}    ${process_name}
    Switch to vm   ${another_vm}
    Start application in VM   ${app_name}   ${another_vm}    ${process_name}
    Stop VM        ${one_vm}
    ${state}  ${substate}   Verify service status  service=microvm@${another_vm}.service  expected_state=active  expected_substate=running
    Switch to vm   ${another_vm}
    Check that the application was started    ${process_name}
    [Teardown]    Run Keywords   Start VM   ${one_vm}   AND   Kill App in VM   ${another_vm}   ${process_name}   PASS

Stop VM
    [Documentation]         Try to stop VM and verify it stopped
    [Arguments]             ${vm}
    Switch to vm            ${HOST}
    Log                     Going to stop ${vm}    console=True
    Execute Command         systemctl stop microvm@${vm}.service  sudo=True  sudo_password=${PASSWORD}  timeout=120
    Sleep    3
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=inactive  expected_substate=dead
    Log                     ${vm} is ${substate}    console=True

Start VM
    [Documentation]         Try to start VM and verify it started
    [Arguments]             ${vm}
    Switch to vm            ${HOST}
    Log                     Going to start ${vm}    console=True
    Execute Command         systemctl start microvm@${vm}.service  sudo=True  sudo_password=${PASSWORD}  timeout=120
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=active  expected_substate=running
    Log                     ${vm} is ${substate}    console=True

