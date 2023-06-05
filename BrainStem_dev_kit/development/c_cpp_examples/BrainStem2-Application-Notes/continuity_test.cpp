/****************************************************************
 * Filename: continuity_test.cpp
 * Prepared By: James Dudley
 * Date Prepared: March 5, 2018
 * Date Revised: March 5, 2018
 * Revision: 0.0.1
 ***************************************************************/

#include "BrainStem2/BrainStem-all.h"

#define CYCLE_TIME                   20     // Time to pause between readings, ms

uint8_t continuity_pairs[][2] = {{0, 9}, {1, 10}, {2, 11}, {3, 12}, {4, 13}, {5, 14}};
uint8_t n_cp = 6;

int main(int argc, const char * argv[]) {
    // Create BrainStem object
    aMTMUSBStem stem;

    // Initialize error tracker
    aErr err = aErrNone;

    // Discover and connect to MTM-USBStem object
    // Connects to the first USB module discovered
    err = stem.discoverAndConnect(USB);
    if (err != aErrNone) {
        printf("Error connecting to MTM-USBStem: %d\n", err);
        return 0;
    }

    // Set DIO configurations
    uint8_t idx_cp = 0;
    for (idx_cp = 0; idx_cp < n_cp; idx_cp++) {
        uint8_t output_dio = continuity_pairs[idx_cp][0];
        uint8_t input_dio = continuity_pairs[idx_cp][1];

        err = stem.digital[output_dio].setConfiguration(1);
        if (err != aErrNone) {
            printf("Error setting DIO%d configuration to output: %d\n", output_dio, err);
            return 0;
        }

        err = stem.digital[input_dio].setConfiguration(5);
        if (err != aErrNone) {
            printf("Error setting DIO%d configuration to input with pull-down: %d\n", input_dio, err);
            return 0;
        }
    }

    // Test continuity between pairs
    uint8_t continuity_array[n_cp][3];
    for (idx_cp = 0; idx_cp < n_cp; idx_cp++) {
        uint8_t output_dio = continuity_pairs[idx_cp][0];
        uint8_t input_dio = continuity_pairs[idx_cp][1];

        // Check continuity by raising the output HI (1) then LO (0) and verifying
        // the corresponding input follows
        uint8_t bContinuous = 1;
        int8_t state = 1;
        for (state = 1; state >= 0; state--) {
            err = stem.digital[output_dio].setState(state);
            if (err != aErrNone) {
                printf("Error setting DIO%d to %d: %d\n", output_dio, state, err);
                return 0;
            }

            aTime_MSSleep(CYCLE_TIME);

            uint8_t read_state = 0;
            err = stem.digital[input_dio].getState(&read_state);
            if (err != aErrNone) {
                printf("Error getting DIO%d state: %d\n", input_dio, err);
                return 0;
            }

            if (state != read_state) {
                bContinuous = 0;
            }
        }

        continuity_array[idx_cp][0] = bContinuous;
        continuity_array[idx_cp][1] = output_dio;
        continuity_array[idx_cp][2] = input_dio;
    }

    printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
    for (idx_cp = 0; idx_cp < n_cp; idx_cp++) {
        if (continuity_array[idx_cp][0] == 1) {
            printf("DIO%d -- DIO%d: Continuous\n", continuity_array[idx_cp][1], continuity_array[idx_cp][2]);
        } else {
            printf("DIO%d -- DIO%d: Discontinuous\n", continuity_array[idx_cp][1], continuity_array[idx_cp][2]);
        }
    }
    printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");

    stem.disconnect();

    return 0;
}
