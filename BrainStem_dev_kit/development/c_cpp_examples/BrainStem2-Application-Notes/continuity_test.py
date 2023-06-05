###############################################################################
# Filename: continuity_test.py
# Prepared By: James Dudley
# Date Prepared: March 5, 2018
# Date Revised: March 5, 2018
# Revision: 0.0.1
###############################################################################

import brainstem        # Import BrainStem API
from brainstem.result import Result     # For easy access to error constants
from time import sleep, time

CONTINUITY_PAIRS = [[0, 9], [1, 10], [2, 11], [3, 12], [4, 13], [5, 14]]    # [output, input]
CYCLE_TIME = 0.2    # Time to pause between readings, seconds

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
    # Create MTM-USBSTEM object
    stem = brainstem.stem.MTMUSBStem()      # Uses default module address

    # Initialize error tracker
    err = Result.NO_ERROR

    try:
        # Discover and connect to MTM-PM-1 object
        # Connects to the first USB module discovered
        step(stem.discoverAndConnect, 'connecting to MTM-USBStem', brainstem.link.Spec.USB)

        # Set DIO configurations
        for pair in CONTINUITY_PAIRS:
            output_dio = pair[0]
            input_dio = pair[1]
            step(stem.digital[output_dio].setConfiguration, 'configuring DIO%d as output' % output_dio, 1)    # Configuration value from datasheet
            step(stem.digital[input_dio].setConfiguration, 'configuring DIO%d as input with pull-down' % input_dio, 5)    # Configuration value from datasheet

        # Test continuity between pairs
        continuity_array = []
        for pair in CONTINUITY_PAIRS:
            output_dio = pair[0]
            input_dio = pair[1]

            # Check continuity by raising the output HI (1), then LO (0) and verifying
            # the corresponding input follows
            bContinuous = True
            for state in [1, 0]:
                step(stem.digital[output_dio].setState, 'setting DIO%d to %d' % (output_dio, state), state)

                sleep(CYCLE_TIME)

                read_state = step(stem.digital[input_dio].getState, 'getting DIO%d state' % input_dio)

                if read_state != state:
                    bContinuous = False

            continuity_array.append([bContinuous, output_dio, input_dio])

        print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
        for idx in continuity_array:
            if idx[0]:
                print 'DIO%d -- DIO%d: Continuous' % (idx[1], idx[2])
            else:
                print 'DIO%d -- DIO%d: Discontinuous' % (idx[1], idx[2])
        print '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'

    except Exception as exc:
        print exc

    finally:
        stem.disconnect()    # Clean up possible remaining connections
        del stem     # Clean up MTM-USBSTEM object


if __name__ == '__main__':
    main()
