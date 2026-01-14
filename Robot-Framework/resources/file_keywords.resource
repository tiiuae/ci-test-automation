# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Create file
    [Documentation]    Create file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Creating file ${file_name}
    Run Command        touch ${file_name}  sudo=${sudo}

Create text file
    [Documentation]    Create text file with given text and name, requires existing ssh connection
    [Arguments]        ${text}    ${file_name}
    Log To Console     Writing to file ${file_name}
    Run Command        echo '${text}' > ${file_name}

Remove file
    [Documentation]    Remove file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False   ${rc_match}=equal
    Log To Console     Removing file ${file_name}
    Run Command        rm ${file_name}  sudo=${sudo}  rc_match=${rc_match}

Copy file
    [Documentation]    Copy file, requires existing ssh connection
    [Arguments]        ${file_1}    ${file_2}
    Log To Console     Copying file ${file_1} to ${file_2}
    Run Command        cp ${file_1} ${file_2}

Check file exists
    [Documentation]    Check file exists, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Checking that file ${file_name} exists
    Run Command        ls ${file_name}  sudo=${sudo}

Check file doesn't exist
    [Documentation]    Check file doesn't exist, requires existing ssh connection
    [Arguments]        ${file_name}  ${sudo}=False
    Log To Console     Checking that file ${file_name} does not exist
    Run Command        ls ${file_name}  sudo=${sudo}  rc_match=not_equal  compare_rc=0