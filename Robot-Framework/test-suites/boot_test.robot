*** Settings ***
Documentation       Testing target device booting up.
Force Tags          ssh_boot_test
Library             ../lib/TapoP100/tapo_p100.py
Resource            ../resources/serial_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}

*** Variables ***
${connection_type}       ssh
${is_available}          False

*** Test Cases ***

Verify booting after restart by power
    [Tags]    boot  plug
    [Documentation]    Restart device by power and verify systemctl status is running
    Reboot Device
    Check If Device Is Up
    IF    ${is_available} == False
        FAIL    The device did not start
    ELSE
        Log To Console  The device started
    END

    IF  "${connection_type}" == "ssh"
        Verify Systemctl status
    ELSE IF  "${connection_type}" == "serial"
        Verify Systemctl status via serial
    END


*** Keywords ***

Check If Device Is Up
    [Arguments]    ${range}=20
    ${start_time}=    Get Time	epoch
    FOR    ${i}    IN RANGE    ${range}
        ${ping}=    Ping Host   ${DEVICE_IP_ADDRESS}
        IF    ${ping}
            Set Global Variable    ${is_available}       True
            BREAK
        END
    END
    ${stop_time}=    Get Time	epoch

    ${diff}=     Evaluate    ${stop_time} - ${start_time}
    IF  ${is_available}    Log To Console    Device woke up after ${diff} sec.

    IF    ${ping}==False
        Log To Console    Device is not available after reboot via SSH, waited for ${diff} sec!
        IF  "${SERIAL_PORT}" == "NONE"
            Log To Console    There is no address for serial connection
        ELSE
            Check Serial Connection
        END
    END

Reboot Device
    [Arguments]    ${delay}=5
    [Documentation]    Turn off power of devicee, wait for given amount of seconds and turn on the power
    Log To Console    ${\n}Turning device off...
    Turn Plug Off
    Sleep    ${delay}
    Log To Console    Turning device on...
    Turn Plug On

