# Copyright (c) 2018 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.

import brainstem
# For easy access to error constants
from brainstem.result import Result
from time import sleep

# The common side USB is always channel 0 on the USBCSwitch.
USBC_COMMON = 0

# Defines for enabling and disabling the mux channel.
ENABLE = 1
DISABLE = 0

# Number of times current and voltage will be printed.
LOOP_MAX = 5


def main():
    """ This Example shows basic interaction with the USB-C-Switch.
        Please see the the product datasheet and the reference material at: http://acroname.com/reference
            1. Create a switch object and connect.
            2. Set up the mux channel to channel 0, enable the common side
               via the USB entity, and enable the mux side.
            3. Disable the connection on the common side via the USB entity.
            4. Change the mux channel to channel 1.
            5. Enable the connection on the common side via the USB entity.
            6. Poll current and voltage once a second for LOOP_MAX seconds.
            7. Disable the connection on the mux side via mux.setEnable.
            8. Change the mux channel to channel 1.
            9. Enable the connection on the mux side via mux.setEnable.
    """

    # Create an instance of a USBCSwitch module.
    cswitch = brainstem.stem.USBCSwitch()

    # Locate and connect to the first object you find on USB
    # Easy way: 1=USB, 2=TCPIP
    result = cswitch.discoverAndConnect(brainstem.link.Spec.USB)
    # Locate and connect to a specific module (replace you with Your Serial Number (hex))
    # result = cswitch.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)

    # Check error
    if result == Result.NO_ERROR:
        result = cswitch.system.getSerialNumber()
        print ("Connected to USB-C-Switch with serial number: 0x%08X" % result.value)

        # Initial port setup.
        # Mux select channel 0, USB common side enabled, Mux side enabled.
        err = cswitch.mux.setChannel(0)
        if err != Result.NO_ERROR:
            print ("Error %d encountered changing the channel." % err)
            exit(1)
        else:
            print ("Switched to mux channel 0.")

        err = cswitch.usb.setPortEnable(USBC_COMMON)
        if err != Result.NO_ERROR:
            print ("Error %d encountered enabling the connection." % err)
            exit(1)
        else:
            print ("Enabled the connection on the common (USB) side.")

        err = cswitch.mux.setEnable(ENABLE)
        if err != Result.NO_ERROR:
            print ("Error %d encountered enabling the connection on the mux side." % err)
            exit(1)
        else:
            print ("Enabled the connection on the mux side.")

        err = cswitch.usb.setPortDisable(USBC_COMMON)
        if err != Result.NO_ERROR:
            print ("Error %d encountered disabling connection." % err)
            exit(1)
        else:
            print ("Disabled connection on the common (USB) side.")

        # Change the mux channel to channel 1.
        err = cswitch.mux.setChannel(1)
        if err != Result.NO_ERROR:
            print ("Error %d encountered changing the channel." % err)
            exit(1)
        else:
            print ("Switched to mux channel 1.")

        # Using the usb entity enable the connection.
        err = cswitch.usb.setPortEnable(USBC_COMMON)
        if err != Result.NO_ERROR:
            print ("Error %d encountered enabling the connection." % err)
            exit(1)
        else:
            print ("Enabled the connection on the common (USB) side.")

        # Loop for LOOP_MAX seconds printing current and voltage.
        for i in range(0, LOOP_MAX):
            micro_volts = cswitch.usb.getPortVoltage(USBC_COMMON)
            micro_amps = cswitch.usb.getPortCurrent(USBC_COMMON)
            if micro_volts.error == Result.NO_ERROR and micro_amps.error == Result.NO_ERROR:
                print("Port Voltage: %d uV, Port Current: %d uA " % (micro_volts.value, micro_amps.value))
            else:
                print("Error encountered getting port voltage and current.")
                exit(1)

            sleep(1)

        # Using the mux, disable the connection.
        #    Note: This has essentially the same effect as disabling the connection
        #          at the common side, except that it will not affect any of the USB
        #          port settings where the usb entity call directly affects these settings.
        err = cswitch.mux.setEnable(DISABLE)
        if err != Result.NO_ERROR:
            print ("Error %d encountered disabling the connection on the mux side." % err)
            exit(1)
        else:
            print ("Disabled the connection on the mux side.")

        # Change the mux channel to channel 0.
        err = cswitch.mux.setChannel(0)
        if err != Result.NO_ERROR:
            print ("Error %d encountered changing the channel." % err)
            exit(1)
        else:
            print ("Switched to mux channel 0.")

        err = cswitch.mux.setEnable(ENABLE)
        if err != Result.NO_ERROR:
            print ("Error %d encountered enabling the connection." % err)
            exit(1)
        else:
            print ("Enabled port via mux.")

        # Disconnect from device.
        cswitch.disconnect()

    else:
        print ('Could not find a module.\n')


if __name__ == '__main__':
    main()
