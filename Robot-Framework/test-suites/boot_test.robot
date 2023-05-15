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
${LOGIN}                 ${EMPTY}
${PASSWORD}              ${EMPTY}
${target_login_output}   ghaf@ghaf-host
${connection_type}       ssh
${IS_AVAILABLE}          False


*** Test Cases ***

Verify booting after restart by power
    [Tags]    boot  plug
    [Documentation]    Restart device by power and verify systemctl status is running
    Reboot Device
    FOR    ${i}    IN RANGE    1    2
        Check If Device Is Up
        IF    ${IS_AVAILABLE}    BREAK
    END
    IF    ${IS_AVAILABLE} == False
        FAIL    The device did not start after ${i} reboots
    ELSE
        Log To Console  The device started after ${i} reboot
    END

    IF  "${connection_type}" == "ssh"
        Verify Systemctl status
    ELSE IF  "${connection_type}" == "serial"
        Verify Systemctl status via serial
    END


*** Keywords ***

Connect
    [Documentation]   Set up the SSH connection to the device

    Open Connection   ${DEVICE_IP_ADDRESS}
    ${output}=        Login     username=${LOGIN}    password=${PASSWORD}
    Should Contain    ${output}    ${target_login_output}

Verify Systemctl status
    [Arguments]    ${range}=8
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

Verify Systemctl status via serial
    [Arguments]    ${range}=30
    [Documentation]    Check is systemctl running with given loop ${range}
    Open Serial Port
    Log In To Ghaf OS
    FOR    ${i}    IN RANGE    ${range}
        Write Data    systemctl status${\n}
        ${output} =    SerialLibrary.Read Until    terminator=Units
        Write Data    \x03${\n}        # write ctrl+c to stop reading status
        ${status}=    Get Systemctl Status    ${output}
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    running
        IF    ${status}    BREAK
    END
    IF    ${status}==False    FAIL    systemctl is not running! Status is ${status}

    [Teardown]       Delete All Ports

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
    [Arguments]    ${range}=15
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}
            Set Global Variable    ${IS_AVAILABLE}       True
            BREAK
        END
        Sleep    1
    END
    ${stop_time}=    Get Time	epoch

    ${diff}=     Evaluate    ${stop_time} - ${start_time}
    IF    ${ping}==False
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END
    IF  ${IS_AVAILABLE}    Log To Console    Device woke up after ${diff} sec.

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
    Delete All Ports
    IF    ${status}
        Log To Console    Device is available via serial
        Set Global Variable    ${connection_type}    serial
        Set Global Variable    ${IS_AVAILABLE}       True
    END

Open Serial Port
    Add Port   ${SERIAL_PORT}
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1

Log In To Ghaf OS
    [Documentation]    Log in with ${LOGIN} and ${PASSWORD}
    FOR    ${i}    IN RANGE    10
        Write Data    ${\n}
        ${output} =    SerialLibrary.Read Until    terminator=ghaf-host login
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ghaf-host login
        IF    ${status}
            Write Data    ${LOGIN}${\n}
            ${output} =    SerialLibrary.Read Until    terminator=Password
            Write Data    ${PASSWORD}${\n}
        END
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    @ghaf-host
        IF    ${status}    BREAK
    END
    IF    ${status}==False    FAIL      Console is not ready