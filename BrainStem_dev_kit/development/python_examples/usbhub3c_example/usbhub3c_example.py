# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.

import sys

import brainstem
#for easy access to error constants
from brainstem.result import Result
import time

# Create USBHub3c object and connecting to the first module found
print('\nCreating USBHub3c stem and connecting to first module found')
chub = brainstem.stem.USBHub3c()

#Locate and connect to the first object you find on USB
#Easy way: 1=USB, 2=TCPIP
result = chub.discoverAndConnect(brainstem.link.Spec.USB)
#Locate and connect to a specific module (replace with your devices Serial Number (hex))
#result = chub.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)

#Verify we are connected
if result == (Result.NO_ERROR):
    result = chub.system.getSerialNumber()
    print("Connected to USBHub3c with serial number: 0x%08X" % result.value)
else:
    #If we are not connected there is nothing we can do.
    print ('Could not find a module.\n')
    sys.exit(1)

result = chub.hub.getUpstream();
upstreamPort = brainstem.stem.USBHub3c.NUMBER_OF_USB_PORTS

if result.error == Result.NO_ERROR:
    upstreamPort = result.value
    print("")
    print("The current upstream port is: %d" % upstreamPort)

if result.error == Result.NO_ERROR:
    print("")
    print("Disabling all downstream ports")

    for port in range(0, brainstem.stem.USBHub3c.NUMBER_OF_USB_PORTS):

        if port == upstreamPort:
            print("Skipping upstream port.")
        elif port == brainstem.stem.USBHub3c.PORT_ID_CONTROL_INDEX:
            print("The control port is always enabled.")
        elif port == brainstem.stem.USBHub3c.PORT_ID_POWER_C_INDEX:
            print("The Power-C port is always enabled")
        else:
            err = chub.hub.port[port].setEnabled(False)
            print("Disabling port %d, Error: %d" % (port, err))

        time.sleep(.4) #Delay so the user can see it.

if result.error == Result.NO_ERROR:
    print("")
    print("Enabling all downstream ports")

    for port in range(0, brainstem.stem.USBHub3c.NUMBER_OF_USB_PORTS):

        if port == upstreamPort:
            print("Skipping upstream port.")
        elif port == brainstem.stem.USBHub3c.PORT_ID_CONTROL_INDEX:
            print("The Control port is always enabled.")
        elif port == brainstem.stem.USBHub3c.PORT_ID_POWER_C_INDEX:
            print("The Power-C port is always enabled")
        else:
            err = chub.hub.port[port].setEnabled(True)
            print("Enabling port %d, Error: %d" % (port, err))

        time.sleep(.4) #Delay so the user can see it.


print("")
print("Getting VBus and VConn Voltage and Current")
print("Note: When in PD Mode voltage is only present after successful ")
print("      negotiation with a device.")
for port in range(0, brainstem.stem.USBHub3c.NUMBER_OF_USB_PORTS):

    vBusVoltageResult = chub.hub.port[port].getVbusVoltage()
    vBusCurrentResult = chub.hub.port[port].getVbusCurrent()
    
    print("")
    print("Vbus Voltage: %.2f, Error: %d" % 
        (vBusVoltageResult.value/1000000, vBusVoltageResult.error))
    print("Vbus Current: %.2f, Error: %d" % 
        (vBusCurrentResult.value/1000000, vBusCurrentResult.error))

    if port == brainstem.stem.USBHub3c.PORT_ID_POWER_C_INDEX:
        print("The Power-C port does not have VConn measurements")
    else :
        vConnCurrentResult = chub.hub.port[port].getVconnCurrent()
        vConnVoltageResult = chub.hub.port[port].getVconnVoltage()
        print("Vconn Current: %.2f, Error: %d" % 
            (vConnCurrentResult.value/1000000, vConnCurrentResult.error))
        print("Vconn Voltage: %.2f, Error: %d" % 
            (vConnVoltageResult.value/1000000, vConnVoltageResult.error))


#Disconnect from device.
chub.disconnect()
