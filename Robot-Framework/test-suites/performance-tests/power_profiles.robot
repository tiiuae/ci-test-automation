# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing power consumption with different power profiles on Lenovo-X1
Force Tags          power-profiles  performance  lenovo-x1  lab-only

Resource            ../../resources/gui_keywords.resource
Resource            ../../resources/gui-vm_keywords.resource
Resource            ../../resources/measurement_keywords.resource
Resource            ../../resources/setup_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Library             ../../lib/output_parser.py
Library             JSONLibrary

*** Variables ***
${POWERSAVE_LIMIT}           10000
${ORIGINAL_POWER_PROFILE}    ${EMPTY}


*** Test Cases ***

Power consumption with different power profiles
    [Documentation]   Measure power consumption with different power profiles.
    ...               Confirm that consumption on powersave < balanced < performance.
    ...               Confirm that consumption on powersave < ${POWERSAVE_LIMIT}.
    [Tags]            SP-T337
    [Setup]           Test Setup
    [Teardown]        Test Teardown

    Start power measurement  ${BUILD_ID}   timeout=1500
    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}

    Wait   30

    ${powersave_power}     Measure power consumption of a power profile   gui-powersave
    ${balanced_power}      Measure power consumption of a power profile   gui-balanced
    ${performance_power}   Measure power consumption of a power profile   gui-performance

    Generate power plot    ${BUILD_ID}   Powersave-Balanced-Performance
    Stop recording power

    Should Be True   ${powersave_power} < ${balanced_power} < ${performance_power}
    Should Be True   ${powersave_power} < ${POWERSAVE_LIMIT}

*** Keywords ***

Test Setup
    [Timeout]   5 minutes
    ${availability}   Check variable availability  RPI_IP_ADDRESS
    IF  ${availability}==False   SKIP   Power measurement agent IP address not defined. Skipping the test
    Prepare Test Environment
    Stop swayidle
    ${active_profile}    Get active power profile
    Set Suite Variable   ${ORIGINAL_POWER_PROFILE}   ${active_profile}

Test Teardown
    Set brightness       100%
    Set power profile    ${ORIGINAL_POWER_PROFILE}
    Log out from laptop

Measure power consumption of a power profile
    [Documentation]      Measure power consumption with a ${profile} and return average consumption
    [Arguments]          ${profile}

    Set power profile    ${profile}
    Set brightness       100%

    Wait                 15
    Set timestamp        starttime
    Wait                 60
    Set timestamp        endtime

    Get power record     ${BUILD_ID}.csv
    ${average_power}     Calculate average power over interval   ${BUILD_ID}   ${starttime}   ${endtime}
    Log                  Average power with ${profile} was ${average_power}   console=True
    RETURN               ${average_power}

Set power profile
    [Documentation]     Set power profile to ${profile}
    [Arguments]         ${profile}
    [Setup]             Switch to vm   ${GUI_VM}
    Log                 Setting power profile to ${profile}   console=True
    Execute Command     tuned-adm profile ${profile}   sudo=True  sudo_password=${PASSWORD}
    ${active_profile}   Get active power profile
    Should Contain      ${active_profile}   ${profile}

Get active power profile
    [Documentation]     Return active power profile
    ${output}           Execute Command   tuned-adm active
    ${parts}            Split String    ${output}    : 
    ${active_profile}   Strip String    ${parts}[1]
    Log                 Active power profile is ${active_profile}   console=True
    RETURN              ${active_profile}
