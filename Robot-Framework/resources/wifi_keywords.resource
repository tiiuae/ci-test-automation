# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Configure wifi
    [Arguments]         ${SSID}  ${passw}
    [Timeout]    2min
    Switch to vm        ${NET_VM}
    Log To Console      Configuring Wifi
    Set Log Level       NONE
    ${output}           Run Command    nmcli dev wifi connect ${SSID} password ${passw}   return=out,err,rc   sudo=True
    Set Log Level       INFO
    Log                 ${output}

Remove Wifi configuration
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log To Console      Removing Wifi configuration
    Run Command         nmcli connection delete id ${SSID}  sudo=True

Turn OFF WiFi
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log To Console      Turning off Wifi
    Run Command         nmcli con down id ${SSID}   sudo=True

Turn ON WiFi
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log To Console      Turning on Wifi
    Run Command         nmcli con up id ${SSID}    sudo=True

Get Wifi Interface name
    ${if_name}     Run Command    nmcli device status | grep wifi | head -n 1 | awk '{print $1}'
    RETURN         ${if_name}

Get Ethernet Interface name
    ${if_name}     Run Command    nmcli device status | grep eth | head -n 1 | awk '{print $1}'
    RETURN         ${if_name}

Get wifi IP
    [Documentation]     Parse ifconfig output and looks for wifi IP
    ${if_name}     Get Wifi Interface name
    ${is_ready}    Set Variable    False
    FOR    ${i}    IN RANGE    20
        ${output}     Run Command      ifconfig
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

Verify nmcli device status
    [Documentation]    Check state of the interface in the output of `nmcli device status`
    ...                and compare with expected: connected | disconnected | absent
    [Arguments]        ${if_name}    ${expected}    ${range}=20
    Switch to vm  ${NET_VM}
    FOR    ${i}    IN RANGE    ${range}
        ${output}          Run Command      nmcli device status

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
