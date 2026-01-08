# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
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
    [Documentation]  Record short audio with pulseaudio tool.
    ...    Verify audio clip is longer than ${expected_duration}, has higher bitrate than ${expected_bitrate} and higher mean volume than ${volume_limit}.
    [Arguments]      ${vm}  ${audiofile}=record_${vm}.wav  ${expected_bitrate}=1000  ${expected_duration}=2  ${volume_limit}=-40  ${sudo}=True
    IF   '${vm}' == '${GUI_VM}'
        Switch to vm   ${vm}  ${USER_LOGIN}
        ${sudo}        Set Variable   False
    ELSE
        Switch to vm   ${vm}
    END
    Log To Console         Recording audio file
    ${output}              Execute Command   sh -c 'parecord -r /tmp/${audiofile} & sleep 5 && pkill parecord && chown ghaf:ghaf /tmp/${audiofile}'    sudo=${sudo}  sudo_password=${PASSWORD}    timeout=15
    SSHLibrary.Get File    /tmp/${audiofile}  ${AUDIO_DIR}/${audiofile}
    Check Audio Duration   ${AUDIO_DIR}/${audiofile}    ${expected_duration}
    IF   ${expected_duration} != 0
        Check Bitrate          ${AUDIO_DIR}/${audiofile}    ${expected_bitrate}
        Check Mean Volume Level      ${AUDIO_DIR}/${audiofile}    ${volume_limit}
    END
    [Teardown]   Remove file   /tmp/${audiofile}  sudo=${sudo}

Play Audio And Verify
    [Documentation]  Play ${sample_file} in ${vm} and record the audio output to ${record_file} with monitor microphone.
    ...   Verify that the mean volume of ${sample_file} and ${record_file} is within ${tolerance} and that the mean volume of ${sample_file} is higher than ${volume_limit}.
    [Arguments]     ${vm}  ${record_file}=play_${vm}.wav  ${sample_file}=wind.wav  ${tolerance}=2.0  ${volume_limit}=-30  ${sudo}=True
    Switch to vm    ${vm}
    Put File        ../test-files/${sample_file}   /tmp
    Remove file     /tmp/recording_${vm}.wav    sudo=True  failure_allowed=True
    ${duration}     Get Duration   ../test-files/${sample_file}
    IF   '${vm}' == '${GUI_VM}'
        Switch to vm   ${vm}  ${USER_LOGIN}
        ${sudo}        Set Variable   False
    END
    ${pamixer}      Search nix store   pamixer
    ${sources}      Execute Command    ${pamixer}/bin/pamixer --list-sources
    Log             ${sources}
    ${source_id}    Get Monitor Microphone Source    ${sources}

    Log To Console  Playing audio and recording it
    # Play sound and record it with mic simultaneously
    Execute Command       sh -c 'paplay /tmp/${sample_file} & parecord -r /tmp/${record_file} -d ${source_id} & sleep 2.5 && sleep ${duration} && pkill parecord'  sudo=${sudo}  sudo_password=${PASSWORD}
    SSHLibrary.Get File   /tmp/${record_file}    ${AUDIO_DIR}/${record_file}

    Check Audio Duration      ${AUDIO_DIR}/${record_file}    expected_duration=${duration}
    Check Mean Volume Level   ${AUDIO_DIR}/${record_file}    ${volume_limit}
    Compare Mean Volumes      ../test-files/${sample_file}   ${AUDIO_DIR}/${record_file}   ${tolerance}

    [Teardown]   Remove file   /tmp/${record_file}   sudo=${sudo}

Get Mean Volume
    [Arguments]   ${file}   ${log}=True
    ${out}        Run   ffmpeg -i ${file} -filter:a volumedetect -f null /dev/null
    Log           ${out}
    ${mean}       Extract Mean Volume   ${out}
    Log           Mean volume of ${file} is ${mean}  console=${log}
    RETURN        ${mean}

Check Mean Volume Level
    [Documentation]   Check that mean volume of ${file} is higher than ${volume_limit}
    [Arguments]   ${file}   ${volume_limit}
    ${mean}       Get mean Volume   ${file}   log=False
    Should Be True    ${mean} > ${volume_limit}    Audio file is too quiet, mean volume ${mean} dB (should be > ${volume_limit} dB)

Compare Mean Volumes
    [Documentation]   Check that the mean volumes of ${file1} and ${file2} are within ${tolerance} of each other
    [Arguments]   ${file1}   ${file2}   ${tolerance}
    ${mean1}    Get Mean Volume    ${file1}
    ${mean2}    Get Mean Volume    ${file2}
    ${diff}   Evaluate   abs(${mean1} - ${mean2})
    Should Be True    ${diff} <= ${tolerance}    Audio files differ too much (difference ${diff} dB, tolerance ${tolerance} dB)

Get Duration
    [Arguments]   ${file}
    ${out}        Run   ffmpeg -i ${file}
    Log           ${out}
    ${duration}   Get Audio Duration In Seconds   ${out}
    RETURN        ${duration}

Check Audio Duration
    [Documentation]  Check that ${audiofile} is longer than ${expected_duration}
    [Arguments]      ${audiofile}  ${expected_duration}
    ${duration}      Get Duration   ${audiofile}
    Should Be True   ${duration} >= ${expected_duration}

Get Bitrate
    [Arguments]   ${file}
    ${out}        Run   ffmpeg -i ${file}
    Log           ${out}
    ${bitrate}    Get Regexp Matches  ${out}  (?im)(bitrate: )(\\d{1,4})  2
    RETURN        ${bitrate}[0]

Check Bitrate
    [Documentation]  Check that ${audiofile} has higher bitrate than ${expected_bitrate}
    [Arguments]      ${audiofile}  ${expected_bitrate}
    ${bitrate}       Get Bitrate   ${audiofile}
    Should Be True   ${bitrate} > ${expected_bitrate}

Verify Video File
    [Documentation]  Verify that file size is not 0 and that video is not all black
    [Arguments]  ${id}
    ${video_files}      Execute Command  ls -la /tmp/
    Should Contain      ${video_files}  video${id}.avi
    ${out}              Execute Command  du -sh /tmp/video${id}.avi
    ${size}             Get Regexp Matches  ${out}  (?m)(\\d{1,4})(.*\\s*video.*)  1
    Should Be True      ${size}[0] > 0  msg=Video was not properly captured.
    Verify Video Has Different Colors  /tmp/video${id}.avi  ${id}
    [Teardown]   Save video file   /tmp/video${id}.avi   ${id}

Verify Video Has Different Colors
    [Documentation]  Take frames from video and check that image is not all same color
    [Arguments]  ${video}  ${id}
    Remove file          /tmp/video_frame*   sudo=True  failure_allowed=True
    # Save one frame from the video 1 second before it ends
    Execute Command      ffmpeg -sseof -1 -i ${video} -frames:v 1 /tmp/video_frame%01d.png  sudo=True  sudo_password=${PASSWORD}
    SSHLibrary.Get File  /tmp/video_frame1.png   ${VIDEO_DIR}/video_frame${id}.png
    Run                  magick ${VIDEO_DIR}/video_frame${id}.png -identify ${VIDEO_DIR}/colors.txt
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

Save video file
    [Documentation]   Save the video for debugging. File is converted to mp4 because avi files are not saved from the agent.
    [Arguments]    ${video_file}  ${id}
    ${out}    Execute Command   ffmpeg -y -i ${video_file} -c copy /tmp/video${id}.mp4
    SSHLibrary.Get File  /tmp/video${id}.mp4   ${VIDEO_DIR}/video${id}.mp4
