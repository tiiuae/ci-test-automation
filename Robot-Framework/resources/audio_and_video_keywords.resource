# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/file_keywords.resource
Library             ../lib/output_parser.py
Library             DateTime

*** Keywords ***

Check camera
    [Arguments]    ${expected}
    Switch to vm   ${BUSINESS_VM}
    ${output}      Execute Command      v4l2-ctl --list-devices    sudo=True    sudo_password=${PASSWORD}
    ${status}      Run Keyword And Return Status    Should Contain  ${output}  /dev/video
    IF    ${status} != ${expected}
        FAIL       Expected availability of camera: ${expected}, in fact: ${status}
    END

Record Audio And Verify
    [Documentation]  Record short audio with pulseaudio tool. Verify audio clip is bigger than default empty file (40Kb)
    [Arguments]      ${vm}   ${audiofile}=test_${vm}.wav    ${expected_duration}=2 sec
    Switch to vm           ${vm}
    Log To Console         Recording audio file
    ${output}    Execute Command   sh -c 'parecord -r /tmp/${audiofile} & sleep 5 && pkill parecord && chown ghaf:ghaf /tmp/${audiofile}'    sudo=True  sudo_password=${PASSWORD}    timeout=15
    SSHLibrary.Get File    /tmp/${audiofile}  ${AUDIO_DIR}/${audiofile}
    Check Audio File       ${AUDIO_DIR}/${audiofile}    ${expected_duration}
    [Teardown]   Remove file   /tmp/${audiofile}    sudo=True

Check Audio File
    [Documentation]  Check some basic audio data
    [Arguments]  ${audiofile}  ${expected_duration}=2 sec
    ${out}  Run  ffmpeg -i ${audiofile}
    ${duration}  Get Regexp Matches  ${out}  (?im)(Duration: )(\\d{1,2}:\\d{1,2}:\\d{1,2}.\\d{1,3})  2
    ${bitrate}  Get Regexp Matches  ${out}  (?im)(bitrate: )(\\d{1,4})  2
    IF    '${expected_duration}' == '0 sec'
        Should Be Empty  ${duration}
    ELSE
        Should Not Be Empty  ${duration}[0]
        Should Not Be Empty  ${bitrate}[0]
        ${actual_duration}  Convert Time  ${duration}[0]
        ${expected_duration}  Convert Time  ${expected_duration}
        Should Be True  ${actual_duration} > ${expected_duration}
    END

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
    Execute Command      ffmpeg -i ${video} -r 1/3 /tmp/image%04d.png  sudo=True  sudo_password=${PASSWORD}
    SSHLibrary.Get File  /tmp/image0001.png   ${VIDEO_DIR}/image0001.png
    Execute Command      rm /tmp/image*
    Run                  magick ${VIDEO_DIR}/image0001.png -identify ${VIDEO_DIR}/colors.txt
    Should Not Be Empty  ${VIDEO_DIR}/colors.txt  Failed to identify colors

    # Check that all colors are not the same
    ${line}             Run  cat ${VIDEO_DIR}/colors.txt | tail -1
    ${color}            Get Regexp Matches  ${line}  (?im)(.*:)(\\s.\\d{1,3},\\d{1,3},\\d{1,3}.)(\\s.*\\s)(.*)  4
    ${all_lines}        Run  cat ${VIDEO_DIR}/colors.txt
    ${matching_lines}   Get Lines Containing String   ${all_lines}  ${color}[0]
    ${line_count}       Get Line Count  ${matching_lines}
    ${lines}            Run  wc ${VIDEO_DIR}/colors.txt -l
    ${splitted_lines}   Split String  ${lines}
    Should Be True      ${line_count} < (${splitted_lines}[0]-${1})  msg=Captured video contains only one color. Maybe lid is closed?
