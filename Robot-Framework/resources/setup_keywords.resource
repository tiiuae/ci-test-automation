# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             SSHLibrary
Resource            ../config/variables.robot
Resource            ../resources/gui_keywords.resource
Resource            ../resources/ssh_keywords.resource
Resource            ../resources/common_keywords.resource
Resource            ../resources/file_keywords.resource


*** Variables ***
${CONNECTION_TYPE}           ssh
${ROBOT_SUDOERS_BOOT_ID}     ${EMPTY}


*** Keywords ***

Prepare Test Environment
    [Arguments]   ${enable_dnd}=False
    [Timeout]     5 minutes
    Check If Device Is Available
    ${timestamp}          Run Command    date '+%Y-%m-%d %H:%M:%S'
    Set Suite Variable    ${SUITE_START_TIME}   ${timestamp}

    Log versions and device unique data
    IF  ${IS_LAPTOP}
        Verify boot from expected device
        Create test user
        Save login and logout icons
        Login to laptop   ${enable_dnd}
    END

Verify boot from expected device
    [Setup]   Switch to vm    ${HOST}
    IF  '${JOB}' == '${DEVICE_TYPE}'
        # Avoid blocking custom local test runs
        RETURN
    END
    Log To Console    Verifying boot from expected device...
    ${expect_internal_boot}    Run Keyword And Return Status    Should Contain    ${JOB}    installer
    IF  ${expect_internal_boot}
        Check that System And Boot Disk Match    nvme0n1
    ELSE
        Check that System And Boot Disk Match    sda
    END

Check that System And Boot Disk Match
    [Documentation]    Check that /boot and / are backed by the same physical disk and match the expected disk.
    [Arguments]        ${expected_disk}
    ${boot_disk}       Get Backing Disk For Mountpoint    /boot
    ${root_disk}       Get Backing Disk For Mountpoint    /
    Should Be Equal    ${boot_disk}       ${expected_disk}    Laptop booted from ${boot_disk}, expected ${expected_disk}
    Should Be Equal    ${root_disk}       ${boot_disk}        / is mounted from ${root_disk}, expected ${boot_disk}
    Log                Correct boot device verified: ${expected_disk}    console=True

Clean Up Test Environment
    [Timeout]     5 minutes
    [Arguments]   ${disable_dnd}=False
    IF    ${IS_AVAILABLE} == True and "${CONNECTION_TYPE}" == "ssh"
        IF   "${SUITE STATUS}" != "PASS"    Save host journalctl
        IF   ${IS_LAPTOP}                   Log out from laptop
    END
    Close All Connections

Save host journalctl
    [Setup]        Switch to vm   ${HOST}
    Run Command    journalctl --since "${SUITE_START_TIME}" > /tmp/jrnl.txt
    Run Command    ls -lh /tmp/jrnl.txt
    # Copy journal log file to Robot outputs
    SSHLibrary.Get file  /tmp/jrnl.txt   ${OUTPUT_DIR}/journal_${SUITE_NAME}.txt
    OperatingSystem.File Should Exist    ${OUTPUT_DIR}/journal_${SUITE_NAME}.txt
    [Teardown]         Reboot Orin if ssh connection dropped    Save host journalctl

Log versions and device unique data
    [Setup]             Switch to vm    ${HOST}
    ${ghaf_commit}      Get File Content Or Default        /persist/build_commit
    ${build_job}        Get File Content Or Default        /persist/job

    Log                 ---- Versions ----                 console=True
    Log                 Ghaf build commit file on the device: ${ghaf_commit}  console=True
    Log                 Test run commit variable: ${COMMIT_HASH}  console=True
    ${ghaf_version}     Run Command   ghaf-version
    Log                 Ghaf version: ${ghaf_version}      console=True
    ${nixos_version}    Run Command   nixos-version
    Log                 Nixos version: ${nixos_version}    console=True
    Log                 NetVM hostname: ${NETVM_NAME}      console=True
    Get Actual Device ID
    #Save the Robot Framework version
    ${robot_version}    Run   robot --version
    Log                 Robot version of the tests: ${robot_version}   console=True
    Log                 Device: ${DEVICE}                  console=True
    Log                 Device type: ${DEVICE_TYPE}        console=True
    Log                 Job file on device: ${build_job}   console=True
    Log                 Test run job variable: ${JOB}      console=True
    Log                 --------                           console=True

Create test user
    [Setup]          Switch to vm    ${GUI_VM}
    Log To Console   Creating test user
    Run Command      systemctl start user-provision-test.service   sudo=True
    ${out}           Run Command    homectl
    Should Contain   ${out}  ${USER_LOGIN}   User not created

Start ydotoold
    [Documentation]    Start ydotool daemon if it is not already running.
    [Setup]            Switch to vm    ${GUI_VM}
    ${ydotoold_state}=    Run Command    sh -c 'ps aux | grep ydotoold | grep -v grep'  rc_match=skip
    IF  $ydotoold_state == '${EMPTY}'
        Log To Console    Starting ydotool daemon
        Run Keyword And Ignore Error  Run Command  systemd-run --unit=ydotoold-persistent /run/current-system/sw/bin/ydotoold --socket-path /tmp/.ydotool_socket  sudo=True  timeout=3
        ${ydotoold_state}=    Run Command    sh -c 'ps aux | grep ydotoold | grep -v grep'
        Should Not Be Empty  ${ydotoold_state}  failed to start ydotool daemon
        # Allow all users to use Ydotool
        Run Command       chmod 666 /tmp/.ydotool_socket  sudo=True
    ELSE
        Log To Console    Check: ydotool daemon running
    END

Stop ydotoold
    [Documentation]   Stop ydotool daemon
    [Setup]           Switch to vm    ${GUI_VM}
    ${ydotoold_state}=    Run Command    sh -c 'ps aux | grep ydotoold | grep -v grep'  rc_match=skip
    IF  $ydotoold_state == '${EMPTY}'
        Confirmed that ydotoold is not running
    ELSE
        Log To Console    Stopping ydotool daemon
        Run Command       systemctl stop ydotoold-persistent.service    sudo=True
    END

Save login and logout icons
    [Documentation]         Save the icons that are used in login and logout
    ...                     Save path to icons
    [Setup]                 Switch to vm    ${GUI_VM}  user=${USER_LOGIN}
    Log To Console          Saving login and logout icons
    ${icons}                Run Command   find $(echo $XDG_DATA_DIRS | tr ':' ' ') -type d -name "icons" 2>/dev/null   rc_match=skip
    Get icon                ${icons}/hicolor/scalable/apps  com.system76.CosmicAppLibrary.svg  crop=0  background=black  output_filename=launcher.png
    Get icon                ${icons}/Cosmic/scalable/actions  system-lock-screen-symbolic.svg  background=black  output_filename=lock.png

Login to laptop
    [Documentation]   Log in to the laptop
    [Arguments]       ${enable_dnd}=False
    Ensure Robot sudoers is installed in all VMs
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
    ${result}   Run Command    journalctl --user -u graphical-session.target | grep "Reached target Current graphical user session"
    ${lines}    Count lines    ${result}
    IF  ${lines} <= 1   RETURN   True
    RETURN      False

Ensure Robot sudoers is installed in all VMs
    [Arguments]     ${skip_boot_check}=False
    Switch to vm    ${HOST}
    ${current_boot_id}    Run Command    cat /proc/sys/kernel/random/boot_id
    IF    '${ROBOT_SUDOERS_BOOT_ID}' == '${current_boot_id}' and not ${skip_boot_check}
        Log    Robot sudoers already installed in this boot, skipping    console=True
        RETURN
    END

    @{vm_list_with_host}    Get VM list    with_host=True
    ${robot_sudoers_install_script_remote}   Set Variable   /tmp/install_robot_sudoers.sh
    ${skipped_vms}    Create List

    # Start an installation in all reachable VMs and on host.
    FOR    ${vm}    IN    @{vm_list_with_host}
        TRY
            Switch to vm    ${vm}
        EXCEPT    AS    ${switch_error}
            Log               Skipping sudoers install in ${vm}: ${switch_error}   console=True
            Append To List    ${skipped_vms}    ${vm}
            CONTINUE
        END
        Log            Starting sudoers install in ${vm}    console=True
        Put File       ../test-files/install_robot_sudoers.sh    ${robot_sudoers_install_script_remote}
        Run Command    chmod 755 ${robot_sudoers_install_script_remote}
        Start Command  ${robot_sudoers_install_script_remote}    sudo=True    sudo_password=${PASSWORD}
    END
    FOR    ${vm}    IN    @{skipped_vms}
        Log Error    Sudoers installation failed    Sudoers not installed to ${vm}
    END
    # Check that installation has finished everywhere
    FOR    ${vm}    IN    @{vm_list_with_host}
        IF    $vm in $skipped_vms
            Log          Skipping sudoers install verification in ${vm} because install was skipped   console=True
            CONTINUE
        END
        Switch to vm    ${vm}
        ${install_out}    Read Command Output
        Should Contain    ${install_out}    __ROBOT_SUDOERS_INSTALL_DONE__    Sudoers install failed in ${vm}, output: ${install_out}
        Log               Sudoers install completed in ${vm}    console=True
    END
    Set Global Variable    ${ROBOT_SUDOERS_BOOT_ID}    ${current_boot_id}
