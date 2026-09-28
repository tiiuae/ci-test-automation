# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             Collections
Library             String
Resource            common_keywords.resource
Resource            ssh_keywords.resource


*** Keywords ***

Verify Log Sealing In VMs
    [Documentation]    Create logs and verify that the producer seal count increases in the given VMs
    [Arguments]        ${log}    @{vms}
    &{seals_before}        Create Dictionary
    @{vms_with_baseline}   Create List
    @{failures}            Create List

    Log    Saving the amount of sealed logs in the selected VMs    console=True
    FOR    ${vm}    IN    @{vms}
        TRY
            ${seal_count}        Get Number Of Sealed Logs    ${vm}
            Set To Dictionary    ${seals_before}    ${vm}=${seal_count}
            Append To List       ${vms_with_baseline}    ${vm}
        EXCEPT    AS    ${error}
            Append To List    ${failures}    Failed to get initial seal count from ${vm}: ${error}
        END
    END

    Log    Creating new logs in the selected VMs    console=True
    Create Logs In VMs    ${log}    @{vms}

    Log    Checking that the selected VMs have new sealed logs    console=True
    FOR    ${vm}    IN    @{vms_with_baseline}
        ${seal_count}    Get From Dictionary    ${seals_before}    ${vm}
        TRY
            ${seals_after}    Wait Until Keyword Succeeds    10x    1s
            ...    Get Increased Number Of Sealed Logs    ${vm}    ${seal_count}
            Log    Sealed logs in ${vm}: ${seal_count} -> ${seals_after}    console=True
        EXCEPT    AS    ${error}
            Append To List    ${failures}    Log sealing verification failed in ${vm}: ${error}
        END
    END
    Should Be Empty    ${failures}    Log sealing failures: ${failures}

Create Logs In VMs
    [Documentation]    Create a logger entry in each given VM
    [Arguments]        ${log}    @{vms}
    FOR    ${vm}    IN    @{vms}
        Switch To Vm    ${vm}
        Run Keyword And Continue On Failure    Create Log In Current VM    ${vm}    ${log}
    END

Create Log In Current VM
    [Arguments]    ${vm}    ${log}
    Run Command    logger --priority=user.info "${log}"
    ${out}         Run Command    journalctl --since "1 minute ago" | grep "${log}"
    Should Contain    ${out}    ${log}    Log was not created in ${vm}

Get Increased Number Of Sealed Logs
    [Arguments]        ${vm}    ${seals_before}    ${sealer}=False
    ${seals_after}     Get Number Of Sealed Logs    ${vm}    sealer=${sealer}
    Should Be True     ${seals_after} > ${seals_before}
    ...                Sealed log count in ${vm} has not increased: ${seals_before} -> ${seals_after}
    RETURN             ${seals_after}

Get Increased Number Of Sealed Logs In Current VM
    [Arguments]        ${vm}    ${seals_before}
    ${seals_after}     Get Number Of Sealed Logs In Current VM    ${vm}
    Should Be True     ${seals_after} > ${seals_before}
    ...                Sealed log count in ${vm} has not increased: ${seals_before} -> ${seals_after}
    RETURN             ${seals_after}

Get Number Of Sealed Logs
    [Arguments]       ${vm}    ${sealer}=False
    Switch To Vm      ${vm}
    ${seal_count}     Get Number Of Sealed Logs In Current VM    ${vm}    sealer=${sealer}
    RETURN            ${seal_count}

Get Number Of Sealed Logs In Current VM
    [Arguments]       ${vm}    ${sealer}=False
    IF    ${sealer}
        ${output}     Run Command    logseald verify-sealer --state-dir /var/lib/logseald/sealer    sudo=True
        Should Contain    ${output}    PASS    Log sealer failed in ${vm}
        ${matches}    Get Regexp Matches    ${output}    (\\d+) total seals    1
    ELSE
        ${state_dir}  Set Variable If    '${vm}'=='${HOST}'    /persist/common/logseald/producer    /var/lib/logseald/producer
        ${output}     Run Command    logseald verify-producer --state-dir ${state_dir} --cert /etc/givc/cert.pem --source ${vm}    sudo=True
        Should Contain    ${output}    PASS    Log sealing failed in ${vm}
        ${matches}    Get Regexp Matches    ${output}    (\\d+) sealed total    1
    END
    ${seal_count}    Convert To Integer    ${matches}[0]
    RETURN           ${seal_count}

Verify Log Sealer
    [Arguments]       ${vm}=${ADMIN_VM}
    ${seal_count}     Get Number Of Sealed Logs    ${vm}    sealer=True
    RETURN            ${seal_count}

Verify Log Sealer In Current VM
    ${seal_count}     Get Number Of Sealed Logs In Current VM    ${ADMIN_VM}    sealer=True
    RETURN            ${seal_count}

Verify Log Sealing In Current VM
    [Arguments]        ${vm}    ${log}
    ${seals_before}    Get Number Of Sealed Logs In Current VM    ${vm}
    Create Log In Current VM    ${vm}    ${log}
    ${seals_after}     Wait Until Keyword Succeeds
    ...                10x    1s    Get Increased Number Of Sealed Logs In Current VM    ${vm}    ${seals_before}
    IF    '${vm}' == '${ADMIN_VM}'
        Verify Log Sealer In Current VM
    END
    Log    ${vm}: sealed logs ${seals_before} -> ${seals_after}    console=True
    RETURN    ${seals_after}
