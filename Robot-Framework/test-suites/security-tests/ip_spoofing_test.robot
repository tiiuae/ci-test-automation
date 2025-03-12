# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../../config/variables.robot
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/common_keywords.resource

*** Variables ***
${connection}
${ip_server}

*** Test Cases ***

Test IP spoofing
    [Documentation]   Test if it's possible to steal packets via ip spoofing
    [Tags]            SP-T128   lenovo-x1   dell-7330   ipspoofing
    Set Suite Variable                ${server_vm}   ${GALA_VM}
    Set Suite Variable                ${client_vm}   ${COMMS_VM}
    Set Suite Variable                ${stealer_vm}  ${CHROME_VM}
    Prepare netcat server script
    Prepare netcat client script
    Prepare netcat stealer script
    Launch netcat test script         ${server_vm}   nc_server
    Launch netcat test script         ${client_vm}   nc_client
    Launch netcat test script         ${stealer_vm}  nc_stealer
    Log To Console                    Waiting 40 sec for the test to finish
    Sleep                             40
    Check the result files
    Close All Connections


*** Keywords ***

Prepare netcat server script
    Connect to VM                     ${server_vm}
    ${ip_server}                      Get Virtual Network Interface IP
    Set Suite Variable                ${ip_server}  ${ip_server}
    Put File                          security-tests/nc_server   /tmp
    Execute Command                   chmod 777 /tmp/nc_server

Prepare netcat client script
    Connect to VM                     ${client_vm}
    Put File                          security-tests/nc_client   /tmp
    Execute Command                   echo 'ip_server=${ip_server}' > /tmp/tmp_file
    Execute Command                   cat /tmp/nc_client >> /tmp/tmp_file
    Execute Command                   cp /tmp/tmp_file /tmp/nc_client
    Execute Command                   chmod 777 /tmp/nc_client

Prepare netcat stealer script
    Connect to VM                     ${stealer_vm}
    ${ip_stealer}                     Get Virtual Network Interface IP
    Put File                          security-tests/nc_stealer   /tmp
    Execute Command                   echo 'ip_server=${ip_server}\nip_stealer=${ip_stealer}' > /tmp/tmp_file
    Execute Command                   cat /tmp/nc_stealer >> /tmp/tmp_file
    Execute Command                   cp /tmp/tmp_file /tmp/nc_stealer
    Execute Command                   chmod 777 /tmp/nc_stealer

Launch netcat test script
    [Arguments]                       ${vm}  ${script_name}
    Connect to VM                     ${vm}
    Run Keyword And Ignore Error      Execute Command  -b /tmp/${script_name}  sudo=True  sudo_password=${PASSWORD}  timeout=3

Check the result files
    Connect to VM                     ${stealer_vm}
    ${stolen}                         Execute Command    cat /tmp/stolen.txt | grep packet
    Log                               ${stolen}
    ${stealer_log}                    Execute Command    cat /tmp/stolen.txt
    Log                               ${stealer_log}
    Connect to VM                     ${server_vm}
    ${server_received}                Execute Command    cat /tmp/server_received.txt | grep packet
    Log                               ${server_received}
    ${server_log}                     Execute Command    cat /tmp/server_received.txt
    Log                               ${server_log}
    IF  $stolen != '${EMPTY}'
        FAIL    Stealer VM managed to receive packets via ip spoofing
    END
    IF  $server_received == '${EMPTY}' and $stolen == '${EMPTY}'
        FAIL    No packets received by server or stealer VM
    END
