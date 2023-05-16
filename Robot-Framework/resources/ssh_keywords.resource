*** Settings ***
Library             SSHLibrary
Resource            ../config/variables.robot
Library             BuiltIn
Library             String
Library             Process
Library             ../lib/output_parser.py

*** Variables ***
${target_login_output}   ghaf@ghaf-host

*** Keywords ***
Ping Host
    [Arguments]    ${hostname}
    [Documentation]    Ping the given hostname once and return boolen result
    ${ping_output}=    Run Process   ping ${hostname} -c 1   shell=True
    ${ping_success}    Run Keyword And Return Status    Should Contain    ${ping_output.stdout}    1 received
    Return From Keyword    ${ping_success}

Connect
    [Documentation]   Set up the SSH connection to the device
    Open Connection   ${DEVICE_IP_ADDRESS}
    ${output}=        Login     username=${LOGIN}    password=${PASSWORD}
    Should Contain    ${output}    ${target_login_output}

Verify Systemctl status
    [Arguments]    ${range}=20
    [Documentation]    Check is systemctl running with given loop ${range}
    Connect
    FOR    ${i}    IN RANGE    ${range}
        ${output}=    Execute Command    systemctl status
        ${status}=    Get Systemctl Status    ${output}
        ${result} =    Run Keyword And Return Status    Should Be Equal     ${status}    running
        IF    ${result}    BREAK
        Sleep    1
    END
    Log To Console   Systemctl status is ${status}
    IF    ${result}==False    FAIL    Systemctl is not running! Status is ${status}
    [Teardown]       Close Connection