//
//  main.cpp
//  BrainStem2Example
//
//  Created by Acroname Inc. on 1/16/15.
//  Copyright (c) 2015 Acroname Inc. All rights reserved.
//

#include "BrainStem2/BrainStem-C.h"
#include <stdio.h>      // standard input / output functions

#define LIST_LENGTH (128U)

int main(int argc, const char * argv[]) {

    DeviceNode_t list[LIST_LENGTH];
    uint32_t itemsCreated = 0;
    aErr err = getDownstreamDevices(list, LIST_LENGTH, &itemsCreated);
    printf("Items Created: %d\n", itemsCreated);
    
    if (err == aErrNone) {
        for (uint32_t x = 0; x < itemsCreated; x++) {
            printf("SN: %X\n", list[x].hubSerialNumber);
            printf("Port: %X\n", list[x].hubPort);
            printf(" -VendorID: 0x%04X\n", list[x].idVendor);
            printf(" -ProductID: 0x%04X\n", list[x].idProduct);
            printf(" -Serial Number: %s\n", list[x].serialNumber);
            printf(" -Product: %s\n", list[x].productName);
            printf(" -Manufacturer: %s\n", list[x].manufacturer);
            printf(" -Speed: %d\n", list[x].speed);
            printf("\n");
        }
    }
    else if (err == aErrParam)      { printf("One of the parameters you passed in is not valid. \n"); }
    else if (err == aErrMemory)     { printf("Device list does not have enough room. \n"); }
    else if (err == aErrNotFound)   { printf("No Acroname devices were found. \n"); }
    else                            { printf("Unknown error case: %d\n", err); }

    return 0;
}


