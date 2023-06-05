###############################################################################
# Filename: led_test.py
# Prepared By: James Dudley
# Date Prepared: February 26, 2018
# Date Revised: February 26, 2018
# Revision: 0.0.1
###############################################################################

import brainstem        # import BrainStem API
from brainstem.result import Result     # for easy access to error constants
from time import sleep

RESISTOR_VALUE = 412    # Current-limiting resistor value, Ohms
POWER_VOLTAGE = 5000000 # LED power voltage setpoint, uV
DAC = 16        # Analog output index for LED power
CURRENT = 14    # Differential analog input index for current measurement
VOLTAGE = 0     # Single-ended analog input index for voltage measurement

# Generic function to run BrainStem commands with error checking
def step(func, func_str, *args):
    print '>> ' + func_str[0].upper() + func_str[1:]    # Capitalize first letter of string
    res = func(*args)
    err = val = res
    if isinstance(err, Result):
        err = res.error
        val = res.value

    if err is not Result.NO_ERROR:
            raise Exception('Error %s: %d' % (func_str, err))

    return val


def main():
    # Create MTM-DAQ-1 object
    daq = brainstem.stem.MTMDAQ1()      # Uses default module address

    # Initialize error tracker
    err = Result.NO_ERROR

    try:
        # Discover and connect to MTM-DAQ-1 object
        # Connects to the first USB module discovered
        step(daq.discoverAndConnect, 'connecting to MTM-DAQ-1', brainstem.link.Spec.USB)

        # Run the test twice, once with LED power enabled, once with it disabled
        for enable, enable_str in zip([1, 0],['enabled', 'disabled']):
            # Set MTM-DAQ-1 DAC0 (analog 16) to 5V and enable to power LED
            step(daq.analog[DAC].setVoltage,'setting DAC voltage', POWER_VOLTAGE)    # uV
            step(daq.analog[DAC].setEnable,'setting DAC enable to %s' % enable_str, enable)     # enable DAC0

            # Set measurement ranges
            step(daq.analog[VOLTAGE].setRange, 'setting Position B analog range to +/-10.24V', 12)   # range value from datasheet
            step(daq.analog[CURRENT].setRange, 'setting Position A->B analog range to +/-5.12V', 9)    # range value from datasheet

            sleep(1)    # Leave the LED on/off for a second

            # Read voltage measurements
            v = step(daq.analog[VOLTAGE].getVoltage, 'reading Position B voltage')
            v_current = step(daq.analog[CURRENT].getVoltage, 'reading Position A-B differential voltage')

            # Calculate current
            i = v_current / RESISTOR_VALUE      # I = V / R

            print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
            print 'MTM-DAQ-1 DAC0 status: %s' % enable_str
            print 'Position B voltage (uV): %d' % v
            print 'Position B voltage (V): %.3f' % (v / 1e6)
            print 'Position A->B voltage (uV): %d' % v_current
            print 'Position A->B current (uA): %d' % i
            print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'

        step(daq.analog[DAC].setEnable, 'disabling DAC', 0)

    except Exception as exc:
        print exc

    finally:
        daq.disconnect()    # Clean up possible remaining connections
        del daq     # Clean up MTM-DAQ-1 object


if __name__ == '__main__':
    main()
