# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

*** Settings ***
Library             SSHLibrary
Library             String


*** Keywords ***

Verify microvm PCI device passthrough
    [Documentation]     Verify that proper PCI devices have been passed through to the VM
    [Arguments]    ${vmname}
    Switch to vm   ${vmname}
    @{pciids}=    Get list of PCI IDs
    Switch to vm   ghaf-host
    @{pcipassthrus}=    Get microvm PCI passthrough list    vmname=${vmname}
    FOR    ${pcipass}    IN    @{pcipassthrus}
        ${pciidpass}=    Get PCI ID from PCI Address    address=${pcipass}
	Log    Checking if PCI ID has been passed through to VM
	Should Contain    ${pciids}    ${pciidpass}
    END

Get list of PCI IDs
    [Documentation]     Runs lspci and returns VENDORID:DEVICEID pairs
    ...                 Pre-condition: requires active ssh connection to either
    ...                                host or one of the VMs, and ability run
    ...                                lspci in the target.
    ${cmd}=    Set Variable    lspci -n | cut -d ' ' -f 3
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    @{lines}=    Split To Lines    ${stdout}
    RETURN       @{lines}

Get microvm PCI passthrough list
    [Documentation]     Returns PCI Addresses, like 0001:01:00.0
    ...                 Pre-condition: requires active ssh connection to ghaf host
    [Arguments]    ${vmname}
    ${cmd}=    Format String    cat /var/lib/microvms/{vmname}/booted/share/microvm/pci-devices    vmname=${vmname}
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    @{lines}=    Split To Lines    ${stdout}
    RETURN       @{lines}

Get PCI ID from PCI Address
    [Documentation]     Gets VENDORID:DEVICEID pair from sysfs
    [Arguments]    ${address}
    ${cmd}=    Set Variable    VENDOR=$(cut -c 3-7 /sys/bus/pci/devices/${address}/vendor) && DEVICE=$(cut -c 3-7 /sys/bus/pci/devices/${address}/device) && echo "$VENDOR:$DEVICE"
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${cmd}    return_stdout=True    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    ${stripped}=    Strip String    ${stdout}
    RETURN          ${stripped}
