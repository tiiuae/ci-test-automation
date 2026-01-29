# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../../resources/ssh_keywords.resource
Test Tags           ip-spoofing
Test Timeout        3 minutes


*** Variables ***
${connection}
${ip_server}


*** Test Cases ***

Test IP spoofing
    [Tags]            SP-T128  lenovo-x1  darter-pro  dell-7330
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
    Check the result files
    [Teardown]                      Spoofing Test Teardown

Prepare netcat server script
    Switch to vm                      ${server_vm}
    ${ip_server}                      Get Virtual Network Interface IP
    Set Suite Variable                ${ip_server}  ${ip_server}
    Put File                          security-tests/nc_server   /tmp
    Run Command                       cp /tmp/nc_server ${file_path}   sudo=True
    Run Command                       chmod 777 ${file_path}/nc_server   sudo=True

Prepare netcat client script
    Switch to vm                      ${client_vm}
    Put File                          security-tests/nc_client   /tmp
    Run Command                       echo 'ip_server=${ip_server}' > /tmp/tmp_file
    Run Command                       cat /tmp/nc_client >> /tmp/tmp_file
    Run Command                       cp /tmp/tmp_file ${file_path}/nc_client  sudo=True
    Run Command                       chmod 777 ${file_path}/nc_client  sudo=True

Prepare netcat stealer script
    Switch to vm                      ${stealer_vm}
    ${ip_stealer}                     Get Virtual Network Interface IP
    Put File                          security-tests/nc_stealer   /tmp
    Run Command                       echo 'ip_server=${ip_server}\nip_stealer=${ip_stealer}' > /tmp/tmp_file
    Run Command                       cat /tmp/nc_stealer >> /tmp/tmp_file
    Run Command                       cp /tmp/tmp_file ${file_path}/nc_stealer  sudo=True
    Run Command                       chmod 777 ${file_path}/nc_stealer  sudo=True

Launch netcat test script
    [Arguments]                       ${vm}  ${script_name}
    Switch to vm                      ${vm}
    Run Keyword And Ignore Error      Run Command  -b ${file_path}/${script_name} ${file_path}  sudo=True  timeout=2

Check the result files
    Switch to vm                      ${GUI_VM}
    ${stealer_log}                    Run Command    cat /Shares/'Unsafe ${stealer_vm} share'/stolen.txt  sudo=True
    ${stolen}                         Run Command    cat /Shares/'Unsafe ${stealer_vm} share'/stolen.txt | grep packet  sudo=True  rc_match=skip
    ${server_log}                     Run Command    cat /Shares/'Unsafe ${server_vm} share'/server_received.txt  sudo=True
    ${server_received}                Run Command    cat /Shares/'Unsafe ${server_vm} share'/server_received.txt | grep packet  sudo=True
    IF  $stealer_log == '${EMPTY}' or $server_log == '${EMPTY}'
        FAIL    Server and/or stealer script was not able to write to output file. Test might be broken.
    END
    IF  $stolen != '${EMPTY}'
        FAIL    Stealer VM managed to receive packets via ip spoofing
    END
    IF  $server_received == '${EMPTY}' and $stolen == '${EMPTY}'
        FAIL    No packets received by server or stealer VM. Test might be broken.
    END

Get Virtual Network Interface IP
    [Documentation]     Parse ifconfig output and look for ethint0 IP
    ${if_name}=    Set Variable   ethint0
    FOR    ${i}    IN RANGE    20
        ${output}     Run Command      ifconfig
        ${ip}         Get ip from ifconfig    ${output}   ${if_name}
        IF  $ip != '${EMPTY}'
            Log       ${ip}
            RETURN    ${ip}
        END
        Sleep    1
    END
    FAIL    IP address not found.


Spoofing Test Teardown
    [Documentation]   Switching of IP address can make stealer VM inaccessible for further tests.
    ...               Restart the stealer vm.
    Switch to vm      ${HOST}
    Run Command       systemctl restart microvm@${stealer_vm}.service  sudo=True
    Close All Connections