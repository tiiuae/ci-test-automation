# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot


*** Keywords ***

Check that the application was started
    [Arguments]          ${app_name}  ${range}=2
    FOR   ${i}   IN RANGE  ${range}
        @{found_pids}        Find pid by name    ${app_name}
        Set Global Variable  @{app_pids}  @{found_pids}
        ${status}    Run Keyword And Return Status   Should Not Be Empty  ${app_pids}
        IF    ${status}    BREAK
        Sleep   1
    END
    Should Not Be Empty  ${app_pids}  ${app_name} is not started
    Log To Console       ${app_name} is started

Check Application Login Page
    [Documentation]  Check that application is able to connect to Internet and login page is available
    [Arguments]  ${application}=outlook
    @{browser_ids}  SeleniumLibrary.Get Browser Ids
    Log  ${browser_ids}

    ${source}  SeleniumLibrary.Get source
    Log  ${source}

    ${handles}  SeleniumLibrary.Get Window Handles
    Log  ${handles}

Check If Ping Fails
    [Documentation]  Check that ping is not getting response from host
    ${result}  Run Process  ping  ${DEVICE_IP_ADDRESS}  -c1  timeout=1s
    Should Not Be Equal   ${result.rc}  ${0}