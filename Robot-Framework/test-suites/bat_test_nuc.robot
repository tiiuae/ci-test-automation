# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Documentation       Test for starting netvm and run some basic ping test through virtio-console device.
Force Tags          netvm_boot_test
Library             BuiltIn
Library             String
Library             Collections
Library             SerialLibrary    encoding=ascii
Suite Setup         Open Serial Port
Suite Teardown      Delete All Ports

*** Variables ***
${Data}             lsvm
${NET_VM}           netvm
${APP_VM}           appvm-lynx
${IP_ADDRESS}       172.18.16.32
${NET_VM_COMMAND}   ch-remote --api-socket /run/service/ext-${NET_VM}/env/cloud-hypervisor.sock info | jq -r .config.console.file${\n}
${APP_VM_COMMAND}   ch-remote --api-socket /run/service/ext-${APP_VM}/env/cloud-hypervisor.sock info | jq -r .config.console.file${\n}


*** Test cases ***
Verify List Of VM's And Start And Verify Running State Of NETVM
    [Tags]    startNetvm
    Write Data    lsvm${\n}
    ${output} =    Read Until    END     # END it's only something that is not there to read and it will read everything
    Should contain    ${output}    ${NET_VM}
    Should contain    ${output}    ${APP_VM}
    Start VM    ${NET_VM}

Ping Test For NETVM And Stop NETVM
    [Tags]    runNetvmPingTest
    ${device} =    Get VM Device Path    ${NET_VM_COMMAND}
    Write Data    echo "ping -c 4 ${IP_ADDRESS}" > ${device}${\n}
    Sleep    10s    # Sleep for enough time to make ping
    Write Data    head ${device}${\n}
    ${output} =    Read Until    END
    Should contain    ${output}    ping statistics
    Stop VM    ${NET_VM}

Start And Verify Running State Of APP-VM Lynx And Verify Also Start Of NETVM
    [Tags]    startAppVmLynx
    Start VM    ${APP_VM}
    Write Data    lsvm | grep ${NET_VM}${\n}
    ${output} =    Read Until    END
    Should contain    ${output}    RUNNING
    Log To Console    ${output}

    # Need to figure out some stuff for that
    # ${device} =    Get VM Device Path    ${APP_VM_COMMAND}
    # Write Data    echo "ping -c 4 ${IP_ADDRESS}" > ${device}${\n}
    # Sleep    10s    # Sleep for enough time to make ping
    # Write Data    head ${device}${\n}
    # ${output} =    Read Until    END
    # Should contain    ${output}    ping statistics

*** Keywords ***
Start VM
    [Arguments]    ${target_vm}
    [Documentation]    Start vm and verify running state of given ${target_vm}.
    Write Data    vm-start ${target_vm}${\n}
    Sleep    10s    # Sleep for enough time to start vm
    Write Data    lsvm | grep ${target_vm}${\n}
    ${output} =    Read Until    END
    Should contain    ${output}    RUNNING
    Log To Console    ${output}

Stop VM
    [Arguments]    ${target_vm}
    [Documentation]    Stop vm and verify stopped state of given ${target_vm}.
    Write Data    vm-stop ${target_vm}${\n}
    Sleep    5s    # Sleep for enough time to stop vm
    Write Data    lsvm | grep ${target_vm}${\n}
    ${output} =    Read Until    END
    Should contain    ${output}    STOPPED
    Log To Console    ${output}

Get VM Device Path
    [Arguments]    ${command}
    [Documentation]    Get device path for connecting that vm's console
    Write Data   ${command}
    ${output} =    Read Until    END
    @{strings} =    Split String    ${output}
    FOR    ${string}    IN    @{strings}
        ${status} =    Run Keyword And Return Status    Should Contain    ${string}    /dev/
        IF    ${status}
            ${device} =    Set Variable    ${string}
            BREAK
        END
    END
    IF   ${status} == False    FAIL    Device path was not found!
    RETURN     ${device}

Open Serial Port
    Add Port   /dev/ttyUSB0
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1
