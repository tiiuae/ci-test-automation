# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Keywords ***

Create file
    [Documentation]    Create file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Creating file ${file_name}
    IF  ${sudo}
        Execute Command    touch ${file_name}  sudo=True  sudo_password=${password}
    ELSE
        Execute Command    touch ${file_name}
    END
    Check file exists  ${file_name}   ${sudo}

Create text file
    [Documentation]    Create text file with given text and name, requires existing ssh connection
    [Arguments]        ${text}    ${file_name}
    Log To Console     Creating file ${file_name}
    ${out}    ${rc}    Execute Command    echo '${text}' > ${file_name}    return_rc=True
    Should Be True     ${rc} == 0

Remove file
    [Documentation]    Remove file with given path & name, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Removing file ${file_name}
        IF  ${sudo}
        Execute Command    rm ${file_name}  sudo=True  sudo_password=${password}
    ELSE
        Execute Command    rm ${file_name}
    END
    Check file doesn't exist  ${file_name}   ${sudo}

Copy file
    [Documentation]    Copy file, requires existing ssh connection
    [Arguments]        ${file_1}    ${file_2}
    Log To Console     Copying file ${file_1} to ${file_2}
    ${output}  ${rc}   Execute Command    cp ${file_1} ${file_2}   return_rc=True

Check file exists
    [Documentation]    Check file exists, requires existing ssh connection
    [Arguments]        ${file_name}   ${sudo}=False
    Log To Console     Check if file ${file_name} exists
    IF  ${sudo}
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True  sudo=True  sudo_password=${password}
    ELSE
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True
    END
    Should Be Equal As Integers   ${rc}   0

Check file doesn't exist
    [Documentation]    Check file doesn't exist, requires existing ssh connection
    [Arguments]        ${file_name}  ${sudo}=False
    Log To Console     Check if file ${file_name} exists
    IF  ${sudo}
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True   sudo=True  sudo_password=${password}
    ELSE
        ${output}  ${rc}   Execute Command    ls ${file_name}   return_rc=True
    END
    Should Be Equal As Integers   ${rc}   2
    Log To Console     File ${file_name} doesn't exist
