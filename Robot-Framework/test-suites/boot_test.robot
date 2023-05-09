*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
Library             BuiltIn
Library             String
Library             SSHLibrary
Library             SerialLibrary    encoding=ascii
Library             Process
Library             ../lib/ssh_client.py
Library             ../lib/TapoP100/tapo_p100.py
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}

*** Variables ***
${target_login_output}   ghaf@ghaf-host
${LOGIN}                 ${EMPTY}
${PASSWORD}              ${EMPTY}


*** Test Cases ***

Verify booting after restart by power
    [Tags]    boot  plug
    [Documentation]    Restart device by power and verify systemctl status is running

    Reboot Device
    Check If Device Is Up
    Connect

    Verify Systemctl status

    [Teardown]       Close Connection


*** Keywords ***

Connect
    [Documentation]   Set up the SSH connection to the device

    Open Connection   ${DEVICE_IP_ADDRESS}
    ${output}=        Login     username=${LOGIN}    password=${PASSWORD}
    Log To Console               ${output}
    Should Contain    ${output}    ${target_login_output}

Verify Systemctl status
    [Arguments]    ${range}=30
    [Documentation]    Check is systemctl running with given loop ${range}
    FOR    ${i}    IN RANGE    ${range}
        ${output}=    Execute Command    systemctl status
        ${status}=    Get Systemctl Status    ${output}
        ${result} =    Run Keyword And Return Status    Should Be Equal     ${status}    running
        IF    ${result}    BREAK
        Sleep    1
    END
    Log To Console   Systemctl status is ${status}
    IF    ${result}==False    FAIL    Systemctl is not running! Status is ${status}

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
    [Arguments]    ${range}=20
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}   BREAK
        Sleep    1
    END
    ${stop_time}=    Get Time	epoch

    IF    ${ping}==False
        ${diff}=     Evaluate    ${stop_time} - ${start_time}
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec. Reboot one more time...
        Reboot Device
        ${start_time}=    Get Time	epoch
        FOR    ${i}    IN RANGE    ${range}
            ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
            IF    ${ping}   BREAK
            Sleep    1
        END
        ${stop_time}=    Get Time	epoch
    END
    ${diff}=     Evaluate    ${stop_time} - ${start_time}
    IF    ${ping}==False
        Log To Console    Device is not available after second reboot via SSH, waited for ${diff} sec!
        Check Serial Connection
    END
    Log To Console    Device woke up for ${diff} sec.


Reboot Device
    Log To Console    ${\n}Turning device off...
    Turn Plug Off
    Sleep    5
    Log To Console    Turning device on...
    Turn Plug On

Check Serial Connection
    [Documentation]    Check if device is available by serial
    Open Serial Port
    FOR    ${i}    IN RANGE    10
        Write Data    ${\n}
        ${output} =    SerialLibrary.Read Until
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ghaf
        IF    ${status}    BREAK
    END
    IF    ${status}     Log To Console    Device is available via serial
    IF    ${status}==False    FAIL    Device is not available via serial
    Delete All Ports

Open Serial Port
    Add Port   /dev/ttyUSB0
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1