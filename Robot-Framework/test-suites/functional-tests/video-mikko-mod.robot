# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing camera application
Force Tags          bat  regression   video  lenovo-x1   dell-7330
Resource            ../../__framework__.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Test Setup          Connect to netvm
Test Teardown       Close All Connections
Test Timeout        2 minutes


*** Variables ***

${VIDEO_DIR}    ${OUTPUT_DIR}/outputs/video-temp
@{failed_videos}

*** Test Cases ***
Check Camera Application
    [Documentation]  Check that camera application is available in business-vm and not in other vm
    [Tags]  SP-T235i
    FOR  ${vm}  IN  @{VMS}
        Connect to VM       ${vm}
        ${out}  Execute Command  v4l2-ctl --list-devices  sudo=True  sudo_password=${PASSWORD}
        Log  ${out}
        IF  '${vm}' == '${BUSINESS_VM}'  Should Contain  ${out}  /dev/video  ELSE  Should Not Contain  ${out}  /dev/video
    END
    [Teardown]  Run Keyword If   "Dell" in "${DEVICE}"   Run Keyword If Test Failed   Skip   "Known issue: SSRCSP-6450"

Record Video With Camera
    [Documentation]  Start Camera application and record short video
    [Tags]  SP-T236i
    Connect to VM           ${BUSINESS_VM}
    Execute Command         rm /tmp/video*  sudo=True  sudo_password=${PASSWORD}
    @{recorded_video_ids}   Create List
    ${listed_devices}       Execute Command  v4l2-ctl --list-devices  sudo=True  sudo_password=${PASSWORD}
    ${video_devices}        Get Regexp Matches  ${listed_devices}  (?im)(.*\\S*.*)(video)(\\d{1})  3
    Run Keyword If  "${video_devices}" == "[]"    FAIL  No Video devices identified. There should be some.

    FOR  ${id}  IN  @{video_devices}
        ${video}            Execute Command  v4l2-ctl --device=/dev/video${id} --all  sudo=True  sudo_password=${PASSWORD}
        # Check if video device is able to capture video
        ${video_caps}       Get Regexp Matches  ${video}  (?im)(.*\\S*Device Caps.*\\s*)(.*\\S*)  2
        IF  'Video Capture' in '${video_caps}[0]'
            Log To Console      Recording video${id} for 5s
            #${result}    Run Keyword And Return Status  Execute Command  ffmpeg -i /dev/video${id} -t 5 -vcodec mpeg4 /tmp/video${id}.avi  timeout=20  sudo=True  sudo_password=${PASSWORD}
            ${stdout}  ${stderr}  ${rc}=  Execute Command  ffmpeg -i /dev/video${id} -t 5 -vcodec mpeg4 /tmp/video${id}.avi  timeout=25  sudo=True  sudo_password=${PASSWORD}  return_stdout=True    return_stderr=True    return_rc=True
            Log  ${stdout}
            Log  ${stderr}
            Log  ${rc}
            ${journal_output}     Execute Command   journalctl --since "10 minutes ago"
            Log           ${journal_output}
            IF  "${rc}" != "0"  FAIL  Device did not manage to record a video.
            Append To List      ${recorded_video_ids}  ${id}
        END
    END

    FOR  ${id}  IN  @{recorded_video_ids}
        Verify Video File  ${id}
    END

    IF  ".avi" in "${failed_videos}"  FAIL   Captured video ${failed_videos} contains only one color. Maybe lid is closed?
    [Teardown]    Run Keyword If  "Dell" in "${DEVICE}"   Run Keyword If Test Failed   SKIP   "Known issue: SSRCSP-6694"

*** Keywords ***
Verify Video File
    [Documentation]  Verify that file size is not 0 and that video is not all black
    [Arguments]  ${id}
    ${video_files}      Execute Command  ls -la /tmp/
    Should Contain      ${video_files}  video${id}.avi
    ${out}              Execute Command  du -sh /tmp/video${id}.avi
    ${size}             Get Regexp Matches  ${out}  (?m)(\\d{1,4})(.*\\s*video.*)  1
    Should Be True      ${size}[0] > 0  msg=Video was not properly captured.
    Verify Video Has Different Colors  /tmp/video${id}.avi  ${id}

Verify Video Has Different Colors
    [Documentation]  Take frames from video and check that image is not all same color
    [Arguments]  ${video}  ${id}
    # Take screenshot every third second i.e. 3 pics, use the middle one
    Execute Command      ffmpeg -i ${video} -r 1/3 /tmp/image%04d.png  sudo=True  sudo_password=${PASSWORD}
    SSHLibrary.Get File  /tmp/image0002.png   ${VIDEO_DIR}/video${id}_image0002.png

    Execute Command      rm /tmp/image*
    Run                  magick ${VIDEO_DIR}/video${id}_image0002.png -identify ${VIDEO_DIR}/video${id}_colors.txt
    Should Not Be Empty  ${VIDEO_DIR}/video${id}_colors.txt  Failed to identify colors

    # Check that all colors are not the same
    ${line}             Run  cat ${VIDEO_DIR}/video${id}_colors.txt | tail -1
    ${color}            Get Regexp Matches  ${line}  (?im)(.*:)(\\s.\\d{1,3},\\d{1,3},\\d{1,3}.)(\\s.*\\s)(.*)  4
    ${all_lines}        Run  cat ${VIDEO_DIR}/video${id}_colors.txt
    ${matching_lines}   Get Lines Containing String   ${all_lines}  ${color}[0]
    ${line_count}       Get Line Count  ${matching_lines}
    ${lines}            Run  wc ${VIDEO_DIR}/video${id}_colors.txt -l
    ${splitted_lines}   Split String  ${lines}
    ${many_colors}      Run Keyword And Return Status  Should Be True  ${line_count} < (${splitted_lines}[0]-${1})
    #DEBUG: run both cases and save the videos
    OperatingSystem.Copy File  ${VIDEO_DIR}/video${id}_image0002.png  ${OUTPUT_DIR}/
    SSHLibrary.Get File  ${video}   ${VIDEO_DIR}/${video[5:]}  #video${id}.avi
    OperatingSystem.Copy File  ${VIDEO_DIR}/${video[5:]}  ${OUTPUT_DIR}/

    SSHLibrary.Get File  ${video}   ${VIDEO_DIR}/${video[5:]}  #video${id}.avi
    OperatingSystem.Copy File  ${VIDEO_DIR}/${video[5:]}  ${OUTPUT_DIR}/
    IF  not ${many_colors}
        #OperatingSystem.Copy File  ${VIDEO_DIR}/video${id}_image0002.png  ${OUTPUT_DIR}     
        Append to list  ${failed_videos}    ${video[5:]}
        Log        <img src="image_${video[5:]}.png">    html=true
    END

