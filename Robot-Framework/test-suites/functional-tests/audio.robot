# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing audio
Test Tags           audio  bat  lenovo-x1  darter-pro  dell-7330

Resource            ../../resources/file_keywords.resource
Resource            ../../resources/audio_and_video_keywords.resource
Resource            ../../resources/ssh_keywords.resource

Suite Setup         Switch to vm   ${NET_VM}
Test Timeout        3 minutes


*** Variables ***

${AUDIO_DIR}           ${OUTPUT_DIR}/outputs/audio-temp
@{VMS_WITH_AUDIO}      ${BUSINESS_VM}  ${CHROME_VM}  ${COMMS_VM}  ${FLATPAK_VM}  ${GUI_VM}
@{VMS_WITHOUT_AUDIO}   ${AUDIO_VM}  ${ADMIN_VM}  ${HOST}  ${MEDIA_VM}  ${NET_VM}


*** Test Cases ***
Record audio in all VMs with audio
    [Tags]   SP-T247    pre-merge
    [Template]  Record Audio And Verify
    FOR  ${vm}  IN  @{VMS_WITH_AUDIO}
        ${vm}
    END

Play audio in all VMs with audio
    [Tags]   SP-T212    pre-merge
    [Template]   Play Audio And Verify
    FOR  ${vm}  IN  @{VMS_WITH_AUDIO}
        ${vm}
    END

Check Audio devices
    [Documentation]  List audio sinks and sources in VMs
    [Tags]      SP-T246  pre-merge
    # VMs with audio
    FOR  ${vm}  IN  @{VMS_WITH_AUDIO}
        IF   '$vm' == '${GUI_VM}'
            Switch to vm   ${vm}   ${USER_LOGIN}
        ELSE
            Switch to vm   ${vm}
        END
        ${sources}   Run Command  pactl list sources
        ${sinks}     Run Command  pactl list sinks
        Run Keyword And Continue On Failure   Should Contain   ${sources}   Source   ${vm} does not have Sources
        Run Keyword And Continue On Failure   Should Contain   ${sinks}     Sink     ${vm} does not have Sinks
    END
    # VMs without audio
    FOR  ${vm}  IN  @{VMS_WITHOUT_AUDIO}
        Switch to vm   ${vm}
        Run Command  pactl list sources  rc_match=not_equal  compare_rc=0
        Run Command  pactl list sinks  rc_match=not_equal  compare_rc=0
    END

Check audio server
    [Documentation]  Check that audio server is available in correct VMs
    [Tags]      SP-T350  pre-merge
    FOR  ${vm}  IN  @{VMS_WITH_AUDIO}
        IF   '$vm' == '${GUI_VM}'
            Switch to vm   ${vm}   ${USER_LOGIN}
        ELSE
            Switch to vm   ${vm}
        END
        ${server}   Run Command   echo $PULSE_SERVER
        Run Keyword And Continue On Failure   Should Not Be Empty   ${server}
    END
    FOR  ${vm}  IN  @{VMS_WITHOUT_AUDIO}
        Switch to vm   ${vm}
        ${server}   Run Command   echo $PULSE_SERVER
        Run Keyword And Continue On Failure   Should Be Empty   ${server}
    END
