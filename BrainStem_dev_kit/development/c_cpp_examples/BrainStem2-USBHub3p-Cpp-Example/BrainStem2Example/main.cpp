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

int main(int argc, const char * argv[]) {
    std::cout << "Creating a USBHub3+ module" << std::endl;

    // Create an instance of the USBHub3p
    aUSBHub3p hub;
    aErr err = aErrNone;

    // Connect to the hardware.
    // The only difference for TCP/IP modules is to change 'USB' to 'TCP';
    // err = stem.discoverAndConnect(USB, 0x40F5849A); // for a known serial number
    err = hub.discoverAndConnect(USB);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered connecting to BrainStem module" << std::endl;
        return 1;

    } else {
        std::cout << "Connected to BrainStem module." << std::endl;

    }


	std::cout << "Disabling ports:" << std::endl;
    for (int i = 0; i < 8; ++i) {
        // Disable all ports
        err = hub.usb.setPortDisable(i);
		std::cout << "    port: " << i << " Error: " << err << std::endl;
        // We wait 400ms only to show the disable process more clearly.
        aTime_MSSleep(400);

    }

	std::cout << "Enabling ports:" << std::endl;
    for (int i = 0; i < 8; ++i) {
        // Renable all ports.
        err = hub.usb.setPortEnable(i);
		std::cout << "    port: " << i << " Error: " << err << std::endl;
        // We wait 400ms only to show the renable process more clearly.
        aTime_MSSleep(400);

    }

    // Disconnect
    err = hub.disconnect();
    if (err == aErrNone) {
        std::cout << "Disconnected from BrainStem module." << std::endl;
    }

    return 0;
}
