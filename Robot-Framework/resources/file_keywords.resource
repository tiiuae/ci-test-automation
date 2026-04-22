# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Create file
    [Documentation]    Create file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log                Creating file ${file_name}    console=True
    Run Command        touch ${file_name}  sudo=${sudo}

Create text file
    [Documentation]    Create text file with given text and name, requires existing ssh connection
    [Arguments]        ${text}    ${file_name}    ${sudo}=False
    Log                Writing to file ${file_name}    console=True
    Run Command        sh -c 'echo "${text}" > ${file_name}'    sudo=${sudo}

Get file owner id
    [Arguments]        ${file_name}
    ${user}            Run Command    stat -c "%U" ${file_name}
    ${id}              Run Command    id -u ${user}
    RETURN             ${id}

Remove file
    [Documentation]    Remove file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False   ${rc_match}=equal
    Log                Removing file ${file_name}    console=True
    Run Command        rm ${file_name}  sudo=${sudo}  rc_match=${rc_match}

Copy file
    [Documentation]    Copy file, requires existing ssh connection
    [Arguments]        ${file_1}    ${file_2}
    Log                Copying file ${file_1} to ${file_2}    console=True
    Run Command        cp ${file_1} ${file_2}

Check file exists
    [Documentation]    Check file exists, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log                Checking that file ${file_name} exists    console=True
    Run Command        ls ${file_name}  sudo=${sudo}

Check file doesn't exist
    [Documentation]    Check file doesn't exist, requires existing ssh connection
    [Arguments]        ${file_name}  ${sudo}=False
    Log                Checking that file ${file_name} does not exist    console=True
    Run Command        ls ${file_name}  sudo=${sudo}  rc_match=not_equal  compare_rc=0

Edit File
    [Documentation]    Replaces all ${position} strings with ${new_string} if replace=true
    ...                Adds ${new_string} under all lines containing ${position} string if replace=false
    ...                Keyword fails if the file does not contain ${position} string
    [Arguments]        ${file_path}  ${position}  ${new_string}  ${replace}=${True}
    Run Command        grep -l '${position}' ${file_path}
    IF  ${replace}
        Run Command    sed -i s/'${position}'/'${new_string}'/ ${file_path}    sudo=True
    ELSE
        Run Command    sed -i '/${position}/a ${new_string}' ${file_path}    sudo=True
    END
    ${out}             Run Command    cat ${file_path}
    Log                ${out}

Get File Content Or Default
    [Arguments]    ${path}    ${default}=not found
    ${out}    ${rc}=    Run Command    cat ${path}    return=out,rc    rc_match=skip
    IF    ${rc} == 0
        RETURN    ${out}
    ELSE
        RETURN    ${default}
    END