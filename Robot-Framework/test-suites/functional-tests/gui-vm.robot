# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Gui-vm
Force Tags          gui-vm   regression

Resource            ../../resources/app_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Test Setup          Switch to vm    ${GUI_VM}  user=${USER_LOGIN}


*** Test Cases ***

Start Falcon AI
    [Documentation]   Start Falcon AI and verify process started
    [Tags]            falcon_ai  SP-T223-1  lenovo-x1  darter-pro  dell-7330
    Get Falcon LLM Name
    Start XDG application  'Falcon AI'
    Wait Until Falcon Download Complete
    Check that the application was started    alpaca    range=20

    ${answer}  Ask the question     2+2=? Return just the number.
    Should Be Equal As Integers     ${answer}   4
    [Teardown]  Run Keywords   Kill App in VM   ${GUI_VM}   AND
    ...         Run Keyword If   "Lenovo" in "${DEVICE}" or "Darter" in "${DEVICE}" or "Dell" in "${DEVICE}"
    ...         Run Keyword If Test Failed   Skip   "Known issue SSRCSP-6769: [Lenovo-X1] Falcon AI finds no models even though the model was installed"

Check user systemctl status
    [Documentation]   Verify systemctl status --user is running
    [Tags]            bat   pre-merge  SP-T260  systemctl  lenovo-x1  darter-pro  dell-7330  fmo

    ${known_issues}=    Create List
    # Add any known failing services here with the target device and bug ticket number.
    # ...    device|service-name|ticket-number

    Run Keyword And Ignore Error   Verify Systemctl status    range=3   user=True
    Log    ${failed_units}

    # Filter out Cosmic Initial Setup (we kill it at the beginning of the tests)
    ${filtered_failed_units}    Evaluate   [u for u in ${failed_units} if "app-com.system76.CosmicInitialSetup@autostart.service" not in u]
    Log   ${filtered_failed_units}

    IF    ${filtered_failed_units}
        Check systemctl status for known issues  ${known_issues}  ${filtered_failed_units}   user=True
    END


*** Keywords ***

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