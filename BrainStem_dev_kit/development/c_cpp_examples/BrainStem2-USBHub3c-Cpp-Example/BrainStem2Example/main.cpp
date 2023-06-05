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
    std::cout << "Creating a USBHub3c module" << std::endl;

    // Create an instance of the USBHub3p
    aUSBHub3c chub;
    aErr err = aErrNone;

    // Connect to the hardware.
    // err = chub.discoverAndConnect(USB, 0x40F5849A); // for a known serial number
    err = chub.discoverAndConnect(USB);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered connecting to BrainStem module" << std::endl;
        return 1;

    }
    else { std::cout << "Connected to BrainStem module." << std::endl; }

    uint8_t upstreamPort = aUSBHUB3C_NUM_USB_PORTS;
    err = chub.hub.getUpstream(&upstreamPort);
    if(err == aErrNone) {
        std::cout << std::endl;
        printf("The current upstream port is: %d\n", upstreamPort);
    }
    
    if(err == aErrNone) {
        std::cout << std::endl;
        std::cout << "Disabling all downstream ports." << std::endl;
        
        for (int port = 0; port < aUSBHUB3C_NUM_USB_PORTS; port++) {
            
            if(port == upstreamPort) {
                std::cout << "Skipping upstream Port." << std::endl;
            }
            else if(port == aUSBHub3c::kPORT_ID_CONTROL) {
                std::cout << "The Control port is always enabled" << std::endl;
            }
            else if(port == aUSBHub3c::kPORT_ID_POWER_C) {
                std::cout << "The Power-C port is always enabled" << std::endl;
            }
            else {
                err = chub.hub.port[port].setEnabled(false);
                std::cout << "Disabling Port " << port << " Error: " << err << std::endl;
            }
        
            aTime_MSSleep(400); //Delay so the user can see it.
        }
    }
    
    
    
    if(err == aErrNone) {
        std::cout << std::endl;
        std::cout << "Enabling all downstream ports." << std::endl;
        
        for (int port = 0; port < aUSBHUB3C_NUM_USB_PORTS; port++) {
                        
            if(port == upstreamPort) {
                std::cout << "Skipping upstream Port: " << std::endl;
            }
            else if(port == aUSBHub3c::kPORT_ID_CONTROL) {
                std::cout << "The Control port is always enabled" << std::endl;
            }
            else if(port == aUSBHub3c::kPORT_ID_POWER_C) {
                std::cout << "The Power-C port is always enabled" << std::endl;
            }
            else {
                err = chub.hub.port[port].setEnabled(true);
                std::cout << "Enabling Port " << port << " Error: " << err << std::endl;
            }
            
            aTime_MSSleep(400); //Delay so the user can see it.
        }
    }
    
    //Voltage and Current
    if(err == aErrNone) {
        std::cout << std::endl;
        std::cout << "Getting VBus and VConn Voltage and Current" << std::endl;
        std::cout << "Note: When in PD Mode voltage is only present after successful ";
        std::cout << "      negotiation with a device." << std::endl;
        
        for (int port = 0; port < aUSBHUB3C_NUM_USB_PORTS; port++) {
            int32_t vBusVoltage = 0;
            int32_t vBusCurrent = 0;
            int32_t vConnVoltage = 0;
            int32_t vConnCurrent = 0;

            std::cout << std::endl;
            printf("Port: %d\n", port);
            
            err = chub.hub.port[port].getVbusVoltage(&vBusVoltage);
            printf("Vbus Voltage: %.2f, Error: %d\n", vBusVoltage/1000000.0, err);
            
            err = chub.hub.port[port].getVbusCurrent(&vBusCurrent);
            printf("Vbus Current: %.2f, Error: %d\n", vBusCurrent/1000000.0, err);
            
            if(port != aUSBHub3c::kPORT_ID_POWER_C) {
                err = chub.hub.port[port].getVconnVoltage(&vConnVoltage);
                printf("VConn Voltage: %.2f, Error: %d\n", vConnVoltage/1000000.0, err);
                
                err = chub.hub.port[port].getVconnCurrent(&vConnCurrent);
                printf("VConn Current: %.2f, Error: %d\n", vConnCurrent/1000000.0, err);
            }
            else { std::cout << "The Power-C port does not have VConn measurements." << std::endl; }
        }
    }
    

    // Disconnect
    err = chub.disconnect();
    if (err == aErrNone) {
        std::cout << std::endl;
        std::cout << "Disconnected from USBHub3c." << std::endl;
    }

    return 0;
}
