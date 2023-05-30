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

Start Chromium
    ${command}=     Set Variable    chromium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland
    Connect
    ${command_output}=    Execute Command    nohup ${command} > output.log 2>&1 &


Is process started
    [Arguments]    ${proc_name}
    ${output}=    Execute Command    ps aux
    ${pid}=       Find Pid    ${output}  ${proc_name}
    Log To Console    ${proc_name} PID: ${pid}
    [Return]      ${pid}

Kill process
    [Arguments]  ${pid}
    Execute Command    kill ${pid}
    FOR    ${i}    IN RANGE   5
        TRY
            Is Process Started    chromium
            ${ps_exists}=     Set Variable    True
            Sleep    0.5
        EXCEPT
            ${ps_exists}=     Set Variable    False
            BREAK
        END
    END
    IF     ${ps_exists}     FAIL    Process chromium haven't stopped