/****************************************************************
 * Filename: led_test.cpp
 * Prepared By: James Dudley
 * Date Prepared: February 26, 2018
 * Date Revised: February 26, 2018
 * Revision: 0.0.1
 ***************************************************************/

#include "BrainStem2/BrainStem-all.h"

#define RAIL                          1     // Power rail to use for test
#define VOLTAGE                 3300000     // Set voltage for Rail 0
#define CYCLE_TIME                   20     // Time to pause between readings, ms
#define TOTAL_TIME                 5000     // Time to keep test running, seconds

int main(int argc, const char * argv[]) {
    // Create BrainStem object
    aMTMPM1 pm;
    
    // Initialize error tracker
    aErr err = aErrNone;
    
    // Discover and connect to MTM-PM-1 object
    // Connects to the first USB module discovered
    err = pm.discoverAndConnect(USB);
    if (err != aErrNone) {
        printf("Error connecting to MTM-PM-1: %d\n", err);
        return 0;
    }
    
    if (RAIL == 0) {
        // Set Rail voltage
        err = pm.rail[RAIL].setVoltage(VOLTAGE);
        if (err != aErrNone) {
            printf("Error setting Rail %d voltage to %d: %d\n", RAIL, VOLTAGE, err);
            return 0;
        }
    }
    
    // Enable Rail
    err = pm.rail[RAIL].setEnable(1);
    if (err != aErrNone) {
        printf("Error enabling Rail %d: %d\n", RAIL, err);
        return 0;
    }
    
    uint16_t time = 0;
    while (time < TOTAL_TIME) {
        time += CYCLE_TIME;
        // Get MTM-PM-1 Rail enable state
        uint8_t enable;
        err = pm.rail[RAIL].getEnable(&enable);
        if (err != aErrNone) {
            printf("Error getting Rail %d enable state: %d\n", RAIL, err);
            return 0;
        }
        
        // Read MTM-PM-1 Rail voltage
        int32_t v_rail;
        err = pm.rail[RAIL].getVoltage(&v_rail);
        if (err != aErrNone) {
            printf("Error reading 'sensor' voltage: %d\n", err);
            return 0;
        }
        
        printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
        if (enable == 0) {
            printf("Enable State: OFF\n");
        } else {
            printf("Enable State: ON\n");
        }
        printf("Rail voltage (V): %.3f\n", (float) v_rail / 1e6);
        printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
        
        aTime_MSSleep(CYCLE_TIME);
    }
    
    err = pm.rail[RAIL].setEnable(0);
    if (err != aErrNone) {
        printf("Error disabling Rail %d: %d\n", RAIL, err);
        return 0;
    }
    
    pm.disconnect();
    
    return 0;
}

