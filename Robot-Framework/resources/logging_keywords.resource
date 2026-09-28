# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             String
Resource            common_keywords.resource
Resource            ssh_keywords.resource


*** Keywords ***

Get Increased Number Of Sealed Logs
    [Arguments]        ${vm}    ${seals_before}    ${sealer}=False    ${switch_vm}=True
    ${seals_after}     Get Number Of Sealed Logs    ${vm}    sealer=${sealer}    switch_vm=${switch_vm}
    Should Be True     ${seals_after} > ${seals_before}
    ...                Sealed log count in ${vm} has not increased: ${seals_before} -> ${seals_after}
    RETURN             ${seals_after}

Get Number Of Sealed Logs
    [Arguments]       ${vm}    ${sealer}=False    ${switch_vm}=True
    IF    ${switch_vm}
        Switch To Vm    ${vm}
    END
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

Verify Log Sealing In Current VM
    [Arguments]        ${vm}    ${log}
    ${seals_before}    Get Number Of Sealed Logs    ${vm}    switch_vm=${False}
    Run Command        logger --priority=user.info "${log}"
    ${out}             Wait Until Keyword Succeeds    5x    1s
    ...                Run Command    journalctl --no-pager MESSAGE="${log}" | grep -F -- "${log}"
    Should Contain     ${out}    ${log}    Log was not created in ${vm}
    ${seals_after}     Wait Until Keyword Succeeds
    ...                10x    1s    Get Increased Number Of Sealed Logs
    ...                ${vm}    ${seals_before}    switch_vm=${False}
    Log    ${vm}: sealed logs ${seals_before} -> ${seals_after}    console=True
    RETURN    ${seals_after}
