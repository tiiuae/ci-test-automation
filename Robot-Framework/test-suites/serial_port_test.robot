*** Settings ***
Documentation       Testing USB serial port console on Spectrum OS.
Force Tags          tc_usb_serial_port
Library             BuiltIn
Library             String
Library             SerialLibrary    encoding=ascii
#Library             SSHLibrary
# Test Setup          Open Serial Port

*** Variables ***
${Data}                         lsvm
${TARGET_READ}                  appvm-catgirl


*** Test cases ***
Open Serial Port Connection And Verify Connection
    [Tags]    openSerialconnection
    [Documentation]    Open USB Serial Port Connection And Verify Connection
    Open Serial Port
    Sleep    2s
    Write Data    vm-start netvm${\n}
    Sleep    2s
    Write Data    ${Data}${\n}
    ${output} =    Read Until    terminator=${TARGET_READ}
    # Should contain    ${output}    ${TARGET_READ}
    Log To Console    Console: ${output}
    [Teardown]    Delete All Ports


*** Keywords ***
Open Serial Port
    Add Port   /dev/ttyUSB0
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1
