//
//  main.cpp
//  BrainStem2A2DBulkCapture
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

//Constants
static const int BULK_CAPTURE_CHANNEL = 0;
static const int NUM_SAMPLES = 8000;
static const int SAMPLE_RATE = 200000;

int main(int argc, const char * argv[]) {

    aErr err = aErrNone;
    uint8_t captureState = bulkCaptureIdle;

    printf("Creating MTMStem Object\n");
    aMTMUSBStem stem;

    // Connect to the hardware.
    // The only difference for TCP/IP modules is to change 'USB' to 'TCP';
    printf("Attempting to connect\n");
    err = stem.discoverAndConnect(USB);
    if (err == aErrNone) printf("Connected\n");
    else { printf("Error connecting to device\n"); return 1; }

    printf("\n");
    printf("Configuring Bulk capture\n");
    printf("Analog Channel: %d\n", BULK_CAPTURE_CHANNEL);
    printf("Number of Samples: %d\n", NUM_SAMPLES);
    printf("Sample Rate: %d\n", SAMPLE_RATE);
    printf("\n");
    err = stem.analog[BULK_CAPTURE_CHANNEL].setBulkCaptureNumberOfSamples(NUM_SAMPLES);
    err = stem.analog[BULK_CAPTURE_CHANNEL].setBulkCaptureSampleRate(SAMPLE_RATE);

    printf("\n");
    printf("Starting bulk capture\n");
    stem.analog[BULK_CAPTURE_CHANNEL].initiateBulkCapture();
    //Wait for Bulk Capture to finnish.
    //You can go do other stuff if you would like... Including other BrainStem functions.
    //but you will need to check that it is finnished before unloading the data
    do {
        err = stem.analog[BULK_CAPTURE_CHANNEL].getBulkCaptureState(&captureState);
        if(captureState == bulkCaptureError) {
            printf("There was an Error with Bulk Capture\n");
            break;
        }
        aTime_MSSleep(100);
    } while(captureState != bulkCaptureFinished);

    //Find out how many samples are in the ram slot
    size_t nSize = 0;
    err = stem.store[storeRAMStore].getSlotSize(0, &nSize);

    if (nSize && (err == aErrNone)) {

		uint8_t *rawData = new uint8_t[nSize];
        uint16_t combinedValue = 0;
        size_t nSizeUnloaded = 0;
        printf("Unloading data from the device:\n");
        err = stem.store[storeRAMStore].unloadSlot(0, nSize, rawData, &nSizeUnloaded);

        // Process 8bit values 2 bytes at a time for a 16bit value (Little Endian)
        // i.e.
        // val[0] = XXXXXXXX = LSB's
        // val[1] = YYYYYYYY = MSB's
        // combinedVal = YYYYYYYY XXXXXXXX for a 16 bit value
        // Repeat until all the data has been processed
        // Note: ",2" increments loop counter "i" by 2
        for(unsigned int x = 0; x < nSize; x+=2) {
            combinedValue = 0;
            combinedValue = rawData[x] + (rawData[x+1] << 8);
            printf("Sample: %d, \t\tVoltage: %.3f, \tRaw: %d\n", x/2,
                                            (combinedValue/65535.0)*3.3,
                                            combinedValue);
        }//end for
		delete[] rawData;
		rawData = NULL;
    }//end if

    printf("Disconnecting from device");
    err = stem.disconnect();



    return 0;
}
