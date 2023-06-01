//
//  main.cpp
//  BrainStem2Example
//
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2018 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////

//  This example walks through some of the basic features of the 40pin USBStem.
//  More information about the BrainStem API can be found at:
//  http://acroname.com/reference

#include "BrainStem2/BrainStem-all.h"
int main(int argc, const char * argv[]) {
    // Create BrainStem object
    aErr err = aErrNone;
    a40PinModule stem;
    
    // Find first device and connect.
    err = stem.discoverAndConnect(USB);
    // Find a specific device and connect with SN=1234ABCD
    //err = stem.discoverAndConnect(USB, 0x1234ABCD);
    
    if (err != aErrNone) {
        printf("Error connecting to BrainStem (%d).\n", err);
        return 0;
    }
    
    printf("Reading the BrainStem input voltage.\n\t");
    uint32_t inputVoltage=0;
    stem.system.getInputVoltage(&inputVoltage);
    printf("Input voltage: %.3f\n\n", inputVoltage/1.0e6);
    
    printf("Flashing the user LED.\n\n");
    // Toggle the user LED
    for (int i = 0; i < 10; i++) {
        stem.system.setLED( i%2 );
        aTime_MSSleep(250);
    }
    
    printf("Reading the analog inputs\n");
    for (int i = 0; i < 4; i++) {
        uint16_t a2dValue=0;
        // set the analog to be an input
        stem.analog[i].setConfiguration(analogConfigurationInput);
        stem.analog[i].getValue(&a2dValue);
        printf("%d: %d    ", i, a2dValue);
    }
    printf("\n\n");
    
    printf("Reading the digital inputs\n");
    printf("\tDigital inputs:");
    for (int i = 0; i < 15; i++) {
        uint8_t state=254;
        // set the analog to be an input
        stem.digital[i].setConfiguration(digitalConfigurationInput);
        stem.digital[i].getState(&state);
        printf(" %d", i);
    }
    printf("\n\n");
    
    printf("Writing data to I2C[1]\n\n");
    uint8_t dataout[4]={0,1,2,3};
    uint8_t addr = 123;
    stem.i2c[1].setSpeed(2);
    stem.i2c[1].write(addr, 4, dataout);
    
    // Disconnect from the module
    stem.disconnect();
    return 0;
}
