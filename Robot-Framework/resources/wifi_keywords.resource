# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Configure wifi
    [Arguments]         ${SSID}  ${passw}
    Switch to vm        ${NET_VM}
    Log To Console      Configuring Wifi
    Set Log Level       NONE
    Execute Command     nmcli dev wifi connect ${SSID} password ${passw}   sudo=True    sudo_password=${PASSWORD}
    Set Log Level       INFO

Remove Wifi configuration
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log To Console      Removing Wifi configuration
    ${stdout}  ${stderr}  ${rc}=  Execute Command  nmcli connection delete id ${SSID}
    ...   sudo=True   sudo_password=${PASSWORD}   return_stdout=True   return_stderr=True   return_rc=True
    Should Be Equal As Integers    ${rc}    0

Turn OFF WiFi
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log To Console      Turning off Wifi
    Execute Command     nmcli con down id ${SSID}   sudo=True    sudo_password=${PASSWORD}

Turn ON WiFi
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log To Console      Turning on Wifi
    Execute Command     nmcli con up id ${SSID}    sudo=True    sudo_password=${PASSWORD}

Get Wifi Interface name
    ${if_name}     Execute Command    nmcli device status | grep wifi | head -n 1 | awk '{print $1}'
    RETURN         ${if_name}

Get Ethernet Interface name
    ${if_name}     Execute Command    nmcli device status | grep eth | head -n 1 | awk '{print $1}'
    RETURN         ${if_name}

Get wifi IP
    [Documentation]     Parse ifconfig output and looks for wifi IP
    ${if_name}     Get Wifi Interface name
    ${is_ready}    Set Variable    False
    FOR    ${i}    IN RANGE    20
        ${output}     Execute Command      ifconfig
        Log           ${output}
        ${ip}         Get ip from ifconfig    ${output}   ${if_name}
        ${status}     Run Keyword And Return Status    Should Not Be Equal As Strings    ${ip}    None
        IF  ${status}
            Log To Console     Ip is ${ip}
            ${is_ready} =  Set Variable    True
            BREAK
        END
        Sleep    1
    END
    IF   ${status} == False    FAIL    NetVM hasn't gotten an IP

Block WLAN
    Switch to vm  ${HOST}
    ${output}     Execute Command      ghaf-killswitch block net    sudo=True    sudo_password=${PASSWORD}
    Switch to vm  ${NET_VM}

Unblock WLAN
    Switch to vm  ${HOST}
    ${output}     Execute Command      ghaf-killswitch unblock net    sudo=True    sudo_password=${PASSWORD}
    Switch to vm  ${NET_VM}

Verify nmcli device status
    [Documentation]    Check state of the interface in the output of `nmcli device status`
    ...                and compare with expected: connected | disconnected | absent
    [Arguments]        ${if_name}    ${expected}
    FOR    ${i}    IN RANGE    20
        ${output}          Execute Command      nmcli device status
        Log     ${output}

        # Format nmcli: DEVICE  TYPE  STATE  CONNECTION
        ${pattern}         Set Variable    (?m)^${if_name}\\s+\\S+\\s+(\\S+)

        @{matches}         Get Regexp Matches    ${output}    ${pattern}    1
        ${count}           Get Length    ${matches}

        IF    ${count} == 0
            ${actual}      Set Variable    absent
        ELSE
            ${actual}       Get From List    ${matches}    0
        END

        ${status}     Run Keyword And Return Status    Should Be Equal    ${actual}    ${expected}
        IF   ${status} == True    BREAK
        Sleep    0.5
    END
    IF   ${status} == False    FAIL    Expected nmcli device status: ${expected}, actual: ${actual}
