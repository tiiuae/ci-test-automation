# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing Network VM
Force Tags          netvm
Resource            ../resources/ssh_keywords.resource
Resource            ../config/variables.robot
Suite Setup         Set Variables   ${DEVICE}
Suite Teardown      Close All Connections


*** Variables ***
${netvm_ip}        192.168.101.1
${SSID}            test_network
${wifi_pswd}       test1234
${netwotk_ip}      192.168.1.1


*** Test Cases ***

Verify NetVM is started
    [Documentation]         Verify thet NetVM is active and running
    [Tags]                  bat   SP-T49
    Verify service status   service=${netvm_service}
    Ping                    host=${netvm_ip}  expected_result=True  range=5
    [Teardown]              Close All Connections

Wifi passthrought into NetVM
    [Documentation]         Verify thet wifi works inside netvm
    [Tags]                  bat   SP-T50
    ${host}  ${netvm_root}  Create connections
    Switch Connection	    ${netvm_root}
    Configure wifi          ${SSID}   ${wifi_pswd}
    Ping                    expected_result=True
    Switch Connection	    ${host}
    Ping                    expected_result=False
    [Teardown]              Remove Wifi configuration  ${netvm_root}


*** Keywords ***

Create connections
    ${host}=	    Open Connection    ${DEVICE_IP_ADDRESS}
    Login           username=${LOGIN}  password=${PASSWORD}
    ${netvm_root}=	Open Connection    ${DEVICE_IP_ADDRESS}
    Login           username=${LOGIN}  password=${PASSWORD}
    Login into NetVM
    [Return]        ${host}  ${netvm_root}

Login into NetVM
    Write       ssh-keygen -R ${netvm_ip}
    Write       ssh ${LOGIN}@${netvm_ip}
    ${output}=	Read	delay=0.5s
    ${fingerprint}    Run Keyword And Return Status    Should Contain    ${output}     fingerprint
    IF    ${fingerprint}
        Write         yes
    END
    ${output}=	Read	delay=0.5s
    ${passw}    Run Keyword And Return Status    Should Contain    ${output}     Password
    IF    ${passw}
        Write         ${PASSWORD}
        Read Until    ghaf@netvm
    END
    Write         sudo su
    Read Until    password
    Write         ${PASSWORD}
    Read Until    root@netvm

Configure wifi
    [Arguments]   ${SSID}  ${passw}
    Write         wpa_passphrase ${SSID} ${passw} > /etc/wpa_supplicant.conf
    Write         systemctl restart wpa_supplicant.service
    Read Until    @netvm

Ping
    [Arguments]            ${host}=${netwotk_ip}  ${expected_result}=True  ${range}=5
    Set Global Variable    ${is_available}   False
    FOR   ${i}   IN RANGE  ${range}
        Write    ping ${host} -c 1
        TRY
            Read Until           1 received
            Set Global Variable  ${is_available}  True
            BREAK
        EXCEPT
            CONTINUE
        END
    END
    IF    ${is_available} != ${expected_result}
        FAIL    Expected availability of ${host}: ${expected_result}, in fact: ${is_available}
    END

Remove Wifi configuration
    [Arguments]         ${netvm_root}
    Switch Connection   ${netvm_root}
    Write               rm /etc/wpa_supplicant.conf
    Read Until          @netvm
    Write               systemctl restart wpa_supplicant.service
    Read Until          @netvm
    [Teardown]          Close All Connections
