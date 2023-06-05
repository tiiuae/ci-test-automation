# Copyright (c) 2019 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem release. See the license.txt
# file included with this package or go to
# https://acroname.com/software/brainstem-development-kit
# for full license details.

"""
This Example shows creating a signal loopback with the MTMUSBStem. Since this is a
signal loopback, this example assumes you have a jumper cable connection between Digital pins
6 and 4. Please see the product datasheet and the reference material at: http://acroname.com/reference
    1. Create a MTMUSBStem object and connect.
    2. Configure the MTMUSBStem to output a square wave via digital pin 6.
    3. Set the T3 Time for signal entity 2 to 100000000.
    4. Get and display the T3 Time for signal 2.
    5. Set the T2 Time for signal entity 2 to 50000000.
    6. Get and display the T2 Time for signal entity 2.
    7. Enable the signal output on signal entity 2.
    8. Configure the MTMUSBStem to receive a square wave via digital pin 4.
    9. Enable the signal input on signal entity 0.
    10. Get and display the T3 Time for signal entity 0.
    11. Get and display the T2 Time for signal entity 0.
    12. Calculate the Duty Cycle with the read T3 and T2 values.
    13. Disable signal entity 2.
    14. Disable signal entity 0.
    15. Disconnect from the MTMUSBStem object.
"""

import brainstem

from brainstem.result import Result
from brainstem.stem import Digital
from time import sleep

print("Creating a signal loopback, between digital pins 6 and 4 with a MTMUSBStem module\n")

# Lookup Table for Signal to Digital Mapping
# The indicies refer to the signal [0-4], while the values
# held in those indicies refer to the digital pins they
# are associated with.
# Note: This Lookup Table is for the MTMUSBStem only.
# Digital Entity to Signal Entity mapping varies per
# device. Please refer to the data sheet for the MTM
# Device you are using to see its unique mapping.
SIGNAL_TO_DIGITAL_MAPPING = [4, 5, 6, 7, 8]

# Preset T Times. Editable by user
T3_TIME = 100000000
T2_TIME = 50000000

# Signal Entity indexs to be used for input and output.
SIGNAL_OUTPUT_IDX = 2;
SIGNAL_INPUT_IDX = 0;

# Find the first BrainStem Module connected and store its Spec in spec
spec = brainstem.discover.findFirstModule(brainstem.link.Spec.USB)

# If there is no spec...
if spec is None:
    # ...there is no reason to continue
    print("Could not find any BrainStem Modules")
# Else, let's continue
else:
    # Create a MTMUSBStem object
    stem = brainstem.stem.MTMUSBStem()
    # Connect to this object using the serial number contained in spec.
    # This serial number should be the serial number of the MTMUSBStem
    # currently connected.
    err = stem.connect(spec.serial_number)
    # If there was a connection error...
    if err != Result.NO_ERROR:
        # ...there is no reason to continue
        print("Error %d encountered connecting to Brainstem Module" % err)
    # Else, let's continue
    else:
        # Output

        # Initialize the boolean which denotes whether a fatal error has occurred
        fatal_error_occurred = False

        # Configure the MTMUSBStem to output a square wave via digital pin 6
        err = stem.digital[SIGNAL_TO_DIGITAL_MAPPING[SIGNAL_OUTPUT_IDX]].setConfiguration(Digital.CONFIGURATION_SIGNAL_OUTPUT)
        # If there was an error...
        if err != Result.NO_ERROR:
            # ...the digital pin signal output was NOT configured successfully
            fatal_error_occurred = True
            print("Error %d encountered attempting to set the configuration for digital pin 6 on the MTM USB Stem" % err)

        print("\n")

        # Set the T3 Time for signal entity 2
        err = stem.signal[SIGNAL_OUTPUT_IDX].setT3Time(T3_TIME)
        # If there was an error...
        if err != Result.NO_ERROR:
            # ...T Time was NOT set successfully. There's no reason to try to get the T3 Time from signal entity 2
            fatal_error_occurred = True
            print("Error %d encountered attempting to set the T3 Time for signal entity 2 on the MTMUSBStem" % err)
        # Else, let's get the T3 Time from signal entity 2
        else:
            # Get the T3 Time from signal entity 2, and display it if it was retrieved with no error
            err_and_time = stem.signal[SIGNAL_OUTPUT_IDX].getT3Time()
            if err_and_time.error != Result.NO_ERROR:
                print("Error %d encountered attempting to get the T3 Time for signal entity 2 on the MTMUSBStem" % err_and_time.error)
            elif err_and_time.value == 0:
                fatal_error_occurred = True
                print("T3 Time cannot be 0!")
            else:
                read_t3_time_from_output_pin = err_and_time.value
                print("T3 Time from Output Pin: %d" % read_t3_time_from_output_pin)

        # Set the T2 Time for signal entity 2
        err = stem.signal[SIGNAL_OUTPUT_IDX].setT2Time(T2_TIME)
        # If there was an error...
        if err != Result.NO_ERROR:
            # ...T Time was NOT set successfully. There's no reason to try to get the T2 Time from signal entity 2
            fatal_error_occurred = True
            print("Error %d encountered attempting to set the T2 Time for signal entity 2 on the MTMUSBStem" % err)
        # Else, let's get the T2 Time from signal entity 2
        else:
            # Get the T2 Time from signal entity 2, and display it if it was retrieved with no error
            err_and_time = stem.signal[SIGNAL_OUTPUT_IDX].getT2Time()
            if err_and_time.error != Result.NO_ERROR:
                print("Error %d encountered attempting to get the T2 Time for signal entity 2 on the MTMUSBStem" % err_and_time.error)
            else:
                read_t2_time_from_output_pin = err_and_time.value
                print("T2 Time from Output Pin: %d" % read_t2_time_from_output_pin)

        print("\n")

        # Enable the signal ouput on signal entity 2
        err = stem.signal[SIGNAL_OUTPUT_IDX].setEnable(True)
        # If there was an error...
        if err != Result.NO_ERROR:
            #  ...signal output on signal entity 2 was NOT enabled
            fatal_error_occurred = True
            print("Error %d encountered attempting to set the signal enabled state of signal 2 to true on the MTMUSBStem" % err)
            print("\n")

        # If digital pin 6 was not configured successfully, T Time was not set successfully, or signal output on signal entity 2 was not enabled successfully...
        if fatal_error_occurred:
            # ...there is no reason to continue
            print("A Fatal Error occurred in the Output phase. Aborting example!")
        # Else, let's continue
        else:
            # Input

            # Configure the MTMUSBStem to take in a square wave via digital pin 4
            err = stem.digital[SIGNAL_TO_DIGITAL_MAPPING[SIGNAL_INPUT_IDX]].setConfiguration(Digital.CONFIGURATION_SIGNAL_INPUT)
            if err != Result.NO_ERROR:
                fatal_error_occurred = True
                print("Error %d encountered attempting to set the configuration for digital pin 4 on the MTMUSBStem" % err)
                print("\n")

            # Enable the signal input on signal entity 0
            err = stem.signal[SIGNAL_INPUT_IDX].setEnable(True)
            if err != Result.NO_ERROR:
                fatal_error_occurred = True
                print("Error %d encountered attempting to set the signal enabled state of signal 0 to true on the MTMUSBStem" % err)
                print("\n")

            # Sleep for 500ms so the ouput can stabilize and the input can have time to calculate the time high/low
            sleep(.5)

            # Get the T3 Time from signal entity 0, and display it if it is not 0 and was retrieved with an error
            err_and_time = stem.signal[SIGNAL_INPUT_IDX].getT3Time()
            if err_and_time.error != Result.NO_ERROR:
                fatal_error_occurred = True
                print("Error %d encountered attempting to get the T3 Time for signal entity 0 on the MTMUSBStem" % err_and_time.error)
            elif err_and_time.value == 0:
                fatal_error_occurred = True
                print("T3 Time cannot be 0!")
            else:
                read_t3_time_from_input_pin = err_and_time.value
                print("T3 Time from Input Pin: %d" % read_t3_time_from_input_pin)

            # Get the T2 Time from signal entity 0, and display it if it was retrieved with no error
            err_and_time = stem.signal[SIGNAL_INPUT_IDX].getT2Time()
            if err_and_time.error != Result.NO_ERROR:
                fatal_error_occurred = True
                print("Error %d encountered attempting to get the T3 Time for signal entity 0 on the MTMUSBStem" % err_and_time.error)
            else:
                read_t2_time_from_input_pin = err_and_time.value
                print("T2 Time from Input Pin: %d" % read_t2_time_from_input_pin)

            print("\n")

            # If digital pin 4 was not configured correctly, signal input on signal entity 0 was not enabled, or T Time was not read correctly
            if fatal_error_occurred:
                # ...there is no reason to continue
                print("A Fatal Error occurred in the Input phase. Aborting example!")
            # Else, let's continue
            else:
                # Compute the Duty Cycle and display it
                duty_cycle = (float(read_t2_time_from_input_pin) / float(read_t3_time_from_input_pin)) * 100.0

                print("Duty Cycle: %f" % duty_cycle)

                # Disable the signal output on signal entity 2
                err = stem.signal[SIGNAL_OUTPUT_IDX].setEnable(False)
                if err != Result.NO_ERROR:
                    print("Error %d encountered attempting to set the signal enabled state of signal entity 2 to false on the MTMUSBStem" % err)

                # Disable the signal input on signal entity 0
                err = stem.signal[SIGNAL_INPUT_IDX].setEnable(False)
                if err != Result.NO_ERROR:
                    print("Error %d encountered attempting to set the signal enabled state of signal entity 0 to false on the MTMUSBStem" % err)

        # Disconnect from the MTMUSBStem
        stem.disconnect()
