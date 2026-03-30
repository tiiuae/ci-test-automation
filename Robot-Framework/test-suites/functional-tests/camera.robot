# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing camera application
Test Tags           camera  bat  lenovo-x1  darter-pro  dell-7330

Library             Collections
Library             OperatingSystem
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../resources/audio_and_video_keywords.resource

Test Setup          Switch to vm   ${NET_VM}
Test Timeout        2 minutes


*** Variables ***
${VIDEO_DIR}    ${OUTPUT_DIR}/outputs/camera


*** Test Cases ***

Check Camera in VMs
    [Documentation]  Check that camera is available in business-vm (for Dell in chrome-vm) and not in other VMs
    [Tags]  SP-T235
    @{vms}      Get VM list
    FOR  ${vm}  IN  @{vms}
        Switch to vm        ${vm}
        IF  '${vm}' == '${BUSINESS_VM}' and "${DEVICE_TYPE}" != "dell-7330"
            Run Keyword And Continue On Failure   Run Command  ls /dev/ | grep video  sudo=True
        ELSE IF  '${vm}' == '${CHROME_VM}' and "${DEVICE_TYPE}" == "dell-7330"
            # Special case for Dell due to SSRCSP-8266
            Run Keyword And Continue On Failure   Run Command  ls /dev/ | grep video  sudo=True
        ELSE
            Run Keyword And Continue On Failure   Run Command  ls /dev/ | grep video  sudo=True  rc_match=not_equal  compare_rc=0
        END
    END

Record Video With Camera
    [Documentation]  Start Camera application and record short video
    [Tags]  SP-T236
    Switch to vm            ${BUSINESS_VM}
    Remove file             /tmp/video*   sudo=True  rc_match=skip
    @{recorded_video_ids}   Create List
    ${listed_devices}       Run Command  v4l2-ctl --list-devices  sudo=True
    ${video_devices}        Get Regexp Matches  ${listed_devices}  (?im)(.*\\S*.*)(video)(\\d{1})  3
    Run Keyword If  "${video_devices}" == "[]"    FAIL  No Video devices identified. There should be some.

    FOR  ${id}  IN  @{video_devices}
        ${video}            Run Command  v4l2-ctl --device=/dev/video${id} --all  sudo=True
        # Check if video device is able to capture video
        ${video_caps}       Get Regexp Matches  ${video}  (?im)(.*\\S*Device Caps.*\\s*)(.*\\S*)  2
        IF  'Video Capture' in '${video_caps}[0]'
            Log To Console    Recording video${id} for 8 seconds
            Run Command       ffmpeg -i /dev/video${id} -t 8 -vcodec mpeg4 /tmp/video${id}.avi  timeout=15  sudo=True
            Append To List    ${recorded_video_ids}  ${id}
        END
    END

    FOR  ${id}  IN  @{recorded_video_ids}
        Verify Video File  ${id}
    END

    # Can't be tested on Dell because v4l2-ctl is not available in chrome-vm
    [Teardown]    Run Keyword If  "${DEVICE_TYPE}" == "dell-7330"   Run Keyword If Test Failed   SKIP   "Known issue: SSRCSP-8266"