/****************************************************************
 * Filename: led_test.cpp
 * Prepared By: James Dudley
 * Date Prepared: February 26, 2018
 * Date Revised: February 26, 2018
 * Revision: 0.0.1
 ***************************************************************/

#include "BrainStem2/BrainStem-all.h"

#define RESISTOR_VALUE              412 
#define POWER_VOLTAGE           5000000
#define DAC                          16
#define CURRENT                      14
#define VOLTAGE                       0

int main(int argc, const char * argv[]) {
    // Create BrainStem object
    aMTMDAQ1 daq;
    
    // Initialize error tracker
    aErr err = aErrNone;
    
    // Discover and connect to MTM-DAQ-1 object
    // Connects to the first USB module discovered
    err = daq.discoverAndConnect(USB);
    if (err != aErrNone) {
        printf("Error connecting to MTM-DAQ-1: %d\n", err);
        return 0;
    }
    
    // Run the test twice, once with LED power enabled, once with it disabled
    int8_t enable = 2;
    for (enable = 1; enable >= 0; enable--) {
        // Set MTM-DAQ-1 DAC0 (analog 16) to 5V and enable to power LED
        err = daq.analog[DAC].setVoltage(POWER_VOLTAGE);
        if (err != aErrNone) {
            printf("Error setting DAC voltage: %d\n", err);
            return 0;
        }
        err = daq.analog[DAC].setEnable(enable);
        if (err != aErrNone) {
            printf("Error setting DAC enable to %d: %d\n", enable, err);
            return 0;
        }
        
        // Set measurement ranges
        err = daq.analog[VOLTAGE].setRange(12);
        if (err != aErrNone) {
            printf("Error setting Position B analog range to +/-10.24V: %d\n", err);
            return 0;
        }
        err = daq.analog[CURRENT].setRange(9);
        if (err != aErrNone) {
            printf("Error setting Position A->B analog range to +/-5.12V: %d\n", err);
            return 0;
        }
        
        aTime_MSSleep(1000);        // leave the LED on/off for a second
        
        // Read voltage measurements
        int32_t v;
        err = daq.analog[VOLTAGE].getVoltage(&v);
        if (err != aErrNone) {
            printf("Error reading Position B voltage: %d\n", err);
            return 0;
        }
        int32_t v_current;
        err = daq.analog[CURRENT].getVoltage(&v_current);
        if (err != aErrNone) {
            printf("Error reading Position A->B differential voltage: %d\n", err);
            return 0;
        }
        
        // Calculate current
        int32_t i = v_current / RESISTOR_VALUE;         // I = V / R
        
        printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
        if (enable) {
            printf("MTM-DAQ-1 DAC0 status: enabled\n");
        } else {
            printf("MTM-DAQ-1 DAC0 status: disabled\n"); }
        printf("Position B voltage (uV): %d\n", v);
        printf("Position B voltage (V): %.3f\n", (float) v / 1e6);
        printf("Position A->B voltage (uV): %d\n", v_current);
        printf("Position A->B current (uA): %d\n", i);
        printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
    }
    
    err = daq.analog[DAC].setEnable(0);
    if (err != aErrNone) {
        printf("Error disabling DAC: %d\n", err);
        return 0;
    }
    
    daq.disconnect();
    
    return 0;
}

