###############################################################################
# Filename: short_test.py
# Prepared By: James Dudley
# Date Prepared: March 2, 2018
# Date Revised: March 2, 2018
# Revision: 0.0.1
###############################################################################

import brainstem        # Import BrainStem API
from brainstem.result import Result     # For easy access to error constants
from time import sleep, time

RAIL = 1            # Power rail to use for test
VOLTAGE = 3300000   # Set voltage for Rail 0
CYCLE_TIME = 0.2    # Time to pause between readings, seconds
TOTAL_TIME = 5      # Time to keep test running, seconds

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
    # Create MTM-PM-1 object
    pm = brainstem.stem.MTMPM1()      # Uses default module address

    # Initialize error tracker
    err = Result.NO_ERROR

    try:
        # Discover and connect to MTM-PM-1 object
        # Connects to the first USB module discovered
        step(pm.discoverAndConnect, 'connecting to MTM-PM-1', brainstem.link.Spec.USB)

        if RAIL is 0:
            # Set Rail voltage
            step(pm.rail[RAIL].setVoltage,'setting Rail %d voltage to %d' % (RAIL, VOLTAGE), 1)

        # Enable Rail
        step(pm.rail[RAIL].setEnable,'enabling Rail %d' % RAIL, 1)

        enable_str = ['OFF', 'ON']
        tStart = tNow = time()
        while tNow < tStart + TOTAL_TIME:
            tNow = time()
            # Get MTM-PM-1 Rail enable state
            enable = step(pm.rail[RAIL].getEnable, 'reading Rail %d enable state' % RAIL)

            # Read MTM-PM-1 Rail voltage
            v = step(pm.rail[RAIL].getVoltage, 'reading Rail %d voltage' % RAIL)

            print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
            print 'Enable State: %s' % enable_str[enable]
            print 'Rail voltage (V): %.3f' % (v / 1.e6)
            print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'

            sleep(CYCLE_TIME)

        step(pm.rail[RAIL].setEnable, 'disabling Rail %d' % RAIL, 0)

    except Exception as exc:
        print exc

    finally:
        pm.disconnect()    # Clean up possible remaining connections
        del pm     # Clean up MTM-PM-1 object


if __name__ == '__main__':
    main()
