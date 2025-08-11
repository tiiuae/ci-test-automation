# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing audio application
Force Tags          audio   bat  regression  pre-merge   lenovo-x1   dell-7330

Library             DateTime
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Connect to netvm
Suite Teardown      Close All Connections
Test Timeout        3 minutes


*** Variables ***

${AUDIO_DIR}    ${OUTPUT_DIR}/outputs/audio-temp


*** Test Cases ***

Record audio in Chrome-VM
    [Tags]  SP-T247-1
    Record Audio And Verify   ${CHROME_VM}

Record audio in Business-VM
    [Tags]   SP-T247-2
    Record Audio And Verify   ${BUSINESS_VM}

Record audio in Comms-VM
    [Tags]   SP-T247-3
    Record Audio And Verify   ${COMMS_VM}

Check Audio devices
    [Documentation]  List audio sinks and sources in business-vm and chrome-vm and check status is running
    [Tags]      SP-T246
    FOR  ${vm}  IN  ${CHROME_VM}  ${BUSINESS_VM}  ${COMMS_VM}
        Switch to vm   ${vm}
        ${sources}   Execute Command  pactl list sources
        ${sinks}     Execute Command  pactl list sinks
        Should Not Be Empty  ${sources}
        Should Not Be Empty  ${sinks}
    END


*** Keywords ***
Record Audio And Verify
    [Documentation]  Record short audio with pulseaudio tool. Verify audio clip is bigger than default empty file (40Kb)
    [Arguments]      ${vm}   ${audiofile}=test_${vm}.wav
    Switch to vm           ${vm}
    Log To Console         Recording audio file
    Execute Command        sh -c 'parecord -r /tmp/${audiofile} & sleep 5 && pkill parecord && chown ghaf:ghaf /tmp/${audiofile}'    sudo=True  sudo_password=${PASSWORD}    timeout=15
    SSHLibrary.Get File    /tmp/${audiofile}  ${AUDIO_DIR}/${audiofile}
    Check Audio File       ${AUDIO_DIR}/${audiofile}
    [Teardown]   Remove file   /tmp/${audiofile}

Check Audio File
    [Documentation]  Check some basic audio data
    [Arguments]  ${audiofile}  ${expected_duration}=2 sec
    ${out}  Run  ffmpeg -i ${audiofile}
    ${duration}  Get Regexp Matches  ${out}  (?im)(Duration: )(\\d{1,2}:\\d{1,2}:\\d{1,2}.\\d{1,3})  2
    ${bitrate}  Get Regexp Matches  ${out}  (?im)(bitrate: )(\\d{1,4})  2
    Should Not Be Empty  ${duration}[0]
    Should Not Be Empty  ${bitrate}[0]
    ${actual_duration}  Convert Time  ${duration}[0]
    ${expected_duration}  Convert Time  ${expected_duration}
    Should Be True  ${actual_duration} > ${expected_duration}
