# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Gui-vm
Force Tags          gui-vm  regression

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Setup          Switch to vm    ${GUI_VM}  user=${USER_LOGIN}


*** Test Cases ***

Start Falcon AI
    [Documentation]   Start Falcon AI and verify process started
    [Tags]            SP-T223  falcon_ai  lenovo-x1  darter-pro
    Get Falcon LLM Name
    Start application  "Falcon AI"
    Wait Until Falcon Download Complete
    Check that the application was started    alpaca    range=20

    ${answer}  Ask the question     2+2=? Return just the number.
    Should Be Equal As Integers     ${answer}   4
    [Teardown]  Kill App in VM   ${GUI_VM}   alpaca

Check user systemctl status
    [Documentation]   Verify systemctl status --user is running
    [Tags]            SP-T260  systemctl  pre-merge  bat  lenovo-x1  darter-pro  dell-7330  fmo

    ${known_issues}=    Create List
    # Add any known failing services here with the target device and bug ticket number.
    # ...    device|service-name|ticket-number

    Run Keyword And Ignore Error   Verify Systemctl status    range=3   user=True
    Log    ${failed_units}

    # Filter out Cosmic Initial Setup (we kill it at the beginning of the tests)
    ${filtered_failed_units}    Evaluate   [u for u in ${failed_units} if "app-com.system76.CosmicInitialSetup@autostart.service" not in u]
    Log   ${filtered_failed_units}

    IF    ${filtered_failed_units}
        Check systemctl status for known issues  ${DEVICE}  ${known_issues}  ${filtered_failed_units}   user=True
    END


*** Keywords ***

Get Falcon LLM Name
    ${output}            Execute Command     cat '/run/current-system/sw/share/applications/Falcon AI.desktop'
    ${line}              Get Lines Containing String  ${output}  Exec=
    ${path}              Set Variable  ${line[5:]}
    ${llm_name_raw}      Execute Command  cat ${path} | grep LLM_NAME | head -n 1
    # LLM_NAME="falcon3:10b" -> falcon3:10b
    ${tmp}               Fetch From Right  ${llm_name_raw}  =
    ${LLM_NAME}          Set Variable  ${tmp[1:-1]}
    Set Global Variable  ${LLM_NAME}

Wait Until Falcon Download Complete
    FOR  ${i}  IN RANGE   100
        ${output}          Execute Command  ollama list
        ${download_done}   Run Keyword And Return Status  Should contain   ${output}  ${LLM_NAME}
        IF  ${download_done}  BREAK
        Sleep  3
    END

Ask the question
    [Arguments]      ${question}
    Log              Asking AI: ${question}  console=True
    Execute Command  script -q -c 'ollama run falcon3:10b "${question}" > result.txt'     return_stderr=True    timeout=60
    ${answer}        Execute Command  cat result.txt
    Log              The answer is: ${answer}  console=True
    RETURN           ${answer}