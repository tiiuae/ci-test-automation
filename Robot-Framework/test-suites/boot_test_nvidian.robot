*** Settings ***
Documentation       Testing target device booting up after power brake. Using wi-fi power plug for braking power and USB serial port console to verify Spectrum OS booting up.
Force Tags          tc_boot_test_imx8
Library             BuiltIn
Library             String
Library             SerialLibrary    encoding=ascii
Library             ../lib/TapoP100/tapo_p100.py
Test Setup          Open Serial Port
Test Teardown       Delete All Ports

*** Variables ***
${IP_ADDRESS}       172.18.16.31
${USERNAME}         UserName
${PASSWORD}         Password
${Data}             lsvm
${TARGET_READ}      appvm-catgirl


*** Test cases ***
#Verify USB Serial Port Connection
    #[Tags]    openSerialconnection
    #Write Data    ${\n}
    #Write Data    ${Data}${\n}
    #${output} =    Read Until    terminator=${TARGET_READ}
    #Should contain    ${output}    ${TARGET_READ}
    #Log To Console    Console: ${output}

Boot NUC with WiFi Plug And Verify Boot
    Turn Plug Off    ${IP_ADDRESS}    ${USER_NAME}    ${PASSWORD}
    Delete All Ports
    #FOR    ${i}    IN RANGE    50
        #Write Data    ${Data}${\n}
        #${output} =    Read Until    terminator=${TARGET_READ}
        #${status} =    Run Keyword And Return Status    Should contain    ${output}    ${TARGET_READ}
        #Log To Console    ${status}
        #IF    ${status}==False   BREAK    
    #END
    #IF    ${status}     Device did not shut down!
    Sleep    2s  #wait that power turned off
    Log To Console    Turn ON
    Turn Plug On    ${IP_ADDRESS}    ${USER_NAME}    ${PASSWORD}
    Sleep    10s  #wait that power turned on
    Open Serial Port
    Set Port Parameter    timeout    120
    ${output} =    Read Until    Run /init as init process
    Log To Console    ${output}
    Set Port Parameter    timeout    5
    # FOR    ${i}    IN RANGE    100
    #     #Write Data    ${\n}
    #     Write Data    ${Data}${\n}
    #     ${output} =    Read Until    terminator=${TARGET_READ}
    #     ${status} =    Run Keyword And Return Status    Should contain    ${output}    ${TARGET_READ}
    #     Log To Console    ${status}
    #     IF    ${status}    BREAK
    # END
    # IF    ${status}==False     Device did not boot up!

*** Keywords ***
Open Serial Port
    Add Port   /dev/ttyACM0
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1

