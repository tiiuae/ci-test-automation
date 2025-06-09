# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing audio application
Force Tags          audio   bat  regression  pre-merge
Resource            ../../__framework__.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Test Setup          Connect to netvm
Test Teardown       Close All Connections
Test Timeout        3 minutes


*** Variables ***

${AUDIO_DIR}    ${OUTPUT_DIR}/outputs/audio-temp


*** Test Cases ***
Record Audio And Verify
    [Documentation]  Record short audio with pulseaudio tool. Verify audio clip is bigger than default empty file (40Kb)
    [Teardown]  Execute Command  rm /tmp/test*.wav  sudo=True  sudo_password=${PASSWORD}
    [Tags]      SP-T247   lenovo-x1   dell-7330
    FOR  ${vm}  IN  ${CHROME_VM}  ${BUSINESS_VM}
        Connect to VM  ${vm}
        # Execute Command timeouts in business-vm, but it is executing the command
        Log To Console  Recording audio file
        Run Keyword And Ignore Error  Execute Command  parecord -r /tmp/test_${vm}.wav  sudo=True  sudo_password=${PASSWORD}  timeout=10
        Sleep  5
        Execute Command  pkill parecord  timeout=10  sudo=True  sudo_password=${PASSWORD}
        Sleep  1
        SSHLibrary.Get File  /tmp/test_${vm}.wav  ${AUDIO_DIR}/test_${vm}.wav
        Check Audio File  ${AUDIO_DIR}/test_${vm}.wav
    END

Check Audio devices
    [Documentation]  List audio sinks and sources in business-vm and chrome-vm and check status is running
    [Tags]      SP-T246   lenovo-x1   dell-7330
    FOR  ${vm}  IN  ${CHROME_VM}  ${BUSINESS_VM}
        Connect to VM  ${vm}
        ${sources}  Execute Command  pactl list sources   sudo=True  sudo_password=${PASSWORD}
        ${sinks}  Execute Command  pactl list sinks   sudo=True  sudo_password=${PASSWORD}
        Should Not Be Empty  ${sources}
        Should Not Be Empty  ${sinks}
    END


*** Keywords ***
Check Audio File
    [Documentation]  Check some basic audio data
    [Arguments]  ${audiofile}  ${expected_duration}=5 sec
    ${out}  Run  ffmpeg -i ${audiofile}
    ${duration}  Get Regexp Matches  ${out}  (?im)(Duration: )(\\d{1,2}:\\d{1,2}:\\d{1,2}.\\d{1,3})  2
    ${bitrate}  Get Regexp Matches  ${out}  (?im)(bitrate: )(\\d{1,4})  2
    Should Not Be Empty  ${duration}[0]
    Should Not Be Empty  ${bitrate}[0]
    ${actual_duration}  Convert Time  ${duration}[0]
    ${expected_duration}  Convert Time  ${expected_duration}
    Should Be True  ${actual_duration} > ${expected_duration}
