# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             BuiltIn
Library             Collections


*** Keywords ***

Create fail message
    [Arguments]       ${stats}
    ${fail_message}=  Set Variable   Significant deviation detected\nThreshold ${stats}[threshold]\nMeasurement result ${stats}[measurement]\nPrevious measurement ${stats}[prev_meas] (d: ${stats}[d_previous])\nFirst meas of the last stable period ${stats}[baseline1] (d: ${stats}[d_baseline1])\nMean of last stable period ${stats}[mean] (d: ${stats}[d_mean])\n
    RETURN            ${fail_message}

Create improved message
    [Arguments]       ${stats}
    ${improve_message}=  Set Variable   Significant improvement detected!\nThreshold ${stats}[threshold]\nMeasurement result ${stats}[measurement]\nPrevious measurement ${stats}[prev_meas] (d: ${stats}[d_previous])\nFirst meas of the last stable period ${stats}[baseline1] (d: ${stats}[d_baseline1])\nMean of last stable period ${stats}[mean] (d: ${stats}[d_mean])\n
    RETURN            ${improve_message}
