//
//  main.cpp
//  BrainStem2-DevantechI2C-Cpp-Example
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

#include "BrainStem2/BrainStem-all.h"

//////////////////////////////////////////////////////////////////////////////////////////
// Devantech CMPSXX sample code
// This reads from different compass registers in a single byte transaction
// as well as a mulitple byte transaction.
// See Devantech's product page for additional register locations and values:
// for CMPS11:
// http://www.robot-electronics.co.uk/htm/cmps11i2c.htm
// for CMPS03
// http://www.robot-electronics.co.uk/htm/cmps3tech.htm

void CMPSXX_Test(a40PinModule &stem);

void CMPSXX_Test(a40PinModule &stem)
{
    aErr err = aErrNone;
    
    // Factory default compass address
    uint8_t cmpsxx_addr = 0xC0;
    uint8_t dataout[4];
    uint8_t datain[6];
	uint8_t bus = 0;
    
    printf("Communicating with CMPSXX module at default I2C address: 0x%02X\n", cmpsxx_addr);
    
    // Define the register address we want to set
    dataout[0] = 0; // software version
    
    // Set the bus speed setting on the I2C object to 100Khz
    err = stem.i2c[bus].setSpeed(i2cSpeed_100Khz);
    
    // Set the compass module register pointer
    err = stem.i2c[bus].write(cmpsxx_addr, 1, dataout);
    
    // if we had an error, we likely don't have it wired up, correct address,...
    if (err != aErrNone)
        printf("Failure communicating with CMPXX at default I2C address: 0x%02X\n", cmpsxx_addr);
    
    // Read the compass firwmare version as a single byte
    if (err == aErrNone)
        err = stem.i2c[bus].read(cmpsxx_addr, 1, datain);
    
    // Print the results back to us
    if (err == aErrNone)
        printf(" CMPSXX firmware version: %d\n", datain[0]);
	else  // end of if for printing result
		printf("Error reading version: %d\n", err);
		
    // read the compass bearing register
    
    // Define the register address we want to set
    dataout[0] = 1; // compass bearing register location
        
    // Set the compass module register pointer
    err = stem.i2c[bus].write(cmpsxx_addr, 1, dataout);
    
    // Read multiple (4) bytes from the compass
    if (err == aErrNone)
        err = stem.i2c[bus].read(cmpsxx_addr, 4, datain);
    
    // print the results when we get no error
    if (err == aErrNone) {
        
        printf(" Devantech CMPSXX bearing as byte [0-255] : %d\n", datain[0]);
        printf(" Devantech CMPSXX bearing as word [0-3599]: %d\n", datain[1] << 8 | datain[2]);
        
    } else { // end of if for printing result
        printf("Error reading multiple bytes: %d\n", err);
    }
} // end CMPSXX_Test

//////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, const char * argv[]) {

    printf("Creating a 40 Pin module\n");
    
    // Create an instance of a 40Pin module. Adjust appropriately for target
    // hardware
    a40PinModule stem;
    aErr err = aErrNone;
    
    // Connect to the hardware.
    // The only difference for TCP/IP modules is to change 'USB' to 'TCP';
    //err = stem.discoverAndConnect(USB, 0x40F5849A); // for a known serial number
    err = stem.discoverAndConnect(USB);
    if (err != aErrNone) {
        printf("Error %d encountered connectoring to BrainStem module\n", err);
        return 1;
    
    } else {
        uint32_t serial_num;
        stem.system.getSerialNumber(&serial_num);
        printf("Connected to BrainStem module [%08X].\n", serial_num);
    }
    
    // Communicate and test a Devantech CMPSXX module
    if (err == aErrNone)
        CMPSXX_Test(stem);
    
    // Disconnect
    err = stem.disconnect();
    if (err == aErrNone) {
        printf("Disconnnected from BrainStem module.\n");
    }
    
    return 0;
}
