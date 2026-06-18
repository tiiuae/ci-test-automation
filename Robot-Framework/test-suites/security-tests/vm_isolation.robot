# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Validates that individual VM failures are isolated and do not impact
...                 the availability, performance, or security of other VMs or the host system.
Test Tags           vm-isolation  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/service_keywords.resource

Suite Setup         Switch to vm   ${NET_VM}
Suite Teardown      Ensure Robot sudoers is installed in all VMs   skip_boot_check=True


*** Test Cases ***

Stopping one VM does not affect others
    [Documentation]     Run application in some VM, stop another VM and check
    ...                 that it doesn't affect the first VM and app running
    [Tags]              SP-T286
    [Template]          Stopping one VM does not affect another
    ${Slack}           ${BUSINESS_VM}
    ${App Store}       ${CHROME_VM}
    ${Gala}            ${MEDIA_VM}
    ${Google Chrome}   ${COMMS_VM}


*** Keywords ***

Stopping one VM does not affect another
    [Arguments]     ${app_key}   ${another_vm}
    Should Not Be Equal       ${app_key}[VM]    ${another_vm}    App is running in the VM that is going to be stopped
    Start App in VM           ${app_key}   always_check_vm=True
    Stop VM                   ${another_vm}
    ${state}  ${substate}     Verify service status  service=microvm@${app_key}[VM].service  expected_state=active  expected_substate=running
    Check that App is running in VM     ${app_key}   range=5
    [Teardown]    Run Keywords   Restart VM   ${another_vm}   start_only=True   restore_sudoers=False
    ...                    AND   Kill App in VM   ${app_key}   log_file=${APP_OUTPUT_FILE}   status=${KEYWORD_STATUS}

Stop VM
    [Documentation]         Try to stop VM and verify it stopped
    [Arguments]             ${vm}
    Switch to vm            ${HOST}
    Log                     Going to stop ${vm}    console=True
    Run Command             systemctl stop microvm@${vm}.service  sudo=True  timeout=120
    Sleep    3
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=inactive  expected_substate=dead
    Log                     ${vm} is ${substate}    console=True
