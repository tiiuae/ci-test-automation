# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing audio
Force Tags          audio   bat  regression   lenovo-x1   darter-pro   dell-7330

Library             DateTime
Resource            ../../resources/file_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Switch to vm   ${NET_VM}
Test Timeout        3 minutes


*** Variables ***

${AUDIO_DIR}    ${OUTPUT_DIR}/outputs/audio-temp


*** Test Cases ***

Record audio in business-vm
    [Tags]   SP-T247-1  pre-merge
    Record Audio And Verify   ${BUSINESS_VM}

Record audio in chrome-vm
    [Tags]  SP-T247-2  pre-merge
    Record Audio And Verify   ${CHROME_VM}

Record audio in comms-vm
    [Tags]   SP-T247-3
    Record Audio And Verify   ${COMMS_VM}

Record audio in flatpak-vm
    [Tags]   SP-T247-4
    Record Audio And Verify   ${FLATPAK_VM}

Record audio in gui-vm
    [Tags]   SP-T247-5
    Record Audio And Verify   ${GUI_VM}

Check Audio devices
    [Documentation]  List audio sinks and sources in VMs
    [Tags]      SP-T246  pre-merge
    # VMs with audio
    FOR  ${vm}  IN  ${BUSINESS_VM}  ${CHROME_VM}  ${COMMS_VM}  ${FLATPAK_VM}  ${GUI_VM} 
        Switch to vm   ${vm}
        ${sources}   Execute Command  pactl list sources
        ${sinks}     Execute Command  pactl list sinks
        Run Keyword And Continue On Failure   Should Contain   ${sources}   Source   ${vm} does not have Sources
        Run Keyword And Continue On Failure   Should Contain   ${sinks}     Sink     ${vm} does not have Sinks
    END
    # VMs without audio
    FOR  ${vm}  IN  ${AUDIO_VM}  ${ADMIN_VM}  ${HOST}  ${NET_VM}  ${ZATHURA_VM}
        Switch to vm   ${vm}
        ${sources}   Execute Command  pactl list sources
        ${sinks}     Execute Command  pactl list sinks
        Run Keyword And Continue On Failure   Should Not Contain   ${sources}   Source   ${vm} has Sources
        Run Keyword And Continue On Failure   Should Not Contain   ${sinks}     Sink     ${vm} has Sinks
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
