###############################################################################
# Filename: brainstem_network.py
# Prepared By: James Dudley
# Date Prepared: March 7, 2018
# Date Revised: March 7, 2018
# Revision: 0.0.1
###############################################################################

import brainstem        # Import BrainStem API
from brainstem.result import Result     # For easy access to error constants
from time import sleep, time

USB_CHANNEL = 0
RAIL0_SET_VOLTAGE = 2200000     # Set voltage for MTM-PM-1 Rail 0
RAIL1_SET_VOLTAGE = 2800000     # Set voltage for MTM-IO-SERIAL Rail 1
CYCLE_TIME = 0.02    # Time to pause between readings, seconds

# Generic function to run BrainStem commands with error checking
def step(func, func_str, *args):
    print '>> ' + func_str[0].upper() + func_str[1:]    # Capitalize first letter of string
    res = func(*args)
    err = val = res
    if isinstance(val, Result):
        err = res.error
        val = res.value
    else:
        err = Result.NO_ERROR

    if err is not Result.NO_ERROR:
            raise Exception('Error %s: %d' % (func_str, err))

    return val


def main():
    # Create each MTM object
    # Apply a module offset of 24 to the MTM-PM-1 module (determined by the DIP switch on the development board)
    ioserial = brainstem.stem.MTMIOSerial()     # Uses default module address
    # Module offset is applied simply to demonstrate module offset, and is not strictly required in this case
    # Make sure the DIP switch for MTM-PM-1 is set to 1-1-0-0 (0b1100 * 2 = offset of 24)
    pm = brainstem.stem.MTMPM1(brainstem.stem.MTMPM1.BASE_ADDRESS + 24)
    stem = brainstem.stem.MTMUSBStem()          # Uses default module address

    # Initialize error tracker
    err = Result.NO_ERROR

    try:
        # Discover and connect to MTM-IO-SERIAL object
        # First, get a list of all available USB modules (Note: MTM-PM-1 shows up because there's a pass-through
        # USB channel on the MTM-IO-SERIAL, which is connected to the MTM-PM-1 edge connector USB on the development board)
        spec_array = step(brainstem.discover.findAllModules, 'discover USB modules', brainstem.link.Spec.USB)
        # Next, iterate through each link Spec in the array and connect if it's the MTM-IO-SERIAL module
        for spec in spec_array:
            if spec.model == brainstem.defs.MODEL_MTM_IOSERIAL:
                step(ioserial.connectFromSpec, 'connecting to MTM-IO-SERIAL from spec', spec)
                break
        connection_status = step(ioserial.isConnected, 'checking MTM-IO-SERIAL connection status')
        if connection_status is not True:
            raise Excepetion('Error finding MTM-IO-SERIAL module: no MTM-IO-SERIAL link Spec discovered')

        # Connect the MTM-PM-1 and MTM-USBSTEM modules over the BrainStem network,
        # using the MTM-IO-SERIAL as the primary module.
        step(pm.connectThroughLinkModule, 'connecting to MTM-PM-1 over BS network', ioserial)
        step(stem.connectThroughLinkModule, 'connecting to MTM-USBSTEM over BS network', ioserial)

        # Set both modules to route through the MTM-IO-SERIAL module (turn "ON" ioserial.routeToMe)
        step(ioserial.system.routeToMe, 'setting MTM-IO-SERIAL routeToMe', 1)

        # Try out a few examples of functionality from each MTM module

        # 1 - Set MTM-PM-1 Rail 0 and measure the voltage using MTM-USBSTEM A2D0
        step(pm.rail[0].setVoltage, 'setting Rail 0 voltage to %.3fV' % (RAIL0_SET_VOLTAGE/1.e6), RAIL0_SET_VOLTAGE)
        step(pm.rail[0].setEnable, 'enabling Rail 0', 1)
        sleep(CYCLE_TIME)
        a2d0_voltage = step(stem.analog[0].getVoltage, 'reading A2D0 voltage')

        print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
        print 'MTM-PM-1 Rail 0:  %.3fV' % (RAIL0_SET_VOLTAGE/1.e6)
        print 'MTM-USBSTEM A2D0: %.3fV' % (a2d0_voltage / 1.e6)
        print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'

        # 2 - (optional) Toggle MTM-IO-SERIAL USB channel on/off
        step(ioserial.usb.setPortEnable, 'enabling USB channel %d' % USB_CHANNEL, USB_CHANNEL)
        raw_input('Verify USB device enumeration (optional) and press Enter to continue...')
        step(ioserial.usb.setPortDisable, 'disabling USB channel %d' % USB_CHANNEL, USB_CHANNEL)

        # 3 - Set MTM-IO-SERIAL Rail 1 and measure the voltage using MTM-USBSTEM A2D1
        step(ioserial.rail[1].setVoltage, 'setting Rail 1 voltage to %.3fV' % (RAIL1_SET_VOLTAGE/1.e6), RAIL1_SET_VOLTAGE)
        step(ioserial.rail[1].setEnable, 'enabling Rail 1', 1)
        sleep(CYCLE_TIME)
        a2d1_voltage = step(stem.analog[1].getVoltage, 'reading A2D1 voltage')
        print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
        print 'MTM-IO-SERIAL Rail 1: %.3fV' % (RAIL1_SET_VOLTAGE/1.e6)
        print 'MTM-USBSTEM A2D1:     %.3fV' % (a2d1_voltage / 1.e6)
        print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'

    except Exception as exc:
        print exc

    finally:
        stem.disconnect()    # Clean up possible remaining connections
        pm.disconnect()
        ioserial.disconnect()
        del stem     # Clean up MTM objects
        del pm
        del ioserial


if __name__ == '__main__':
    main()
