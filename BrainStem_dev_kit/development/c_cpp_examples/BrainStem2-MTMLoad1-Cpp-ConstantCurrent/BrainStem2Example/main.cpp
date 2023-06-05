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

#include <iostream>
#include "BrainStem2/BrainStem-all.h"

//Note: This example assumes you have a device connected to the rail 0 and is
//      capable of allowing 5VDC @ 100mA.

int main(int argc, const char * argv[]) {
    std::cout << "Creating a MTMLoad1 module" << std::endl;

    // Create an instance of the MTMLoad1 module
    aMTMLoad1 stem;
    aErr err = aErrNone;

    // Connect to the hardware.
    // The only difference for TCP/IP modules is to change "USB" to "TCP";
    // err = stem.discoverAndConnect(USB, 0x40F5849A); // for a known serial number
    err = stem.discoverAndConnect(USB);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered connecting to BrainStem module" << std::endl;
        return 1;

    }
    else {
        uint32_t sn;
        err = stem.system.getSerialNumber(&sn);
        printf("Connected to BrainStem module. SN: 0x%08X. Error: %d\n", sn, err);
    }

    //Operational modes are defined in aProtocoldefs.h (development/lib/BrainStem2/)
    //Device specific configurations/capabilities can be found in the product datasheet.
    //0x01 = (railOperationalModeConstantCurrent_Value(0x00) | railOperationalModeLinear_Value(0x01))
    stem.rail[0].setOperationalMode(railOperationalModeConstantCurrent_Value | railOperationalModeLinear_Value);

    printf("Setting load rail 0 to draw 0.1A\n");
    stem.rail[0].setCurrentSetpoint(100000);  //Current is in microamps

    printf("Setting load rail 0 max voltage to 5.0V\n");
    stem.rail[0].setVoltageMaxLimit(5000000);

    printf("Enabling load rail 0\n");
    stem.rail[0].setEnable(true);

    printf("Allowing time for the rail to stabilize\n");
    aTime_MSSleep(1000); //Sleep for 1 second.

    int32_t voltage = 0;
    err = stem.rail[0].getVoltage(&voltage);
    printf("Voltage: %d microvolts, Error: %d\n", voltage, err);

    int32_t current = 0;
    err = stem.rail[0].getCurrent(&current);
    printf("Current: %d microamps, Error: %d\n", current, err);

    printf("Disabling load rail 0\n");
    stem.rail[0].setEnable(false);

    // Disconnect
    err = stem.disconnect();
    if (err == aErrNone) {
        std::cout << "Disconnected from BrainStem module." << std::endl;
    }

    return 0;
}
