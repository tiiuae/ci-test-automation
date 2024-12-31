# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Force Tags          security
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Resource            ../../resources/common_keywords.resource
Suite Teardown      Close All Connections


*** Variables ***
${connection}


*** Test Cases ***

Test IP spoofing
    [Documentation]   Test if it's possible to steal packets via ip spoofing
    [Tags]            SP-T128   lenovo-x1

    # Prepare netcat server script
    Connect to netvm
    Check if ssh is ready on vm    ${GALA_VM}
    Connect to VM                  ${GALA_VM}
    ${ip_gala}                     Get Virtual Network Interface IP
    Put File                       security-tests/nc_server   /tmp
    Execute Command                chmod 777 /tmp/nc_server

    # Prepare netcat client script
    Connect to netvm
    Check if ssh is ready on vm    ${COMMS_VM}
    Connect to VM                  ${COMMS_VM}
    Put File                       security-tests/nc_client   /tmp
    Execute Command                echo 'ip_server=${ip_gala}' > /tmp/tmp_file
    Execute Command                cat /tmp/nc_client >> /tmp/tmp_file
    Execute Command                cp /tmp/tmp_file /tmp/nc_client
    Execute Command                chmod 777 /tmp/nc_client

    # Prepare netcat stealer script
    Connect to netvm
    Check if ssh is ready on vm    ${CHROME_VM}
    Connect to VM                  ${CHROME_VM}
    ${ip_chrome}                   Get Virtual Network Interface IP
    Put File                       security-tests/nc_stealer   /tmp
    Execute Command                echo 'ip_server=${ip_gala}\nip_stealer=${ip_chrome}' > /tmp/tmp_file
    Execute Command                cat /tmp/nc_stealer >> /tmp/tmp_file
    Execute Command                cp /tmp/tmp_file /tmp/nc_stealer
    Execute Command                chmod 777 /tmp/nc_stealer

    # Launch the test scripts
    Connect to VM                  ${GALA_VM}
    Run Keyword And Ignore Error   Execute Command  -b /tmp/nc_server  sudo=True  sudo_password=${PASSWORD}  timeout=3
    Connect to VM                  ${COMMS_VM}
    Run Keyword And Ignore Error   Execute Command  -b /tmp/nc_client  sudo=True  sudo_password=${PASSWORD}  timeout=3
    Connect to VM                  ${CHROME_VM}
    Run Keyword And Ignore Error   Execute Command  -b /tmp/nc_stealer  sudo=True  sudo_password=${PASSWORD}  timeout=3
    Log To Console                 Waiting 40 sec for the test to finish
    Sleep                          40
    Close All Connections

    # Check the result files
    Connect
    Connect to netvm
    Check if ssh is ready on vm    ${CHROME_VM}
    Connect to VM                  ${CHROME_VM}
    ${stolen}                      Execute Command    cat /tmp/stolen.txt | grep packet
    Log                            ${stolen}
    ${stealer_log}                 Execute Command    cat /tmp/stolen.txt
    Log                            ${stealer_log}
    Connect to VM                  ${GALA_VM}
    ${server}                      Execute Command    cat /tmp/server_received.txt | grep packet
    Log                            ${server}
    ${server_log}                  Execute Command    cat /tmp/server_received.txt
    Log                            ${server_log}
    IF  $stolen != '${EMPTY}'
        FAIL    Stealer VM managed to receive packets via ip spoofing
    END
    IF  $server == '${EMPTY}' and $stolen == '${EMPTY}'
        FAIL    No packets received by server or stealer VM
    END
