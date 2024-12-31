# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Testing camera applicaton
Force Tags          video  lenovo-x1
Resource            ../../__framework__.resource
Resource            ../../resources/serial_keywords.resource
Resource            ../../resources/common_keywords.resource
Resource            ../../resources/connection_keywords.resource
Resource            ../../resources/ssh_keywords.resource
Resource            ../../config/variables.robot
Suite Setup         Initialize Variables And Connect
Suite Teardown      Close All Connections
Test Timeout        2 minutes


*** Test Cases ***
Check Camera Application
    [Documentation]  Check that camera application is available in business-vm and not in other vm
    [Tags]  SP-T235
    Connect to netvm
    FOR  ${vm}  IN  @{VMS}
        Connect to VM       ${vm}
        ${out}  Execute Command  v4l2-ctl --list-devices
        Log  ${out}
        IF  '${vm}' == '${BUSINESS_VM}'  Should Contain  ${out}  /dev/video  ELSE  Should Not Contain  ${out}  /dev/video
    END

Record Video With Camera
    [Documentation]  Start Camera application and record short video
    [Tags]  SP-T236
    Connect to netvm
    Connect to VM           ${BUSINESS_VM}
    Execute Command         rm /tmp/video*
    @{recorded_video_ids}   Create List
    ${listed_devices}       Execute Command  v4l2-ctl --list-devices
    ${video_devices}        Get Regexp Matches  ${listed_devices}  (?im)(.*\\S*.*)(video)(\\d{1})  3
    FOR  ${id}  IN  @{video_devices}
        ${video}            Execute Command  v4l2-ctl --device=/dev/video${id} --all
        # Check if video device is able to capture video
        ${video_caps}       Get Regexp Matches  ${video}  (?im)(.*\\S*Device Caps.*\\s*)(.*\\S*)  2
        IF  'Video Capture' in '${video_caps}[0]'
            Log To Console      Recording video${id} for 5s
            Execute Command     ffmpeg -i /dev/video${id} -t 5 -vcodec mpeg4 /tmp/video${id}.avi  timeout=7
            Append To List      ${recorded_video_ids}  ${id}
        END
    END

    FOR  ${id}  IN  @{recorded_video_ids}
        Verify Video File  ${id}
    END


*** Keywords ***
Verify Video File
    [Documentation]  Verify that file size is not 0 and that video is not all black
    [Arguments]  ${id}
    ${video_files}      Execute Command  ls -la /tmp/
    Should Contain      ${video_files}  video${id}.avi
    ${out}              Execute Command  du -sh /tmp/video${id}.avi
    ${size}             Get Regexp Matches  ${out}  (?m)(\\d{1,4})(.*\\s*video.*)  1
    Should Be True      ${size}[0] > 0  msg=Video was not properly captured.
    Verify Video Has Different Colors  /tmp/video${id}.avi

Verify Video Has Different Colors
    [Documentation]  Take frames from video and check that image is not all same color
    [Arguments]  ${video}
    # Take screenshot every third second
    Execute Command      ffmpeg -i ${video} -r 1/3 /tmp/image%04d.png
    SSHLibrary.Get File  /tmp/image0001.png   image0001.png
    Execute Command      rm /tmp/image*
    Run                  magick image0001.png -identify colors.txt

    # Check that all colors are not the same
    ${line}             Run  cat colors.txt | tail -1
    ${color}            Get Regexp Matches  ${line}  (?im)(.*:)(\\s.\\d{1,3},\\d{1,3},\\d{1,3}.)(\\s.*\\s)(.*)  4
    ${all_lines}        Run  cat colors.txt
    ${matching_lines}   Get Lines Containing String   ${all_lines}  ${color}[0]
    ${line_count}       Get Line Count  ${matching_lines}
    ${lines}            Run  wc colors.txt -l
    ${splitted_lines}   Split String  ${lines}
    Should Be True      ${line_count} < (${splitted_lines}[0]-${1})  msg=Captured video contains only one color. Maybe lid is closed?
