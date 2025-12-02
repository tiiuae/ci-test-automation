# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing audio
Force Tags          audio   bat  regression   lenovo-x1   darter-pro   dell-7330

Resource            ../../resources/file_keywords.resource
Resource            ../../resources/audio_and_video_keywords.resource
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
