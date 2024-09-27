# SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             BuiltIn
Library             Collections


*** Keywords ***

Create fail message
    [Arguments]       ${stats}
    ${fail_message}=  Set Variable   Significant deviation detected\nThreshold ${stats}[threshold]\nMeasurement result ${stats}[measurement]\nPrevious measurement ${stats}[prev_meas] (d: ${stats}[d_previous])\nFirst meas of the last stable period ${stats}[baseline1] (d: ${stats}[d_baseline1])\nMean of last stable period ${stats}[mean] (d: ${stats}[d_mean])\n
    [Return]          ${fail_message}

Create improved message
    [Arguments]       ${stats}
    ${improve_message}=  Set Variable   Significant improvement detected!\nThreshold ${stats}[threshold]\nMeasurement result ${stats}[measurement]\nPrevious measurement ${stats}[prev_meas] (d: ${stats}[d_previous])\nFirst meas of the last stable period ${stats}[baseline1] (d: ${stats}[d_baseline1])\nMean of last stable period ${stats}[mean] (d: ${stats}[d_mean])\n
    [Return]          ${improve_message}

Get IP address
    [Documentation]  Get PC ip address
    [Arguments]  ${if_name}=enp0s31f6
    ${out}  Run   ifconfig
    ${ip}  Get Regexp Matches  ${out}  (?m)(${if_name}.*?\n.*?inet) (\\d{1,3}\.\\d{1,3}\.\\d{1,3}\.\\d{1,3})  2
    RETURN  ${ip}[0]