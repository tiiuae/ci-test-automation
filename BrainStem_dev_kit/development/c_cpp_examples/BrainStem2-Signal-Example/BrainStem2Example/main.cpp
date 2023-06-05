//
//  main.cpp
//  BrainStem2Example
//
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2019 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////
//
// This Example shows basic interaction with the MTMUSBStem. Please see the
// the product datasheet and the reference material at: http://acroname.com/reference
//    1. Create a MTMUSBStem object and connect.
//    2. Configure the MTMUSBStem to output a square wave via digital pin 6.
//    3. Set the T3 Time for signal entity 2 to 100000000.
//    4. Get and display the T3 Time for signal entity 2.
//    5. Set the T2 Time for signal entity 2 to 50000000.
//    6. Get and display the T2 Time for signal entity 2.
//    7. Enable the signal output on signal entity 2.
//    8. Configure the MTMUSBStem to receive a square wave via digital pin 4.
//    9. Enable the signal input on signal entity 0.
//    10. Get and display the T3 Time for signal entity 0.
//    11. Get and display the T2 Time for signal entity 0.
//    12. Calculate the Duty Cycle with the read T3 and T2 values.
//    13. Disable the signal output on signal entity 2.
//    14. Disable the signal input on signal entity 0.
//    15. Disconnect from the MTMUSBStem object.


#include <iostream>
#include "BrainStem2/BrainStem-all.h"
#include "BrainStem2/aMTMUSBStem.h"

int main(int argc, const char * argv[]) {
    std::cout << "Creating a signal loopback, between digital pins 6 and 4, with a MTMUSBStem module" << std::endl << std::endl << std::endl;

    // Lookup Table for Signal to Digital Mapping
    // The indicies refer to the signal [0-4], while the values
    // held in those indicies refer to the digital pins they
    // are associated with.
    // Note: This Lookup Table is for the MTMUSBStem only.
    // Digital Entity to Signal Entity mapping varies per
    // device. Please refer to the data sheet for the MTM
    // Device you are using to see its unique mapping.
    const int signalToDigitalMapping[] = {4, 5, 6, 7, 8};
    
    // T Times to be set. Editable by user
    const uint32_t T3_TIME = 100000000;
    const uint32_t T2_TIME = 50000000;
    
    // Signal Entity indexs to be used for input and output.
    const uint8_t SIGNAL_OUTPUT_IDX = 2;
    const uint8_t SIGNAL_INPUT_IDX = 0;
    
    aMTMUSBStem usbstem; // Create an instance of a MTMUSBStem module
    aErr err = aErrNone; // aErr variable which will hold the return value of the last command executed

    uint32_t readFromOutputT3Time = 0; // T3 Time read from signal entity 2
    uint32_t readFromOutputT2Time = 0; // T2 Time read from signal entity 2
    uint32_t readFromInputT3Time = 0; // T3 Time read from signal entity 0
    uint32_t readFromInputT2Time = 0; // T2 Time read from signal entity 0

    // Connect to the hardware.
    // The only difference for TCP/IP modules is to change 'USB' to 'TCP';
    err = usbstem.discoverAndConnect(USB);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered connecting to BrainStem module. Aborting example!" << std::endl;
        return 1;

    } else {
        std::cout << "Connected to BrainStem module." << std::endl;
    }
    
    std::cout << std::endl;

    /*
     * Output
     */
    
    // Configure the MTMUSBStem to output a square wave via digital pin 6
    err = usbstem.digital[signalToDigitalMapping[SIGNAL_OUTPUT_IDX]].setConfiguration(digitalConfigurationSignalOutput);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the configuration for digital pin 6 on the MTMUSBStem. Aborting example!" << std::endl << std::endl;
        return 1;
    }

    // Set the T3 Time for signal entity 2 to 100000000
    err = usbstem.signal[SIGNAL_OUTPUT_IDX].setT3Time(T3_TIME);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the T3 Time for signal entity 2 on the MTMUSBStem. Aborting example!" << std::endl;
        return 1;
    }

    // Get and display the T3 Time from signal entity 2
    err = usbstem.signal[SIGNAL_OUTPUT_IDX].getT3Time(&readFromOutputT3Time);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to get the T3 Time for signal entity 2 on the MTMUSBStem." << std::endl;
    }
    else if (readFromOutputT3Time == 0) {
        std::cout << "T3 Time cannot be 0. Aborting example!" << std::endl;
        return 1;
    }
    else {
        std::cout << "T3 Time from Output Pin: " << readFromOutputT3Time << std::endl;
    }

    // Set the T2 Time for signal entity 2 to 50000000
    err = usbstem.signal[SIGNAL_OUTPUT_IDX].setT2Time(T2_TIME);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the T2 Time for signal entity 2 on the MTMUSBStem. Aborting example!" << std::endl;
        return 1;
    }

    // Get and display the T2 Time from signal entity 2
    err = usbstem.signal[SIGNAL_OUTPUT_IDX].getT2Time(&readFromOutputT2Time);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to get the T2 Time for signal entity 2 on the MTMUSBStem" << std::endl;
    }
    else {
        std::cout << "T2 Time from Output Pin: " << readFromOutputT2Time << std::endl;
    }

    err = usbstem.signal[SIGNAL_OUTPUT_IDX].setEnable(true);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the signal enabled state of signal entity 2 to true on the MTMUSBStem. Aborting example!" << std::endl;
        return 1;
    }
    
    std::cout << std::endl;

    /*
     * Input
     */
    
    // Configure the MTMUSBStem to receive a square wave via digital pin 4
    err = usbstem.digital[signalToDigitalMapping[SIGNAL_INPUT_IDX]].setConfiguration(digitalConfigurationSignalInput);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the configuration for digital pin 4 on the MTMUSBStem. Aborting example!" << std::endl << std::endl;
        return 1;
    }

    // Enable the signal input on signal entity 0
    err = usbstem.signal[SIGNAL_INPUT_IDX].setEnable(true);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the signal enabled state of signal entity 0 to true on the MTMUSBStem. Aborting example!" << std::endl << std::endl;
        return 1;
    }
    
    /*
    * Sleep for 500ms so the ouput can stabilize
    * and the input can have time to calculate the
    * time high/low
    */
    aTime_MSSleep(500);

    // Get and display the T3 Time from signal entity 0
    err = usbstem.signal[SIGNAL_INPUT_IDX].getT3Time(&readFromInputT3Time);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to get the T3 Time for signal entity 0 on the MTMUSBStem. Aborting example!" << std::endl;
        return 1;
    }
    else if (readFromInputT3Time == 0) {
        std::cout << "T3 Time cannot be 0. Aborting example!" << std::endl;
        return 1;
    }
    else {
        std::cout << "T3 Time from Input Pin: " << readFromInputT3Time << std::endl;
    }

    // Get and display the T2 Time from signal entity 0
    err = usbstem.signal[SIGNAL_INPUT_IDX].getT2Time(&readFromInputT2Time);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to get the T2 Time for signal entity 0 on the MTMUSBStem. Aborting example!" << std::endl;
        return 1;
    }
    else {
        std::cout << "T2 Time from Input Pin: " << readFromInputT2Time << std::endl;
    }
    
    std::cout << std::endl;

    double dutyCycle = ((double)readFromInputT2Time / (double)readFromInputT3Time) * 100.0; // Calculate the Duty Cycle

    std::cout << "Duty Cycle: "<< dutyCycle << std::endl << std::endl; // Display the Duty Cycle

    // Disable the signal output on signal entity 2
    err = usbstem.signal[SIGNAL_OUTPUT_IDX].setEnable(false);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the signal enabled state of signal entity 2 to false on the MTMUSBStem" << std::endl;
    }

    // Disable the signal input on signal entity 0
    err = usbstem.signal[SIGNAL_INPUT_IDX].setEnable(false);
    if (err != aErrNone) {
        std::cout << "Error "<< err <<" encountered attempting to set the signal enabled state of signal entity 0 to false on the MTMUSBStem" << std::endl;
    }
    
    std::cout << std::endl;

    usbstem.disconnect(); // Disconnect from the MTMUSBStem

    return 0;
}
