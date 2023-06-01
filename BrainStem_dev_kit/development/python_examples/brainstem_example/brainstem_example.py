# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.
import brainstem
import time

#for easy access to error constants
from brainstem.result import Result

# Create USBStem object
print ('\nCreating USBStem and connecting to first module found')
stem = brainstem.stem.USBStem()
#Other Options/Examples:
#stem = brainstem.stem.USBHub2x4()
#stem = brainstem.stem.MTMUSBStem()

#Locate and connect to the first object you find on USB
#Easy way: 1=USB, 2=TCPIP
result = stem.discoverAndConnect(brainstem.link.Spec.USB)
#Locate and connect to a specific module (replace "0x66F4859B" with your Serial Number (hex))
#result = stem.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)

#Check error
if result == (Result.NO_ERROR):
    result = stem.system.getSerialNumber()
    print ("Connected to USBStem with serial number: 0x%08X" % result.value)

    #Flash the LED
    print ('Flashing the user LED\n')
    for i in range(1, 11):
        stem.system.setLED(i % 2)
        time.sleep(0.5)

else:
    print ("Could not connect to device\n")

#Disconnect from device.
stem.disconnect()
