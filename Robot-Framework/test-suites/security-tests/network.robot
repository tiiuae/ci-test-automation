# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Check network related security
Force Tags          security  network
Resource            ../../resources/ssh_keywords.resource


*** Test Cases ***

Account lockout after failed login
    [Tags]          SP-T268
    Check if ssh is ready on vm        ${CHROME_VM}
    Switch to vm    ${COMMS_VM}
    ${ip}    Get VM IP
    Set test variable  ${ip}
    Write    ssh-keygen -R ${CHROME_VM}
    Write    ssh ${LOGIN}@${CHROME_VM}
    ${rc}    ${output}    Run Keyword And Ignore Error    Read Until 	 (yes/no/[fingerprint])?
    Log      ${output}
    ${output}   SSHLibrary.Write    yes
    ${output} 	Read Until 	Password:
    FOR    ${i}    IN RANGE    10
        SSHLibrary.Write    wrong
        ${rc}    ${output}    Run Keyword And Ignore Error    Read Until    assword:
        IF    '${rc}' == 'FAIL'
            ${status}=    Run Keyword And Return Status    Should Contain    ${output}  Too many authentication failures
            IF    ${status}
                BREAK
            END
        END
    END
    Write    ssh ${LOGIN}@${CHROME_VM}
    ${rc}    ${output} 	Run Keyword And Ignore Error    Read Until    $
    Switch to vm    ${CHROME_VM}
    ${output} 	Execute Command    ipset list f2b-sshBlacklist   sudo=True    sudo_password=${PASSWORD}
    Should contain    ${output}    ${ip}
    [Teardown]    Execute Command    ipset del f2b-sshBlacklist ${ip}   sudo=True    sudo_password=${PASSWORD}

Account lockout after failed login (interactive)
    [Tags]          SP-T268-1
    Check if ssh is ready on vm        ${CHROME_VM}
    Switch to vm    ${COMMS_VM}
    ${ip}    Get VM IP
    Write    ssh-keygen -R ${CHROME_VM}
    ${output} 	Read Until 	:
    Write    ssh ${LOGIN}@${CHROME_VM}
    ${rc}    ${output}    Run Keyword And Ignore Error    Read Until 	 (yes/no/[fingerprint])?
    Log      ${output}
    ${output}   SSHLibrary.Write    yes
    ${output} 	Read Until 	Password:
    FOR    ${i}    IN RANGE    10
        SSHLibrary.Write    wrong
        ${rc}    ${output}    Run Keyword And Ignore Error    Read Until    assword:
        IF    '${rc}' == 'FAIL'
            ${status}=    Run Keyword And Return Status    Should Contain    ${output}  Too many authentication failures
            IF    ${status}
                BREAK
            END
        END
    END
    Write    ssh ${LOGIN}@${CHROME_VM}
    ${rc}    ${output} 	Run Keyword And Ignore Error    Read Until    $
    Switch to vm    ${CHROME_VM}
    ${output} 	Execute Command    ipset list f2b-sshBlacklist   sudo=True    sudo_password=${PASSWORD}
    Log      ${output}
    Should contain    ${output}    ${ip}
    [Teardown]    Execute Command    ipset del f2b-sshBlacklist ${ip}   sudo=True    sudo_password=${PASSWORD}
#    [Teardown]    Teardown


*** Keywords ***

Teardown
    Switch to vm        ${HOST}
    Restart VM          ${CHROME_VM}
    Switch to vm        ${CHROME_VM}
    Execute Command     ipset del f2b-sshBlacklist ${ip}   sudo=True    sudo_password=${PASSWORD}

Get VM IP
    ${output}     Execute Command    ifconfig
    ${ip}         Get ip from ifconfig    ${output}   eth
    RETURN        ${ip}

Try to connect
    [Arguments]    ${jumphost}
    ${connection}=       Open Connection    ${vm_name}    port=22    prompt=\$    timeout=30
    FOR    ${i}    IN RANGE     6
        ${status}  ${login_output}   Run Keyword And Ignore Error  Login with timeout  username=${user}  password=wrong  jumphost=${jumphost}
        Exit For Loop If        ${logged_in}
        Sleep                   1
    END
    ${status}  ${login_output}   Run Keyword And Ignore Error  Login with timeout  username=${user}  password=${pw}  jumphost=${jumphost}


Restart VM
    [Documentation]         Try to restart VM service and verify it started
    ...                     Pre-condition: requires active ssh connection to ghaf host.
    [Arguments]             ${vm}
    Log                     Going to start ${vm}    console=True
    Execute Command         systemctl restart microvm@${vm}.service  sudo=True  sudo_password=${PASSWORD}  timeout=120
    ${state}  ${substate}   Verify service status  service=microvm@${vm}.service  expected_state=active  expected_substate=running
    Log                     ${vm} is ${substate}    console=True
    Check if ssh is ready on vm   ${vm}