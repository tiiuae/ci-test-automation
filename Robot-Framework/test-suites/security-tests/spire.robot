# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Verify that SPIRE server is healthy and x509pop agents are attested
Test Tags           spire  lenovo-x1  darter-pro

Library             Collections
Library             String
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource


*** Variables ***
${SPIRE_SOCKET_PATH}       /run/spire-server/api.sock
${SPIRE_ATTESTATION_TYPE}  x509pop


*** Test Cases ***

Spire agents are running
    [Documentation]    Verify SPIRE server health and one x509pop attested agent for every VM and host.
    [Tags]             SP-T373
    @{vm_list}         Get VM list    with_host=True
    ${expected_count}  Get Length     ${vm_list}
    Switch to vm       ${ADMIN_VM}
    Check SPIRE server health
    ${agents}          Get SPIRE x509pop agents
    Check SPIRE agent count    ${agents}    ${expected_count}


*** Keywords ***

Check SPIRE server health
    ${output}    Run Command    spire-server healthcheck -socketPath ${SPIRE_SOCKET_PATH} -verbose   sudo=True
    Should Contain    ${output}    Server is healthy.

Get SPIRE x509pop agents
    ${output}    Run Command    spire-server agent list -socketPath ${SPIRE_SOCKET_PATH} -attestationType ${SPIRE_ATTESTATION_TYPE}   sudo=True
    Should Match Regexp    ${output}    (?m)^Attestation type\\s+:\\s+${SPIRE_ATTESTATION_TYPE}$
    RETURN       ${output}

Check SPIRE agent count
    [Arguments]       ${agents}    ${expected_count}
    @{spiffe_ids}     Get Regexp Matches    ${agents}    (?m)^SPIFFE ID\\s*:
    ${agent_count}    Get Length            ${spiffe_ids}
    Should Be Equal As Integers             ${agent_count}     ${expected_count}
    ...    Expected one ${SPIRE_ATTESTATION_TYPE} SPIRE agent for every VM and host.
    ...    Expected: ${expected_count}, found: ${agent_count}.
