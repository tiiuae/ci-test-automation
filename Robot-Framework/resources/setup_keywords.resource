# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Resource            ../config/variables.robot
Resource            ../resources/gui_keywords.resource
Resource            ../resources/ssh_keywords.resource


*** Keywords ***

Prepare Test Environment
    [Arguments]   ${login}=True   ${enable_dnd}=False
    Check If Device Is Up    range=5
    IF    ${IS_AVAILABLE} == False
        FAIL    The device is not available via SSH or serial.
    ELSE IF  "${CONNECTION_TYPE}" == "serial"
        FAIL    The device is available only via serial, but tests require SSH.
    END
    Close All Connections
    Switch to vm    ${HOST}
    Log versions

    IF  ${IS_LAPTOP}
        Create test user
        IF  ${login}
            Save gui icons and icon path
            Login to laptop   ${enable_dnd}
        END
    END

Clean Up Test Environment
    [Timeout]     5 minutes
    [Arguments]   ${disable_dnd}=False
    IF    ${IS_AVAILABLE} == True and "${CONNECTION_TYPE}" == "ssh"
        # Temporarily taking journal log taking our from Orin-NX [SSRCSP-7453]
        IF  "${DEVICE_TYPE}" != "orin-nx"
            Switch to vm   ${HOST}
            Save host journalctl
        END
        IF  ${IS_LAPTOP}
            Log out from laptop
        END
    END
    Close All Connections

Save host journalctl
    Execute Command      journalctl -b 0 > /tmp/jrnl.txt
    ${jrnl_size}         Execute Command    ls -lh /tmp/jrnl.txt
    Log                  ${jrnl_size}
    # Copy journal log file to Robot outputs
    SSHLibrary.Get file  /tmp/jrnl.txt   ${OUTPUT_DIR}/jrnl.txt
    OperatingSystem.File Should Exist    ${OUTPUT_DIR}/jrnl.txt

Log versions
    ${ghaf_version}     Execute Command   ghaf-version
    Log To Console      Ghaf version: ${ghaf_version}
    ${nixos_version}    Execute Command   nixos-version
    Log To Console      Nixos version: ${nixos_version}
    ${device_id}        Execute Command   cat /persist/common/device-id
    Log To Console      Device ID: ${device_id}

Create test user
    [Setup]          Switch to vm    ${GUI_VM}
    Log To Console   Creating test user
    ${out}  ${err}  ${rc}   Execute Command   systemctl start user-provision-test.service    return_stderr=True  return_rc=True  sudo=True  sudo_password=${PASSWORD}
    Should Be Equal As Integers   ${rc}  0   ${err}
    ${out}            Execute Command    homectl
    Log               ${out}
    Should Contain    ${out}  ${USER_LOGIN}   User not created

Start ydotoold
    [Documentation]    Start ydotool daemon if it is not already running.
    [Setup]            Switch to vm    ${GUI_VM}
    ${ydotoold_state}=    Execute Command    sh -c 'ps aux | grep ydotoold | grep -v grep'
    IF  $ydotoold_state == '${EMPTY}'
        Log To Console    Starting ydotool daemon
        Run Keyword And Ignore Error  Execute Command   /run/current-system/sw/bin/ydotoold --socket-path /tmp/.ydotool_socket  sudo=True  sudo_password=${PASSWORD}  timeout=3
        ${ydotoold_state}=    Execute Command    sh -c 'ps aux | grep ydotoold | grep -v grep'
        Should Not Be Empty  ${ydotoold_state}  failed to start ydotool daemon
        # Allow all users to use Ydotool
        ${output}   Execute Command       chmod 666 /tmp/.ydotool_socket  return_stdout=True  return_rc=True   sudo=True  sudo_password=${PASSWORD}
        Log   ${output}
    ELSE
        Log To Console    Check: ydotool daemon running
    END

Stop ydotoold
    [Documentation]   Kill ydotool daemon
    [Setup]           Switch to vm    ${GUI_VM}
    Log To Console    Stopping ydotool daemon
    Kill process by name   ydotoold   sudo=True

Save gui icons and icon path
    [Documentation]         Save the icons that are used in multiple test cases
    ...                     Save path to icons
    Log To Console          Saving commonly used test icons
    ${ICONS}                Execute Command   find $(echo $XDG_DATA_DIRS | tr ':' ' ') -type d -name "icons" 2>/dev/null
    Set Global Variable     ${ICONS}
    Get icon                ${ICONS}/hicolor/scalable/apps  com.system76.CosmicAppLibrary.svg  crop=0  background=black  output_filename=launcher.png
    Get icon                ${ICONS}/Papirus/24x24/symbolic/actions  window-close-symbolic.svg  crop=0  background=white  output_filename=window-close.png
    Negate app icon         ${GUI_TEMP_DIR}/window-close.png  ${GUI_TEMP_DIR}/window-close-neg.png
    Get icon                ${ICONS}/Cosmic/scalable/actions  system-search-symbolic.svg  crop=0  background=white  output_filename=search.png
    Negate app icon         ${GUI_TEMP_DIR}/search.png  ${GUI_TEMP_DIR}/search-neg.png
    Get icon                ${ICONS}/Papirus/24x24/actions  system-shutdown.svg  crop=0  background=black  output_filename=power.png
    Get icon                ${ICONS}/Cosmic/scalable/actions  system-lock-screen-symbolic.svg  background=black  output_filename=lock.png

Login to laptop
    [Documentation]   Log in to the laptop
    [Arguments]       ${enable_dnd}=False
    Check if ssh is ready on vm   ${GUI_VM}    timeout=60
    Start ydotoold
    Switch to vm   ${GUI_VM}  user=${USER_LOGIN}
    Log in, unlock and verify   ${enable_dnd}

Log out from laptop
    [Documentation]   Log out from the laptop
    [Arguments]       ${disable_dnd}=False
    Start ydotoold
    Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    Log out and verify   ${disable_dnd}
    Stop ydotoold

Is first graphical login
    [Documentation]   Returns True if there has only been one graphical login and False if there has been more than one
    ${result}   Execute Command    journalctl --user -u graphical-session.target | grep "Reached target Current graphical user session"
    Log         ${result}
    ${lines}    Count lines    ${result}
    IF  ${lines} <= 1   RETURN   True
    RETURN      False
