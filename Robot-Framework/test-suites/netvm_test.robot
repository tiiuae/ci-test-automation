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
${TARGET_VM}        netvm


*** Test cases ***
Verify List Of VM's And Start NETVM
    [Tags]    startNetvm
    Write Data    lsvm${\n}
    ${output} =    Read Until    END     # END it's only something that is not there to read and it will read everything
    Should contain    ${output}    ${TARGET_VM}
    Log To Console    ${output}
    Write Data    vm-start ${TARGET_VM}${\n}
    Sleep    10s    # Sleep for enough time to start netvm
    Write Data    lsvm | grep ${TARGET_VM}${\n}
    ${output} =    Read Until    END
    Should contain    ${output}    RUNNING
    Log To Console    ${output}

Ping Test For NETVM
    [Tags]    runPingTest
    ${device} =    Get VM Device Path
    Write Data    echo "ping -c 4 172.18.16.42" > ${device}${\n}
    Sleep    10s    # Sleep for enough time to make ping
    Write Data    head ${device}${\n}
    ${output} =    Read Until    END
    Log To Console    ${output}
    Should contain    ${output}    ping statistics

*** Keywords ***
Get VM Device Path
    [Documentation]    Get device path for connecting that vm's console
    Write Data    ch-remote --api-socket /run/service/ext-netvm/env/cloud-hypervisor.sock info | jq -r .config.console.file${\n}
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
    [Return]     ${device}

Open Serial Port
    Add Port   /dev/ttyUSB0
    ...        baudrate=115200
    ...        bytesize=8
    ...        parity=N
    ...        stopbits=1
