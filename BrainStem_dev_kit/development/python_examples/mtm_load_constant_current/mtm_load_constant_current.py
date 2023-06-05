# Copyright (c) 2019 Acroname Inc. - All Rights Reserved
#
# This file is part of the BrainStem development package.
# See file LICENSE or go to https://acroname.com/software/brainstem-development-kit for full license details.
import brainstem
# for easy access to error constants
from brainstem.result import Result
import time

# Note: This example assumes you have a device connected to the rail 0 and is
#       capable of allowing 5VDC @ 100mA.

print('\nCreating MTM-Load-1 stem and connecting to first module found')
stem = brainstem.stem.MTMLOAD1()

# Locate and connect to the first BrainStem device found (object type must match the device).
# Easy way: USB=1, TCPIP=2
result = stem.discoverAndConnect(brainstem.link.Spec.USB)
# If you want to connect to a specific module you can supply the devics serial number.
# result = stem.discoverAndConnect(brainstem.link.Spec.USB, 0x66F4859B)

# Check error
if result == Result.NO_ERROR:
    result = stem.system.getSerialNumber()
    print("Connected to MTM-Load-1 with serial number: 0x%08X" % result.value)

    # Operational modes are defined in aProtocoldefs.h (development/lib/BrainStem2/)
    # Device specific configurations/capabilities can be found in the product datasheet.
    # 0x01 = (railOperationalModeConstantCurrent(0x00) | railOperationalModeLinear(0x01))
    print('Setting load rail 0 to constant current mode\n')
    stem.rail[0].setOperationalMode(0x01)  # this sets the operational mode to constant current and linear mode

    print('Setting load rail 0 to draw 0.1A\n')
    stem.rail[0].setCurrentSetpoint(100000)  # Current is in microamps

    print('Setting load rail 0 max voltage to 5.0V\n')
    stem.rail[0].setVoltageMaxLimit(5000000)

    print('Enabling load rail 0\n')
    stem.rail[0].setEnable(True)

    print('Allowing time for the rail to stabilize\n')
    time.sleep(1)

    voltage = stem.rail[0].getVoltage()
    print('Voltage: %d microvolts, Error: %d\n' % (voltage.value, voltage.error))

    current = stem.rail[0].getCurrent()
    print('Current: %d microamps, Error: %d\n' % (current.value, current.error))

    print('Disabling load rail 0\n')
    stem.rail[0].setEnable(False)

else:
    print('Could not find a module.\n')

# Disconnect from device.
stem.disconnect()
