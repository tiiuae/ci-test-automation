# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Create file
    [Documentation]    Create file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Creating file ${file_name}
    ${output}  ${err}  ${rc}   Execute Command    touch ${file_name}  return_stderr=True  return_rc=True  sudo=${sudo}  sudo_password=${PASSWORD}
    Should Be Equal As Integers   ${rc}   0   ${err}

Create text file
    [Documentation]    Create text file with given text and name, requires existing ssh connection
    [Arguments]        ${text}    ${file_name}
    Log To Console     Writing to file ${file_name}
    ${out}  ${err}  ${rc}    Execute Command    echo '${text}' > ${file_name}  return_stderr=True  return_rc=True
    Should Be Equal As Integers   ${rc}   0   ${err}

Remove file
    [Documentation]    Remove file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False   ${failure_allowed}=False
    Log To Console     Removing file ${file_name}
    ${output}  ${err}  ${rc}  Execute Command    rm ${file_name}  return_stderr=True  return_rc=True  sudo=${sudo}  sudo_password=${PASSWORD}
    IF  not ${failure_allowed}   Should Be Equal As Integers   ${rc}   0   ${err}

Copy file
    [Documentation]    Copy file, requires existing ssh connection
    [Arguments]        ${file_1}    ${file_2}
    Log To Console     Copying file ${file_1} to ${file_2}
    ${output}  ${err}  ${rc}   Execute Command    cp ${file_1} ${file_2}  return_stderr=True  return_rc=True
    Should Be Equal As Integers   ${rc}   0   ${err}

Check file exists
    [Documentation]    Check file exists, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Check if file ${file_name} exists
    ${output}  ${err}  ${rc}   Execute Command    ls ${file_name}  return_stderr=True  return_rc=True  sudo=${sudo}  sudo_password=${PASSWORD}
    Should Be Equal As Integers   ${rc}   0

Check file doesn't exist
    [Documentation]    Check file doesn't exist, requires existing ssh connection
    [Arguments]        ${file_name}  ${sudo}=False
    Log To Console     Check if file ${file_name} exists
    ${output}  ${err}  ${rc}   Execute Command    ls ${file_name}  return_stderr=True  return_rc=True  sudo=${sudo}  sudo_password=${PASSWORD}
    Should Not Be Equal As Integers   ${rc}   0   ${err}