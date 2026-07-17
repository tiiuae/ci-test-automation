# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../resources/ssh_keywords.resource

*** Keywords ***

Configure wifi
    [Arguments]         ${SSID}  ${passw}
    Switch to vm        ${NET_VM}
    Wait Until Keyword Succeeds     10x   1s   Scan for Wifi   ${SSID}
    Log To Console      Configuring Wifi
    Wait Until Keyword Succeeds   3x   1s   Try to connect wifi   ${SSID}  ${passw}

Try to connect wifi
    [Arguments]         ${SSID}  ${passw}
    [Timeout]    2min
    Set Log Level       NONE
    ${output}           Run Command    nmcli dev wifi connect ${SSID} password ${passw}   return=out,err,rc   sudo=True   rc_match=skip
    Set Log Level       INFO
    # Log output and check return code without revealing sensitive information
    Log                 ${output}
    Should Be Equal As Integers        ${output}[2]  0   Configuring wifi failed with ${output}[0] \nReturn code: ${output}[2], expected: 0 \nError: ${output}[1] \n

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

Scan for Wifi
    [Arguments]         ${SSID}
    Switch to vm        ${NET_VM}
    Log                 Scanning for ${SSID}   console=True
    ${output}           Run Command   nmcli dev wifi list --rescan yes   sudo=True
    Should Contain      ${output}   ${SSID}

Get wifi IP
    [Documentation]     Parse ifconfig output and looks for wifi IP
    ${if_name}     Get Interface name    wifi
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

Get gateway
    [Documentation]     Parse route table and return gateway for the default route of selected interface type
    [Arguments]         ${interface}=wifi
    ${if_name}          Get Interface name   ${interface}
    ${output}           Run Command          route -n
    ${pattern}          Set Variable         (?m)^0\\.0\\.0\\.0\\s+(\\S+)\\s+.*\\s${if_name}\\s*$
    @{matches}          Get Regexp Matches   ${output}    ${pattern}    1
    Should Not Be Empty    ${matches}    Could not find gateway for interface ${if_name} in route table
    ${gateway}          Get From List        ${matches}    0
    Log                 ${interface} gateway is ${gateway}    console=True
    RETURN              ${gateway}

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
