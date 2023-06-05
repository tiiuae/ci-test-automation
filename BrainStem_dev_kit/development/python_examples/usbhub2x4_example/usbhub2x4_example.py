# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.
import brainstem
#for easy access to error constants
from brainstem.result import Result
import time

# Create USBHub2x4 object and connecting to the first module found
print ('\nCreating USBHub2x4 stem and connecting to first module found')
stem = brainstem.stem.USBHub2x4()

#Locate and connect to the first object you find on USB
#Easy way: 1=USB, 2=TCPIP
result = stem.discoverAndConnect(brainstem.link.Spec.USB)
#Locate and connect to a specific module (replace you with Your Serial Number (hex))
#result = stem.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)

#Check error
if result == (Result.NO_ERROR):
    result = stem.system.getSerialNumber()
    print ("Connected to USBHub2x4 with serial number: 0x%08X" % result.value)
    print ('Flashing the user LED and toggling the ports\n')
    for i in range(1, 11):
        #Turn all ports on and off.
        if i%2 == 0:
            stem.usb.setPortEnable(0)
            #stem.usb.setPowerEnable(0)     #for independent power control
            #stem.usb.setDataEnable(0)      #for independent data control
            stem.usb.setPortEnable(1)
            stem.usb.setPortEnable(2)
            stem.usb.setPortEnable(3)
        else:
            stem.usb.setPortDisable(0)
            #stem.usb.setPowerDisable(0)    #for independent power control
            #stem.usb.setDataDisable(0)     #for independent data control
            stem.usb.setPortDisable(1)
            stem.usb.setPortDisable(2)
            stem.usb.setPortDisable(3)

        # Turn user LED on and off
        stem.system.setLED(i % 2)
        time.sleep(2)
else:
    print ('Could not find a module.\n')

#Disconnect from device.
stem.disconnect()
