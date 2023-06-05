# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.
import brainstem
#for easy access to error constants
from brainstem.result import Result
import time

# Create USBHub2x4 object and connecting to the first module found
print ('\nCreating USBHub3+ stem and connecting to first module found')
stem = brainstem.stem.USBHub3p()

#Locate and connect to the first object you find on USB
#Easy way: 1=USB, 2=TCPIP
result = stem.discoverAndConnect(brainstem.link.Spec.USB)
#Locate and connect to a specific module (replace you with Your Serial Number (hex))
#result = stem.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)

#Check error
if result == (Result.NO_ERROR):
    result = stem.system.getSerialNumber()
    print ("Connected to USBHub3+ with serial number: 0x%08X" % result.value)
    print ('Flashing the user LED and toggling the ports\n')
    for i in range(1, 11):
        for port in range(0, 8):
            #Turn all ports on and off.
            if i%2 == 0:
                stem.usb.setPortEnable(port)
                #stem.usb.setPowerEnable(port)     #for independent power control
                #stem.usb.setDataEnable(port)      #for independent data control
            else:
                stem.usb.setPortDisable(port)
                #stem.usb.setPowerDisable(port)    #for independent power control
                #stem.usb.setDataDisable(port)     #for independent data control

        # Turn user LED on and off
        stem.system.setLED(i % 2)
        time.sleep(2)
else:
    print ('Could not find a module.\n')

#Disconnect from device.
stem.disconnect()
