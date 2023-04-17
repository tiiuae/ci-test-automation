*** Settings ***
Documentation       Testing target device booting up after power brake.Using wi-fi power plug for braking power and USB serial port console to verify Spectrum OS booting up.
Force Tags          tc_boot_test
Library             BuiltIn
Library             String
Library             SerialLibrary    encoding=ascii
Library             ../lib/TapoP100/tapo_p100.py
Test Setup          Open Serial Port
Test Teardown       Delete All Ports

*** Variables ***
${IP_ADDRESS}       172.18.16.30
${LOGIN_USERNAME}   UserName
${LOGIN_PASSWORD}   Password
${PLUG_USERNAME}    UserName
${PLUG_PASSWORD}    Password
${WRITE_DATA}       systemctl status
${TARGET_OUTPUT}    running
${TARGET_OUTPUT2}   ghaf-host login
${TARGET_OUTPUT3}   Password
${TARGET_OUTPUT4}   @ghaf-host


*** Test cases ***
Verify USB Serial Port Connection
    [Tags]    openSerialconnection
    [Documentation]    Verifies USB connection by chekking systemctl status from target device.
    Verify Systemctl status    5

Boot NUC with WiFi Plug And Verify Boot
    [Tags]    bootNUC
    [Documentation]
    Log To Console    Turn plug OFF
    Turn Plug Off
    FOR    ${i}    IN RANGE    50
        Write Data    ls -la${\n}
        ${output} =    Read Until    terminator=ghaf users
        ${status} =    Run Keyword And Return Status    Should Contain    ${output}    ghaf users
        IF    ${status}==False   BREAK
    END
    IF    ${status}    FAIL    Device did not shut down!

    Log To Console    Turn plug ON
    Turn Plug On
    Log In To Ghaf OS
    Verify Systemctl status    50

*** Keywords ***
Verify Systemctl status
    [Arguments]    ${range}
    [Documentation]    Check is systemctl running with given loop ${range}
    FOR    ${i}    IN RANGE    ${range}
        Write Data    ${WRITE_DATA}${\n}
        ${output} =    Read Until    terminator=${TARGET_OUTPUT}
        # write ctrl+c to stop reading status
        Write Data    \x03${\n}
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ${TARGET_OUTPUT}
        IF    ${status}    BREAK
    END
    Log To Console    ${output}
    IF    ${status}==False    FAIL    systemctl is not running!

Log In To Ghaf OS
    [Documentation]    Log in with ${LOGIN_USERNAME} and ${LOGIN_PASSWORD}
    FOR    ${i}    IN RANGE    100
        Write Data    ${\n}
        ${output} =    Read Until    terminator=${TARGET_OUTPUT2}
        ${status} =    Run Keyword And Return Status    Should contain    ${output}    ${TARGET_OUTPUT2}
        IF    ${status}    BREAK
    END
    IF    ${status}    Write Data    ${LOGIN_USERNAME}${\n}
    ${output} =    Read Until    terminator=${TARGET_OUTPUT3}
    Should contain    ${output}    ${TARGET_OUTPUT3}
    Write Data    ${LOGIN_PASSWORD}${\n}
    ${output} =    Read Until    terminator=${TARGET_OUTPUT4}
    Should contain    ${output}    ${TARGET_OUTPUT4}

Open Serial Port
    Add Port   /dev/ttyUSB0
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1
