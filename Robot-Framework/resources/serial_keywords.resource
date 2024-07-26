# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             SerialLibrary    encoding=ascii
Resource            ../config/variables.robot
Library             BuiltIn
Library             String
Library             AdvancedLogging
Library             ../lib/output_parser.py

*** Keywords ***
Open Serial Port
    [Arguments]    ${timeout}=1.0
    Add Port   ${SERIAL_PORT}
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1
    ...        timeout=${timeout}

Check Serial Connection
    [Documentation]    Check if device is available by serial
    Log To Console     Trying to connect via serial...
    Open Serial Port
    FOR    ${i}    IN RANGE    120
        Write Data    ${\n}
        ${output} =    SerialLibrary.Read Until
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ghaf
        IF    ${status}    BREAK
        Sleep   1
    END
    Delete All Ports
    IF    ${status}
        Log To Console    Device is available via serial
        Set Global Variable    ${CONNECTION_TYPE}    serial
        Set Global Variable    ${IS_AVAILABLE}       True
    ELSE
        Log To Console    Device is not available via serial
    END

Log In To Ghaf OS
    [Documentation]    Log in with ${LOGIN} and ${PASSWORD}
    Log To Console     Trying to log in via serial...
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
        IF    ${status}
            Log To Console     Successfully logged in
            BREAK
        END
    END
    IF    ${status}==False    FAIL      Console is not ready

Verify init.scope status via serial
    [Arguments]    ${range}=60
    [Documentation]    Check if init.scope service is running with given loop ${range}
    Connect via serial  timeout=10
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        Write Data    systemctl status init.scope${\n}
        ${output} =    SerialLibrary.Read Until    terminator=Units
        Write Data    \x03${\n}        # write ctrl+c to stop reading status
        ${status}  ${state}   Get Service Status    ${output}
        IF  '${state}' not in ['running', 'starting']
            Log To Console   init.scope status is ${status}
            FAIL    init.scope is not running! Status is ${state}
        ELSE IF    '${state}' == 'running'
            ${diff}=    Evaluate    int(time.time()) - int(${start_time})
            Log To Console   init.scope status is ${status}
            RETURN
        END
        Sleep    1
    END
    ${diff}=    Evaluate    int(time.time()) - int(${start_time})
    FAIL    init.scope is not running after ${diff} sec! Status is ${status}
    [Teardown]       Delete All Ports

Connect via serial
    [Arguments]     ${timeout}=1.0
    Open Serial Port     timeout=${timeout}
    Log In To Ghaf OS

Save log
    Connect via serial    timeout=60.0
    Write Data    sh -c 'journalctl | tee jrnl.txt | cat'${\n}
    ${output} =   SerialLibrary.Read Until    ghaf@ghaf-host:
    Write Advanced Testlog    journalctl.log     ${output}
    Log  ${output}
    [Teardown]    Delete All Ports

Get ethernet IP address
    Connect via serial
    Write Data    ifconfig${\n}
    ${output}     SerialLibrary.Read Until    ghaf@ghaf-host:
    ${ip}         Get ip from ifconfig    ${output}   eth0
    Set Global Variable  ${DEVICE_IP_ADDRESS}  ${ip}
    [Teardown]    Delete All Ports
