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
//
// This Example shows basic interaction with the USBC-Switch. Please see the
// the product datasheet and the reference material at: http://acroname.com/reference
//    1. Create a switch object and connect.
//    2. Set up the mux channel to channel 0, enable the common side
//       via the USB entity, and enable the mux side.
//    3. Disable the connection on the common side via the USB entity.
//    4. Change the mux channel to channel 1.
//    5. Enable the connection on the common side via the USB entity.
//    6. Poll current and voltage once a second for MAX_LOOP seconds.
//    7. Disable the connection on the mux side via mux.setEnable.
//    8. Change the mux channel to channel 1.
//    9. Enable the connection on the mux side via mux.setEnable.


#include <iostream>
#include "BrainStem2/BrainStem-all.h"

// The common side USB is always channel 0 on the USBCSwitch.
#define USBC_COMMON         0

// Defines for enabling and disabling the mux channel.
#define ENABLE              1
#define DISABLE             0

// Number of times current and voltage will be printed.
#define LOOP_MAX            5

#include "BrainStem2/aUSBCSwitch.h"

int main(int argc, const char * argv[]) {
    std::cout << "Creating a USBCSwitch module" << std::endl;
    
    // Create an instance of a USBCSwitch module.
    aUSBCSwitch cswitch;
    aErr err = aErrNone;
    uint8_t count;
    
    // Connect to the hardware.
    // The only difference for TCP/IP modules is to change 'USB' to 'TCP';
    // err = cswitch.discoverAndConnect(USB, 0x40F5849A); // for a known serial number
    err = cswitch.discoverAndConnect(USB);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered connecting to BrainStem module" << std::endl;
        return 1;
        
    } else {
        std::cout << "Connected to BrainStem module." << std::endl;
    }
    
    // Initial port setup.
    // Mux select channel 0, USB common side enabled, Mux side enabled.
    cswitch.mux.setChannel(0);
    cswitch.usb.setPortEnable(USBC_COMMON);
    cswitch.mux.setEnable(ENABLE);
    
    // Using the USB channel disable the connection on the common side.
    err = cswitch.usb.setPortDisable(USBC_COMMON);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered disabling connection." << std::endl;
        return 1;
    } else { std::cout << "Disabled connection on the common (USB) side." << std::endl; }
    
    // Change the mux channel to channel 1.
    err = cswitch.mux.setChannel(1);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered changing the channel." << std::endl;
        return 1;
    } else { std::cout << "Switched to mux channel 1." << std::endl; }
    
    
    // Using the usb entity enable the connection.
    err = cswitch.usb.setPortEnable(USBC_COMMON);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered enabling the connection." << std::endl;
        return 1;
    } else { std::cout << "Enabled the connection on the common (USB) side." << std::endl; }
    
    // Loop for LOOP_MAX seconds printing current and voltage.
    for (count = 0; count < LOOP_MAX; count++) {
        int32_t microVolts = 0;
        int32_t microAmps = 0;
        err = cswitch.usb.getPortVoltage(USBC_COMMON, &microVolts);
        if (err == aErrNone) { err = cswitch.usb.getPortCurrent(USBC_COMMON, &microAmps); }
        if (err != aErrNone) {
            std::cout << "Error "<< err <<" encountered getting port voltage and current." << std::endl;
            return 1;
        } else {
            std::cout << "Port Voltage: " << microVolts << " uV, " << "Port Current: " << microAmps << " uA " << std::endl;
        }
        aTime_MSSleep(1000);
    }
    
    // Using the mux, disable the connection.
    //   Note : This has essentially the same effect as disabling the connection
    //          at the common side, except that it will not affect any of the USB
    //          port settings where the USB call directely affects these settings.
    err = cswitch.mux.setEnable(DISABLE);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered disabling the connection on the mux side." << std::endl;
        return 1;
    } else { std::cout << "Disabled the connection on the mux side." << std::endl; }
    
    // Change the mux channel to channel 0.
    err = cswitch.mux.setChannel(0);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered changing the channel." << std::endl;
        return 1;
    } else { std::cout << "Switched to mux channel 0." << std::endl; }
    
    // Using the mux, Enable the connection.
    err = cswitch.mux.setEnable(ENABLE);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered enabling the connection." << std::endl;
        return 1;
    } else { std::cout << "Enabled port via mux." << std::endl; }
    
    err = cswitch.disconnect();
    if (err == aErrNone) {
        std::cout << "Disconnected from BrainStem module." << std::endl;
    }
    
    return 0;
}
