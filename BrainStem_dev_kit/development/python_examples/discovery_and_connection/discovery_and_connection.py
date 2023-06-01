#
#  main.py
#  BrainStem2Example
#
###################################################################
#                                                                 #
# Copyright (c) 2019 Acroname Inc. - All Rights Reserved          #
#                                                                 #
# This file is part of the BrainStem release. See the license.txt #
# file included with this package or go to                        #
# https:#acroname.com/software/brainstem-development-kit          #
# for full license details.                                       #
###################################################################


##########################################################################
# This example shows the various ways to discover and connect to BrainStem
# modules/devices.
# NOTE: Not all functions will be successful.  Many of the examples will
#      require slight modification in order to work with your device.
#      Please refer to the individual notes/comments in and around
#      each function.
##########################################################################

import brainstem
# for easy access to error constants
from brainstem.result import Result


# discoverAndConnect_Example:
#############################################################################
# This is the most common form of connection. The discovery and connection
# process is enveloped into a single function.
#
# PITFALL: This function requires that the object type matches the device
#          you are attempting to connect too and will likely require modification
#          in order to work properly.
###############################################################################
def discoverAndConnect_Example():

    # TODO
    # Uncomment the object that matches your device.

    # stem = brainstem.stem.USBStem()
    # stem = brainstem.stem.EtherStem()
    # stem = brainstem.stem.MTMEtherStem()
    # stem = brainstem.stem.MTMIOSerial()
    # stem = brainstem.stem.MTMUSBStem()
    # stem = brainstem.stem.MTMPM1()
    # stem = brainstem.stem.MTMRelay()
    # stem = brainstem.stem.USBHub2x4()
    stem = brainstem.stem.USBHub3p()
    # stem = brainstem.stem.USBCSwitch()
    # stem = brainstem.stem.MTMDAQ1()
    # stem = barinstem.stem.MTMDAQ2()

    # When no serial number is provided discoverAndConnect will attempt to
    # connect to the first module it finds.  If multiple BrainStem devices
    # are connected to your machine it is unknown which device will be
    # discovered first.
    # Under the hood this function uses findFirstModule()

    print("\nStarting DiscoverAndConnect(USB) example.")

    err = stem.discoverAndConnect(brainstem.link.Spec.USB)
    if err != Result.NO_ERROR:
        print("Unable to find BrainStem module. Error: %s.\n" % err)
        print("Are you using the correct module/object type?")
    else:
        print("Found and connected to a BrainStem module. \n")
        serial_number = stem.system.getSerialNumber()
        stem.disconnect()

        # discoverAndConnect has an overload which accepts a Serial Number.
        # The example immediately above will attempt to fetch the serial number
        # and use it in this example. Feel free to drop in the
        # serial number of your device.
        # Under the hood this function uses a combination of findAllModules() and
        # connectFromSpec().

        # TODO
        # Put the SN of your device here.
        user_serial_number = serial_number.value

        print("Starting DiscoverAndConnect(USB, serial_number) example. ")
        err = stem.discoverAndConnect(brainstem.link.Spec.USB, user_serial_number)
        if err != Result.NO_ERROR:
            print("Unable to find BrainStem module. Error: %s.\n" % err)
            print("Are you using the correct module/object type?")
        else:
            print("Found and connected to a BrainStem module. \n")
        stem.disconnect()
        print("Finished with DiscoverAndConnect example.\n"
              "------------------------------------------- \n")
# end of Discover and Connect example
##########################################################################

# findAllModules_Example:
##########################################################################
# Highlights how to discover and integrate multiple BrainStem devices
# without connecting to them.
# This is especially helpful for device agnostic applications.'
###########################################################################
def findAllModules_Example():

    print("Starting findAllModules(USB) example.\n")
    specList = brainstem.discover.findAllModules(brainstem.link.Spec.USB)
    if not specList:
        print("No devices discovered over USB.")
    else:
        for spec in specList:
            print("Model: ", spec.model)
            print("Module: ", spec.module)
            print("Serial Number: ", spec.serial_number)
            print("Transport: ", spec.transport)
            print("")

    print("Starting findAllModules(TCPIP) example")
    specList = brainstem.discover.findAllModules(brainstem.link.Spec.TCPIP)
    if not specList:
        print("No devices discovered over TCPIP.\n")
    else:
        for spec in specList:
            print("Model: ", spec.model)
            print("Module: ", spec.module)
            print("Serial Number: ", spec.serial_number)
            print("Transport: ", spec.transport)
            print("")

    print("End of findAllModules example. \n"
          "------------------------------------------- \n")
##########################################################################

# findFirstModule_Example:
##########################################################################
# This example will return the linkSpec object of the first device it
# finds.  The linkSpec object can then be used to connect to a device via
# the connectFromSpec function.
##########################################################################
def findFisrtModule_Example():

    print("Starting findFirstModule(USB) example.")
    spec = brainstem.discover.findFirstModule(brainstem.link.Spec.USB)
    if not spec:
        print("No devices found over USB.\n")
    else:
        print("Discovered and connected to BrainStem device.\n")
        print("Model: ", spec.model)
        print("Module: ", spec.module)
        print("Serial Number: ", spec.serial_number)
        print("Transport: ", spec.transport)

    print("\nStarting findFirstModule(TCPIP) example.")
    spec = brainstem.discover.findFirstModule(brainstem.link.Spec.TCPIP)
    if not spec:
        print("No devices found over TCPIP.")
    else:
        print("Discovered and connected to BrainStem device.")
        print("Model: ", spec.model)
        print("Module: ", spec.module)
        print("Serial Number: ", spec.serial_number)
        print("Transport: ", spec.transport)
    print("\nEnd of findFirstModule example. \n"
          "------------------------------------------- \n")
##########################################################################

# findModule_Example:
##########################################################################
# This example will connect to any BrainStem device given its serial
# number. It will not connect without a SN.
##########################################################################
def findModule_Example():

    print("Starting findModule(USB, SN) example.\n")

    # TODO:
    # Add the serial number of your device here.
    serial_number = 0xB971001E

    spec = brainstem.discover.findModule(brainstem.link.Spec.USB, serial_number)
    if not spec:
        print("No devices found over USB.\n")
    else:
        print("Discovered and connected to BrainStem device.")
        print("Model: ", spec.model)
        print("Module: ", spec.module)
        print("Serial Number: ", spec.serial_number)
        print("Transport: ", spec.transport)

    print("\nStarting findModule(TCPIP, SN) example.")
    spec = brainstem.discover.findModule(brainstem.link.Spec.TCPIP, serial_number)
    if not spec:
        print("No devices found over TCPIP.\n")
    else:
        print("Discovered and connected to BrainStem device.")
        print("Model: ", spec.model)
        print("Module: ", spec.module)
        print("Serial Number: ", spec.serial_number)
        print("Transport: ", spec.transport)

    print("\nEnd of findModule example. \n"
          "------------------------------------------- \n")
##########################################################################

# connectFromSpec_Example:
##########################################################################
# Many of the discovery functions will return a linkSpec object.
# This function shows how to use that object to connect to a BrainStem
# device.
# The benefit of this connection method is that it does not care
# about which BrainStem object you use.
# i.e. you can connect to a USBHub3p from a USBStem object. However,
# the USBStem object does not possess a USB Entity and therefor will not be
# able to control the USBHub3p correctly. This is typically not
# recommended.
###########################################################################
def connectFromSpec_Example():

    print("Starting connectFromSpec(Spec) example.")

    stem = brainstem.stem.USBHub3p()
    spec = brainstem.discover.findFirstModule(brainstem.link.Spec.USB)
    if not spec:
        print("No devices found.")
    else:
        err = stem.connectFromSpec(spec)
        if err != Result.NO_ERROR:
            print("Unable to connect to module. Error: ", err)
        else:
            print("Successfully connected to BrainStem module.")
            stem.disconnect()

    print("\nEnd of connectFromSpec example. \n"
          "------------------------------------------- \n")
##########################################################################



# connectThroughLinkModule_Example:
##########################################################################
# This function allows a device to share the connection of another device.
# This feature is only available for Acroname's MTM and 40pin devices.
#
# In this example we have a MTMUSBStem and a MTMDAQ2 connected to a BrainStem
# development board.  The board is powered and ONLY the MTMUSBStem is connected
# to the computer via USB cable.  The MTMDAQ2 will connect to the PC through the
# MTMUSBStem via the BrainStem Network (I2C) which is wired through the
# development board.
###########################################################################
def connectThroughLinkModule_Example():

    print("Starting connectThroughLinkModule example.")

    # Create the devices required for this example
    mtmstem = brainstem.stem.MTMUSBStem()
    mtmdaq2 = brainstem.stem.MTMDAQ2()

    err = mtmstem.discoverAndConnect(brainstem.link.Spec.USB)
    if err != Result.NO_ERROR:
        print("Unable to find BrainStem module. Error: %s.\n" % err)
        print("Are you using the correct module/object type?")
    else:
        print("Found and connected to a MTMUSBStem. \n")

        # Each module has a "router" address.  This address defines the I2C network.
        # By default this value is set to the devices module address.  In order
        # for devices to communicate on the BrainStem Network all devices must have
        # the router address of the link stem.  In this example the MTMUSBStem is the
        # the link stem.  When the routeToMe function is called the device will broadcast
        # to all devices on the network.  0 = default configuration, 1 = Instructs all modules
        # to change their router address to that of the broadcaster.
        err = mtmstem.system.routeToMe(1)
        if err == Result.NO_ERROR:
            # Now that the MTMUSBStem connection is up and running we can
            # use its connection to connect to the MTMDAQ2.
            err = mtmdaq2.connectThroughLinkModule(mtmstem)
            if err != Result.NO_ERROR:
                print("Unable to connect to MTMDAQ2 through the MTMUSBStem: %s.\n" % err)
            else:
                print("Connected to MTMDAQ2 through the MTMUSBStem\n")
                # Once connected you can use the device normally.
                LED_result = mtmstem.system.getLED()
                if LED_result.error == Result.NO_ERROR:
                    string_val = "Off" if LED_result.value == 0 else "On"
                    print("MTMUSBStem's User LED: %s\n" % string_val)
                LED_result = mtmdaq2.system.getLED()
                if LED_result.error == Result.NO_ERROR:
                    string_val = "Off" if LED_result.value == 0 else "On"
                    print("MTMDAQ2's User LED: %s\n" % string_val)

                # You should disconnect in the reverse order in which you connected.
                mtmdaq2.disconnect()

        # Reset all network routers back to their default configurations.
        mtmstem.system.routeToMe(0)
        mtmstem.disconnect()
    print("\nEnd of connectThroughLinkModule example. \n"
          "------------------------------------------- \n")
##########################################################################


if __name__ == '__main__':
    discoverAndConnect_Example()
    findAllModules_Example()
    findFisrtModule_Example()
    findModule_Example()
    connectFromSpec_Example()
    connectThroughLinkModule_Example()
    print("FINISHED WITH ALL EXAMPLES!")
