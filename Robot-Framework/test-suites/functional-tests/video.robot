# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing camera application
Force Tags          video  bat  regression  lenovo-x1  darter-pro  dell-7330

Library             Collections
Library             OperatingSystem
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/audio_and_video_keywords.resource

Test Setup          Switch to vm   ${NET_VM}
Test Timeout        2 minutes


*** Variables ***
${VIDEO_DIR}    ${OUTPUT_DIR}/outputs/video-temp


*** Test Cases ***

Check Camera Application
    [Documentation]  Check that camera application is available in business-vm and not in other vm
    [Tags]  SP-T235
    @{vms}      Get VM list
    FOR  ${vm}  IN  @{vms}
        Switch to vm        ${vm}
        ${out}  Execute Command  v4l2-ctl --list-devices  sudo=True  sudo_password=${PASSWORD}
        Log  ${out}
        IF  '${vm}' == '${BUSINESS_VM}'  Should Contain  ${out}  /dev/video  ELSE  Should Not Contain  ${out}  /dev/video
    END
    [Teardown]  Run Keyword If   "${DEVICE_TYPE}" == "dell-7330"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6450"

Record Video With Camera
    [Documentation]  Start Camera application and record short video
    [Tags]  SP-T236
    Switch to vm            ${BUSINESS_VM}
    Remove file             /tmp/video*   sudo=True  failure_allowed=True
    @{recorded_video_ids}   Create List
    ${listed_devices}       Execute Command  v4l2-ctl --list-devices  sudo=True  sudo_password=${PASSWORD}
    ${video_devices}        Get Regexp Matches  ${listed_devices}  (?im)(.*\\S*.*)(video)(\\d{1})  3
    Run Keyword If  "${video_devices}" == "[]"    FAIL  No Video devices identified. There should be some.

    FOR  ${id}  IN  @{video_devices}
        ${video}            Execute Command  v4l2-ctl --device=/dev/video${id} --all  sudo=True  sudo_password=${PASSWORD}
        # Check if video device is able to capture video
        ${video_caps}       Get Regexp Matches  ${video}  (?im)(.*\\S*Device Caps.*\\s*)(.*\\S*)  2
        IF  'Video Capture' in '${video_caps}[0]'
            Log To Console      Recording video${id} for 8 seconds
            Execute Command     ffmpeg -i /dev/video${id} -t 8 -vcodec mpeg4 /tmp/video${id}.avi  timeout=15  sudo=True  sudo_password=${PASSWORD}
            Append To List      ${recorded_video_ids}  ${id}
        END
    END

    FOR  ${id}  IN  @{recorded_video_ids}
        Verify Video File  ${id}
    END

    [Teardown]    Run Keyword If  "${DEVICE_TYPE}" == "dell-7330"   Run Keyword If Test Failed   SKIP   "Known issue: SSRCSP-6694"
