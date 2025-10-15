# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../../resources/ssh_keywords.resource
Force Tags          security    regression
Test Timeout        3 minutes


*** Variables ***
${connection}
${ip_server}


*** Test Cases ***

Test IP spoofing
    [Tags]            SP-T128  ipspoofing  lenovo-x1  dell-7330  darter-pro
    Set Suite Variable      ${file_path}   /home/appuser/'Unsafe share'
    Set Suite Variable      ${server_vm}   ${BUSINESS_VM}
    Set Suite Variable      ${client_vm}   ${COMMS_VM}
    Set Suite Variable      ${stealer_vm}  ${CHROME_VM}
    Test IP spoofing


*** Keywords ***

Test IP spoofing
    [Documentation]   Test if it's possible to steal packets via ip spoofing
    Prepare netcat server script
    Prepare netcat client script
    Prepare netcat stealer script
    Launch netcat test script       ${server_vm}   nc_server
    Launch netcat test script       ${client_vm}   nc_client
    Launch netcat test script       ${stealer_vm}  nc_stealer

    # When nc_stealer script starts to flip IP address ssh connection can get stuck. Drop all connections.
    Close All Connections

    Log To Console                  Waiting 50 sec for the test to finish   no_newline=true
    FOR    ${i}    IN RANGE    10
        Log To Console   .  no_newline=true
        Sleep       5
    END

    Connect
    Check the result files
    [Teardown]                      Spoofing Test Teardown

Prepare netcat server script
    Switch to vm                      ${server_vm}
    ${ip_server}                      Get Virtual Network Interface IP
    Set Suite Variable                ${ip_server}  ${ip_server}
    Put File                          security-tests/nc_server   /tmp
    Execute Command                   cp /tmp/nc_server ${file_path}   sudo=True  sudo_password=${PASSWORD}
    Execute Command                   chmod 777 ${file_path}/nc_server   sudo=True  sudo_password=${PASSWORD}

Prepare netcat client script
    Switch to vm                      ${client_vm}
    Put File                          security-tests/nc_client   /tmp
    Execute Command                   echo 'ip_server=${ip_server}' > /tmp/tmp_file
    Execute Command                   cat /tmp/nc_client >> /tmp/tmp_file
    Execute Command                   cp /tmp/tmp_file ${file_path}/nc_client  sudo=True  sudo_password=${PASSWORD}
    Execute Command                   chmod 777 ${file_path}/nc_client  sudo=True  sudo_password=${PASSWORD}

Prepare netcat stealer script
    Switch to vm                      ${stealer_vm}
    ${ip_stealer}                     Get Virtual Network Interface IP
    Put File                          security-tests/nc_stealer   /tmp
    Execute Command                   echo 'ip_server=${ip_server}\nip_stealer=${ip_stealer}' > /tmp/tmp_file
    Execute Command                   cat /tmp/nc_stealer >> /tmp/tmp_file
    Execute Command                   cp /tmp/tmp_file ${file_path}/nc_stealer  sudo=True  sudo_password=${PASSWORD}
    Execute Command                   chmod 777 ${file_path}/nc_stealer  sudo=True  sudo_password=${PASSWORD}

Launch netcat test script
    [Arguments]                       ${vm}  ${script_name}
    Switch to vm                      ${vm}
    Run Keyword And Ignore Error      Execute Command  -b ${file_path}/${script_name} ${file_path}  sudo=True  sudo_password=${PASSWORD}  timeout=2

Check the result files
    Switch to vm                      ${GUI_VM}
    ${stealer_log}                    Execute Command    cat /Shares/'Unsafe ${stealer_vm} share'/stolen.txt  sudo=True  sudo_password=${PASSWORD}
    Log                               ${stealer_log}
    ${stolen}                         Execute Command    cat /Shares/'Unsafe ${stealer_vm} share'/stolen.txt | grep packet  sudo=True  sudo_password=${PASSWORD}
    Log                               ${stolen}
    ${server_log}                     Execute Command    cat /Shares/'Unsafe ${server_vm} share'/server_received.txt  sudo=True  sudo_password=${PASSWORD}
    Log                               ${server_log}
    ${server_received}                Execute Command    cat /Shares/'Unsafe ${server_vm} share'/server_received.txt | grep packet  sudo=True  sudo_password=${PASSWORD}
    Log                               ${server_received}
    IF  $stealer_log == '${EMPTY}' or $server_log == '${EMPTY}'
        FAIL    Server and/or stealer script was not able to write to output file. Test might be broken.
    END
    IF  $stolen != '${EMPTY}'
        FAIL    Stealer VM managed to receive packets via ip spoofing
    END
    IF  $server_received == '${EMPTY}' and $stolen == '${EMPTY}'
        FAIL    No packets received by server or stealer VM. Test might be broken.
    END

Spoofing Test Teardown
    [Documentation]   Switching of IP address can make stealer VM inaccessible for further tests.
    ...               Restart the stealer vm.
    Switch to vm   ${HOST}
    Execute Command         systemctl restart microvm@${stealer_vm}.service  sudo=True  sudo_password=${PASSWORD}
    Close All Connections