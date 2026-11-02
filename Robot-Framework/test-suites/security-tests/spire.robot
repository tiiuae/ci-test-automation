# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0


*** Settings ***
Documentation       Verify that SPIRE server is healthy and x509pop agents are attested

Library             Collections
Library             String
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/service_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Wait for VMs to be running

Test Tags           spire  lenovo-x1  darter-pro  orin-agx  orin-agx-64  orin-nx


*** Variables ***
${SPIRE_SOCKET_PATH}        /run/spire-server/api.sock
${SPIRE_AGENT_SOCKET_PATH}  /run/spire-agent/agent.sock
${SPIRE_ATTESTATION_TYPE}  x509pop


*** Test Cases ***
Spire agents are running
    [Documentation]    Verify SPIRE server health and one x509pop attested agent for every VM and host.
    [Tags]             SP-T373
    Switch to vm       ${ADMIN_VM}
    Check SPIRE server health
    Check SPIRE agents


*** Keywords ***
Wait for VMs to be running
    @{vm_list}    Get VM list
    FOR    ${vm}    IN    @{vm_list}
        TRY
            Verify service status    service=microvm@${vm}    range=30
        EXCEPT    AS    ${error}
            Log    ${vm}: ${error}    WARN
        END
    END

Check SPIRE server health
    ${output}    Run Command    spire-server healthcheck -socketPath ${SPIRE_SOCKET_PATH} -verbose   sudo=True
    Should Contain    ${output}    Server is healthy.

Get SPIRE x509pop agents
    ${output}    Run Command    spire-server agent list -socketPath ${SPIRE_SOCKET_PATH} -attestationType ${SPIRE_ATTESTATION_TYPE}   sudo=True
    RETURN       ${output}

Check SPIRE agent count
    [Arguments]       ${expected_count}
    ${agents}         Get SPIRE x509pop agents
    @{spiffe_ids}     Get Regexp Matches    ${agents}    (?m)^SPIFFE ID\\s*:
    ${agent_count}    Get Length            ${spiffe_ids}
    Should Be Equal As Integers    ${agent_count}    ${expected_count}
    ...    Expected one ${SPIRE_ATTESTATION_TYPE} SPIRE agent for every VM and host. Expected: ${expected_count}, found: ${agent_count}.

Check SPIRE agents
    @{vm_list}         Get VM list    with_host=True
    ${expected_count}  Get Length    ${vm_list}
    Switch to vm       ${ADMIN_VM}
    TRY
        Wait Until Keyword Succeeds    10x    1s    Check SPIRE agent count    ${expected_count}
    EXCEPT    AS    ${count_error}
        Log    ${count_error}
    ELSE
        RETURN
    END

    ${agent_failures}    Create List
    FOR    ${vm}    IN    @{vm_list}
        TRY
            Switch to vm    ${vm}
            Run Command    spire-agent healthcheck -socketPath ${SPIRE_AGENT_SOCKET_PATH} -verbose    sudo=True
        EXCEPT    AS    ${error}
            Append To List    ${agent_failures}    ${vm}: ${error}
        END
    END
    ${failure_details}    Catenate    SEPARATOR=\n    @{agent_failures}
    IF    not $agent_failures
        ${failure_details}    Set Variable    All local SPIRE agent health checks passed.
    END
    Fail    ${count_error}\nLocal SPIRE agent check failures:\n${failure_details}
