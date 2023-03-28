*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
Library             BuiltIn
Library             String
Library             SSHLibrary
Library             Process
Library             ../lib/ssh_client.py
Library             ../lib/TapoP100/tapo_p100.py
Resource            ../config/variables.robot
Suite Setup         Set Device Variables   ${DEVICE}

*** Variables ***
${target_login_output}   ghaf@ghaf-host


*** Test Cases ***
Check Systemctl Status
    [Documentation]     Check if systemctl status is running
    [Tags]    boot
    [Setup]          Connect
    Verify Systemctl status     range=5
    [Teardown]       Close Connection

Verify booting after restart by power
    [Tags]    boot  plug
    [Documentation]    Restart device by power and verify systemctl status is running

    Log To Console    Turn plug OFF
    Turn Plug Off
    Check If Device Is Down

    Log To Console    Turn plug ON
    Turn Plug On
    Check If Device Is Up
    Connect

    Verify Systemctl status

    [Teardown]       Close Connection


*** Keywords ***

Connect
    [Documentation]   Set up the SSH connection to the device

    Open Connection   ${DEVICE_IP_ADDRESS}
    ${output}=        Login     username=${LOGIN}    password=${PASSWORD}
    Log To Console    ${output}
    Should Contain    ${output}    ${target_login_output}

Verify Systemctl status
    [Arguments]    ${range}=15
    [Documentation]    Check is systemctl running with given loop ${range}
    FOR    ${i}    IN RANGE    ${range}
        ${output}=    Execute Command    systemctl status
        ${status}=    Get Systemctl Status    ${output}
        ${result} =    Run Keyword And Return Status    Should Be Equal     ${status}    running
        IF    ${result}    BREAK
        Sleep    1
    END
    Log To Console    Systemctl status is ${status}
    IF    ${result}==False    FAIL    systemctl is not running!

Ping Host
    [Arguments]    ${hostname}
    ${ping_output}=    Run Process   ping ${hostname} -c 1   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Check If Device Is Down
    [Arguments]    ${range}=50
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}==False   BREAK
        Sleep    1
    END
    IF    ${ping}    FAIL    Device did not shut down!

Check If Device Is Up
    [Arguments]    ${range}=50
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}   BREAK
        Sleep    1
    END
    IF    ${ping}==False    FAIL    Device did not wake!