# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             Collections


*** Keywords ***

Create deviation message
    [Arguments]       ${statistics}     ${inverted}
    ${word}           Set Variable    improvement
    IF  ${inverted} < 1
        IF  ${statistics}[flag] < 0
            ${word}       Set Variable    deviation
        END
    ELSE
        IF  ${statistics}[flag] > 0
            ${word}       Set Variable    deviation
        END
    END
    ${message}=       Set Variable   Significant ${word} detected\n${statistics}\n
    RETURN            ${message}

Determine Test Status
    [Documentation]         Determine if the test is passed or failed. Add notification of significant deviation or improvement to the test message field.
    ...                     Give statistics argument as a dictionary of statistics dictionaries.
    ...                     Inverted argument can be set to 1 for notifying significant decrease of result value as improvement
    ...                     and significant increase of result value as deviation/FAIL.
    [Arguments]             ${statistics_dict}  ${inverted}=0
    ${keys}                 Get Dictionary Keys          ${statistics_dict}
    ${msg}=                 Set Variable  ${EMPTY}
    FOR   ${i}  IN  @{keys}
        ${statistics}       Get From Dictionary      ${statistics_dict}    ${i}
        IF  ${statistics}[measurement] < ${PERF_LOW_LIMIT}
            FAIL            Measurement result is zero or too close to zero.\n\n${statistics}
        END
        IF  ${statistics}[flag] != 0
            ${add_msg}      Create deviation message  ${statistics}     ${inverted}
            ${msg}          Set Variable  ${msg}${i}\n${add_msg}\n
        END
    END
    IF  "deviation" in $msg
        FAIL                ${msg}
    END
    IF  "improvement" in $msg
        Pass Execution  ${msg}
    END

Output Dictionary First Value
    [Documentation]         Argument as a dictionary of statistics dictionaries.
    ...                     Outputs the value of the first dictionary key.
    [Arguments]             ${statistics_dict}
    ${keys}                 Get Dictionary Keys          ${statistics_dict}
    ${output}               Get From Dictionary          ${statistics_dict}    ${keys}[0]
    RETURN                  ${output}

Install sysbench tool
    ${command_output}=    Execute Command    nix-env --query --installed
    ${not_installed} =	Run Keyword And Return Status	Should Not Contain    ${command_output}    sysbench
    IF  ${not_installed}
        Execute Command    nix-env -i sysbench
        ${command_output}=    Execute Command    nix-env --query --installed
        Log               ${\n}Installed packages:${\n}${command_output}  console=True
        Should Contain    ${command_output}    sysbench    sysbench tool was not installed
        Log To Console    sysbench tool was successfully installed
    ELSE
        Log To Console    ${\n}sysbench tool was already installed
    END

Install iperf tool
    ${command_output}=    Execute Command    nix-env --query --installed
    ${not_installed} =	  Run Keyword And Return Status	Should Not Contain    ${command_output}    iperf
    IF  ${not_installed}
        Execute Command   nix-env -i iperf
        ${command_output}=    Execute Command    nix-env --query --installed
        Log To Console    ${\n}Installed packages:${\n}${command_output}
        Should Contain    ${command_output}    iperf    iperf tool was not installed
        Log To Console    iperf tool was successfully installed
    ELSE
        Log To Console    ${\n}iperf tool was already installed
    END

Initial Memory Check
    [Arguments]             ${max_init_memory}  ${iterations}
    ${init_mem_check_ok}=             Set Variable  False
    ${sleep_between}                  Evaluate      10
    FOR    ${i}    IN RANGE    ${iterations}
        ${init_total_mem}=                Execute Command  free --mebi | awk -F: 'NR==2 {print $2}' | awk '{print $1}'
        Log                               Total memory at start ${init_total_mem} MiB  console=True
        IF  ${init_total_mem} > ${max_init_memory}
            Log To Console                Initial total memory too high. Waiting for the mem-manager to adjust it.
            Sleep  ${sleep_between}
        ELSE
            ${init_mem_check_ok}=             Set Variable  True
            BREAK
        END
    END
    IF  $init_mem_check_ok != 'True'
        ${duration}       Evaluate    int(${iterations} * ${sleep_between})
        FAIL    High initial total memory not deflating within ${duration} sec.\nghaf-mem-manager service of the vm has probably failed.
    END
