*** Settings ***
Library             SerialLibrary    encoding=ascii
Resource            ../config/variables.robot
Library             BuiltIn
Library             String
Library             ../lib/output_parser.py

*** Keywords ***
Open Serial Port
    Add Port   ${SERIAL_PORT}
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1

Check Serial Connection
    [Documentation]    Check if device is available by serial
    Open Serial Port
    FOR    ${i}    IN RANGE    200
        Write Data    ${\n}
        ${output} =    SerialLibrary.Read Until
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ghaf
        IF    ${status}    BREAK
        Log To Console    ${output}
        Sleep   1
    END
    Delete All Ports
    IF    ${status}
        Log To Console    Device is available via serial
        Set Global Variable    ${connection_type}    serial
        Set Global Variable    ${is_available}       True
    ELSE
        Log To Console    Device is not available via serial
    END

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