# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.
import brainstem
import serial # Requires pySerial
import time

#for easy access to error constants
from brainstem.result import Result


# HARDWARE SETUP:
# This example assumes that you have a loop back cable from UART 0 TO UART 1 on
# the MTMIOSerial device.  (Remember to swap those TX/RX lines)

# Constants
RAIL_1_VOLTAGE = 5000000 #5VDC

# Example of Mac/Linux ports.  Windows would be "COM#" with "#" being replaced
# by the port number. i.e. COM5, or COM9 etc.
OUTPUT_PORT = "/dev/tty.usbmodem11ADDCC1"
BRAINSTEM_OUTPUT_PORT = 0
INPUT_PORT = "/dev/tty.usbmodem11ADDCC3"
BRAINSTEM_INPUT_PORT = 1
SERIAL_BAUDRATE = 115200
SERIAL_TIMEOUT = .5


print ("")
print ("Creating MTMIOSerial Object")
stem = brainstem.stem.MTMIOSerial()


print ("Attempting to connect to device")
#Locate and connect to the first object you find on USB
#Easy way: 1=USB, 2=TCPIP
err = stem.discoverAndConnect(brainstem.link.Spec.USB)
#Locate and connect to a specific module (replace "0x66F4859B" with your Serial Number (hex))
#result = stem.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)
if err == Result.NO_ERROR: print ("Connected")
else: print ("Failed to connect to device")


print ("")
print ("Configuring MTMIOSerial device")
err = stem.rail[1].setVoltage(RAIL_1_VOLTAGE)
print ("Rail 1 Voltage was set to %d VDC, Error: %d" % (RAIL_1_VOLTAGE, err))
err = stem.rail[1].setEnable(True)
print ("Enabling Rail 1: Error %d" % err)


# Output for this example
err = stem.uart[BRAINSTEM_OUTPUT_PORT].setEnable(1)
print ("Enabling Channel 0's Data lines: Error %d" % err)
# Input for this example
err = stem.uart[BRAINSTEM_INPUT_PORT].setEnable(1)
print ("Enabling Channel 1's Data lines: Error %d" % err)


# Communication port setup: pySerial
# //////////////////////////////////////////////////////////////////////////////
print ("")
print ("Setting up communication port: \"%s\"" % OUTPUT_PORT)
serialOutput = serial.Serial()
serialOutput.baudrate = SERIAL_BAUDRATE
serialOutput.port = OUTPUT_PORT
serialOutput.timeout = SERIAL_TIMEOUT
print ("Port \"%s\" Configuration" % OUTPUT_PORT)
print (serialOutput)
serialOutput.open()
print ("The port: \"%s\" is open: %s" % (OUTPUT_PORT, serialOutput.is_open))


print ("")
print ("Setting up communication port: \"%s\"" % INPUT_PORT)
serialInput = serial.Serial()
serialInput.baudrate = SERIAL_BAUDRATE
serialInput.port = INPUT_PORT
serialInput.timeout = SERIAL_TIMEOUT
print ("Port \"%s\" Configuration:" % INPUT_PORT)
print (serialInput)
serialInput.open()
print ("The port: \"%s\" is open: %s" % (INPUT_PORT, serialOutput.is_open))
# //////////////////////////////////////////////////////////////////////////////


for x in range(0, 10):

    # This if/else is to show that the enable and disable do infact work
    # Note: The host machine does not know that the ports are being enabled/disabled
    # and will still send the data out (host computer), but the MTMIOSerial will
    # not output the data.  You will notice that the read it tied to
    # "numBytesWritten".  This will cause the read to "timeout" (.5 seconds)
    # becauese the host computer is under the impression that the data was written.
    if(x % 2):
        # Note: This only disables the TX lines.  The RX lines are not affected
        # by the enable and disable.  In other words you might think you can use
        # stem.uart[0].setChannelDisable(BRAINSTEM_INPUT_PORT) to disable the read,
        # but this will have no affect
        err = stem.uart[BRAINSTEM_OUTPUT_PORT].setEnable(0)
    else:
        err = stem.uart[BRAINSTEM_OUTPUT_PORT].setEnable(1)
        # Enabling and disabling the UART will cause "noise" in the read buffer
        # It is best to reset the buffer before starting again.
        serialInput.reset_input_buffer()


    print ("")
    print ("Writting to port:")
    numBytesWritten = serialOutput.write(b'Testing...')
    print ("%d Bytes were written to serial port: \"%s\"" % (numBytesWritten, OUTPUT_PORT))


    print ("Reading from port:")
    print ("The following was read from port: \"%s\": \"%s\"" % (INPUT_PORT, serialInput.read(numBytesWritten)))



print ("")
print ("Closing port: \"%s\"" % OUTPUT_PORT)
serialOutput.close()
print ("Closing port: \"%s\"" % INPUT_PORT)
serialInput.close()


print ("")
print ("Returning MTMIOSerial to its previous configuration")
err = stem.rail[1].setEnable(False)
print ("Disabling Rail 1 Error %d" % err)
err = stem.uart[BRAINSTEM_OUTPUT_PORT].setEnable(0)
print ("Disabling Channel 0's Data lines: Error %d" % err)
err = stem.uart[BRAINSTEM_INPUT_PORT].setEnable(0)
print ("Disabling Channel 1's Data lines: Error %d" % err)


print ("Disconnecting from device")
stem.disconnect()
