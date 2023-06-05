# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.
import time
import brainstem
# for easy access to error constants
from brainstem.result import Result

# Constants
BULK_CAPTURE_CHANNEL = 0
NUM_SAMPLES = 8000
SAMPLE_RATE = 200000

print ("\nCreating MTMUSBStem Object.")
# Create MTMUSBStem object
stem = brainstem.stem.MTMUSBStem()

# Locate and connect to the first object you find on USB
# Easy way: 1=USB, 2=TCPIP
print("Attempting to connect.")
err = stem.discoverAndConnect(brainstem.link.Spec.USB)
if(err == Result.NO_ERROR):
    print("Connected")
else:
    print("Error connecting to device. Exiting.")
    exit(1)

print("")
print("Configuring Bulk capture")
print("Analog Channel: %d" % BULK_CAPTURE_CHANNEL)
print("Number of Samples: %d" % NUM_SAMPLES)
print("Sample Rate: %d" % SAMPLE_RATE)
# Setup Analog Entity for Bulk capture configuration
stem.analog[BULK_CAPTURE_CHANNEL].setBulkCaptureNumberOfSamples(NUM_SAMPLES)
stem.analog[BULK_CAPTURE_CHANNEL].setBulkCaptureSampleRate(SAMPLE_RATE)

print("")
print("Starting bulk capture")
captureState = 0
stem.analog[BULK_CAPTURE_CHANNEL].initiateBulkCapture()
# Wait for Bulk Capture to finish.
# You can go do other stuff if you would like... Including other BrainStem functions.
# but you will need to check that it is finished before unloading the data
while(captureState != brainstem.stem.Analog.BULK_CAPTURE_FINISHED):
    if(captureState == brainstem.stem.Analog.BULK_CAPTURE_ERROR):
        print("There was an Error with Bulk Capture")
        break
    captureState = stem.analog[BULK_CAPTURE_CHANNEL].getBulkCaptureState().value
    time.sleep(.1)

print("Unloading data from device")
data = stem.store[brainstem.stem.Store.RAM_STORE].unloadSlot(0)
values = bytearray(data.value)

# Process 8bit values 2 bytes at a time for a 16bit value (Little Endian)
# i.e.
# val[0] = XXXXXXXX = LSB's
# val[1] = YYYYYYYY = MSB's
# combinedVal = YYYYYYYY XXXXXXXX for a 16 bit value
# Repeat until all the data has been processed
# Note: ",2" increments loop counter "i" by 2
print("")
for i in range(0, len(values)-1, 2):
    combinedValue = ((values[i]) + (values[i+1] << 8))
    print ("Sample: %d \tVoltage: %.3f \tRaw: %d" % (i/2, (combinedValue/65535.0)*3.3, combinedValue))

print("Disconnecting from Device")
stem.disconnect()
