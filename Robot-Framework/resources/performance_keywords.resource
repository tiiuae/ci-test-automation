# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             BuiltIn
Library             Collections


*** Keywords ***

Create fail message
    [Arguments]       ${stats}
    ${percent_raw}=   Evaluate  100*(${stats}[d_previous]/${stats}[prev_meas])
    ${{percent}=      Convert To Number  ${percent_raw}  1
    ${fail_message}=  Set Variable   Significant deviation detected (${percent} %)\nThreshold ${stats}[threshold]\nMeasurement result ${stats}[measurement]\nPrevious measurement ${stats}[prev_meas] (d: ${stats}[d_previous])\nFirst meas of the last stable period ${stats}[baseline1] (d: ${stats}[d_baseline1])\nMean of last stable period ${stats}[mean] (d: ${stats}[d_mean])\n
    RETURN            ${fail_message}

Create improved message
    [Arguments]       ${stats}
    ${percent_raw}=   Evaluate  100*(${stats}[d_previous]/${stats}[prev_meas])
    ${{percent}=      Convert To Number  ${percent_raw}  1
    ${improve_message}=  Set Variable   Significant improvement detected! (${percent} %)\nThreshold ${stats}[threshold]\nMeasurement result ${stats}[measurement]\nPrevious measurement ${stats}[prev_meas] (d: ${stats}[d_previous])\nFirst meas of the last stable period ${stats}[baseline1] (d: ${stats}[d_baseline1])\nMean of last stable period ${stats}[mean] (d: ${stats}[d_mean])\n
    RETURN            ${improve_message}
