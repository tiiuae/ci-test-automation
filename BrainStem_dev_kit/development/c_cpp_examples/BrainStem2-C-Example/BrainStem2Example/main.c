//
//  main.c
//  BrainStem2Example C
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

#include <stdio.h>
#include "BrainStem2/BrainStem-C.h"
#include "BrainStem2/aProtocoldefs.h"

aErr getPacket32(aLinkRef stem, uint8_t command, uint8_t option, uint32_t *responseValue);
aErr getFirmwareVersion(aLinkRef stem);
aErr toggleUserLED(aLinkRef stem);
aErr getInputVoltage(aLinkRef stem);

uint8_t moduleAddress = 0;

int main(int argc, const char * argv[]) {
    linkSpec* spec = NULL;
    aLinkRef stem = 0;
    aErr err = aErrNone;
    uint8_t count = 0;
    uint32_t voltage = 0;

    //Set the global module address (device specific: i.e. 40pin = 2, MTMStem = 4)
    //Pitfall: Software and Hardware offsets contribute to this value.
    moduleAddress = 2;
    
    printf("Finding the first BrainStem USB module.\n");
    
    printf("\n");
    
    spec = aDiscovery_FindFirstModule(USB);
  
    if (spec != NULL && spec->t.usb.usb_id != 0) {
        printf("Connecting to BrainStem module %08X\n", spec->t.usb.usb_id);

        // If the link creation fails, a reference identifier of 0 is returned.
        stem = aLink_CreateUSB(spec->t.usb.usb_id);
        if (stem == 0) {
            fprintf(stderr, "Error creating link.\n");
            return 1;
        }
    }
    else{
        fprintf(stderr, "No BrainStem module was discovered.\n");
        return 1;
    }

    printf("BrainStem module connected.\n");

    // Wait up to 300 milliseconds for the connection to be established.
    // Start returns after a transport is established, but communications
    // may not be ready. When using the C library layer it is up to the user
    // to check that the connetion is ready and running.

    while ((aLink_GetStatus(stem) != RUNNING) && (count < 30)) {
        count++;
        aTime_MSSleep(10);
    }

    if (count >= 30 && aLink_GetStatus(stem) != RUNNING) {
        printf("BrainStem connection failed!\n");
        aLink_Destroy(&stem);
        return 1;
    }

    printf("Connected after %d milliseconds.\n", count * 10);

    printf("\n");
    
    // Get and print the module firmware version
    printf("Get the module firmware version.\n");
    err = getFirmwareVersion(stem);
    if (err != aErrNone) { printf("Error in getFirmwareVersion(): %d\n", err); }
    
    printf("\n");
    
    // Get and print the module input voltage
    // use the generalized getUEI32 interface
    printf("Get the module input voltage.\n");
    err = getInputVoltage(stem);
    if (err != aErrNone) { printf("Error in getInputVoltage(): %d\n", err); }
    
    printf("\n");
    
    printf("Get the module input voltage with generic interface.\n");
    err = getPacket32(stem, cmdSYSTEM, systemInputVoltage, &voltage);
    if (err == aErrNone)    { printf("System input voltage: %.3fV\n", (float)voltage/1.0e6); }
    else                    { printf("Error in getPacket32(): %d\n", err); }
    
    printf("\n");
    
    // Blink the User LED.
    printf("Toggling the User LED.\n");
    err = toggleUserLED(stem);
    if (err != aErrNone) { printf("Error in toggleUserLED(): %d\n", err); }
    
    printf("\n");
    
    if (stem != 0) {
        // Clean up our resources.
        err = aLink_Destroy(&stem);
    }

    if (err != aErrNone)    { return 1; }
    else                    { return 0; }
}

// Match for systemVersion
static uint8_t sSystemVersion(const aPacket* p, const void* vpRef) {
    return (p->data[0] == cmdSYSTEM && (p->data[1] & ueiOPTION_MASK) == systemVersion);
}
aErr getFirmwareVersion(aLinkRef stem){
    // Set up some packet and data arrays
    uint8_t pData[aBRAINSTEM_MAXPACKETBYTES];
    aPacket* packet = NULL;
    aPacket* response = NULL;
    aErr err = aErrNone;
    uint32_t version = 0;
    
    // Get the module's firmware version
    pData[0] = cmdSYSTEM;
    pData[1] = ueiOPTION_GET | systemVersion;
    pData[2] = ueiSPECIFIER_RETURN_HOST;
    
    // build a packet with the command
    packet = aPacket_CreateWithData(moduleAddress,
                                    3, // pData length in bytes
                                    pData);
    if (packet != NULL) {
        // send the command to the module via the link we created
        err = aLink_PutPacket(stem, packet);
        if (err != aErrNone) { printf("Error with aLink_PutPacket: %d\n", err); }
        err = aPacket_Destroy(&packet);
        if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }

        // We await a response here. We could exit or perform some corrective.
        // action.
        response = aLink_AwaitFirst(stem, sSystemVersion , NULL, 2000);
        if (response == NULL) {
            printf("Error awaiting packet\n");
            return aErrIO;
        }
        
        // grab the version from the response packet
        version = ((response->data[3])<<24) | ((response->data[4])<<16) |
                  ((response->data[5])<<8)  | ((response->data[6]));
        
        //We can, and should, destroy the packet here to clean up.
        err = aPacket_Destroy(&response);
        if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }
    } else {
        // the creation of a packet failed
        err = aErrMemory;
        printf("Could not create packet\n");
    }
    
    // for pretty-printing, throw out the patch build-hash information;
    // keep just the patch-version nibble
    printf("Firmware version: %d.%d.%d\n", aVersion_ParseMajor(version),
           aVersion_ParseMinor(version), aVersion_ParsePatch(version));
    
    return err;
}


// Match packet proc. Here we match a systemLED set response.
static uint8_t sSystemLED(const aPacket* p, const void* vpRef) {
    return (p->data[0] == cmdSYSTEM && (p->data[1] & ueiOPTION_MASK) == systemLED);
}
aErr toggleUserLED(aLinkRef stem){
    // Set up some packet and data arrays
    uint8_t pData[4];
    aPacket* packet = NULL;
    aPacket* response = NULL;
    uint8_t i = 0;
    aErr err = aErrNone;
    
    for( i = 0; i <= 10; i++) {
        // create a command to turn the LED to bOn
        pData[0] = cmdSYSTEM;
        pData[1] = ueiOPTION_SET | systemLED;
        pData[2] = ueiSPECIFIER_RETURN_HOST;
        pData[3] = i%2;
        
        // build a packet with the command
        packet = aPacket_CreateWithData(moduleAddress,
                                        4, // pData length in bytes
                                        pData);
        if (packet != NULL) {
            // send the command to the module via the link we created
            err = aLink_PutPacket(stem, packet);
            if (err != aErrNone) { printf("Error with aLink_PutPacket: %d\n", err); }
            err = aPacket_Destroy(&packet);
            if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }
            // We await a response here. We could exit or perform some corrective.
            // action.
            response = aLink_AwaitFirst(stem, sSystemLED , NULL, 2000);
            if (response == NULL) {
                printf("error awaiting packet\n");
                return aErrIO;
            }
            //We can, and should, destroy the packet here to clean up.
            err = aPacket_Destroy(&response);
            if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }
        } else {
            // the creation of a packet failed
            err = aErrMemory;
        }
        
        if (err != aErrNone) {
            fprintf(stderr, "Error %d communicating with BrainStem module, exiting.\n", err);
            break;
        }
        // We use the Acroname aTime utility here to avoid platform specific sleep issues.
        aTime_MSSleep(250);
    } // end for i < 10
    
    return err;
}


// Match for systemInputVoltage
static uint8_t sSystemInputVoltage(const aPacket* p, const void* vpRef) {
    return (p->data[0] == cmdSYSTEM && (p->data[1] & ueiOPTION_MASK) == systemInputVoltage);
}
aErr getInputVoltage(aLinkRef stem){
    // Set up some packet and data arrays
    uint8_t pData[4];
    aPacket* packet = NULL;
    aPacket* response = NULL;
    aErr err = aErrNone;
    uint32_t voltage = 0;
    
    // Get the module's firmware version
    pData[0] = cmdSYSTEM;
    pData[1] = ueiOPTION_GET | systemInputVoltage;
    pData[2] = ueiSPECIFIER_RETURN_HOST;
    
    // build a packet with the command
    packet = aPacket_CreateWithData(moduleAddress,
                                    3, // pData length in bytes
                                    pData);
    if (packet != NULL) {
        // send the command to the module via the link we created
        err = aLink_PutPacket(stem, packet);
        if (err != aErrNone) { printf("Error with aLink_PutPacket: %d\n", err); }
        err = aPacket_Destroy(&packet);
        if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }
        
        // We await a response here. We could exit or perform some corrective.
        // action.
        response = aLink_AwaitFirst(stem, sSystemInputVoltage , NULL, 2000);
        //response = aLink_AwaitPacket(stem, 2000);
        if (response == NULL) {
            printf("error awaiting packet\n");
            return aErrIO;
        }
        
        // grab the voltage from the response packet
        voltage = ((response->data[3])<<24) | ((response->data[4])<<16) |
                  ((response->data[5])<<8)  | ((response->data[6]));
        
        //We can, and should, destroy the packet here to clean up.
        err = aPacket_Destroy(&response);
        if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }
    } else {
        // the creation of a packet failed
        err = aErrMemory;
    }
    
    // print out the voltage
    printf("System input voltage: %.3f\n", (float)voltage/1.0e6);
    
    return err;
}


// The above functions are the brute force way to do BrainStem packet handling.
// Clearly these can be abstracted into a generic interface (a UEI). The
// following sets up a generic packet filter for a given command/option. One
// should also check for error packets with matching command/option. This is
// left as an exercise for the reader. (Hint: put it in the packet filter and
// handle the error packet after the filter).
static uint8_t sPacketFilter(const aPacket* packet, const void* vpRef) {
    aPacket* query = (aPacket*)vpRef;
    return (packet->address == query->address &&
            packet->data[0] == query->data[0] &&
            packet->data[1] == query->data[1]);
}
aErr getPacket32(aLinkRef stem, uint8_t command, uint8_t option, uint32_t *responseValue){
    uint8_t pData[4];
    aPacket* packet = NULL;
    aPacket* response = NULL;
    aErr err = aErrNone;

    if(!responseValue){
        return aErrMemory;
    }
    
    // Get the module's firmware version
    pData[0] = command;
    pData[1] = ueiOPTION_GET | option;
    pData[2] = ueiSPECIFIER_RETURN_HOST;
    
    // build a packet with the command
    packet = aPacket_CreateWithData(moduleAddress,
                                    3, // pData length in bytes
                                    pData);
    if (packet == NULL) {
        // the creation of a packet failed
        return aErrMemory;
    }

    // send the command to the module via the link we created
    err = aLink_PutPacket(stem, packet);
    if (err != aErrNone) { printf("Error with aLink_PutPacket: %d\n", err); }
    err = aPacket_Destroy(&packet);
    if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }
    
    // We await a response here.
    // Change the packet to ba a val (response) type with the same cmd/option
    pData[0] = command;
    pData[1] = ueiOPTION_VAL | option;
    pData[2] = ueiSPECIFIER_RETURN_HOST;
    packet = aPacket_CreateWithData(moduleAddress,
                                    3, // pData length in bytes
                                    pData);
    if (packet == NULL) {
        // the creation of a packet failed
        return aErrMemory;
    }
    
    response = aLink_AwaitFirst(stem, sPacketFilter, packet, 1000);
    if (response == NULL) {
        printf("error awaiting packet\n");
        return aErrIO;
    }
    
    // grab the version from the response packet
    // data[0] = command
    // data[1] = operation|option
    // data[2] = reply|index
    // data[3] = high data byte
    // data[4..] = data bytes...
    // https://acroname.com/reference/brainstem/appendix/uei.html
    *responseValue = ((response->data[3])<<24) | ((response->data[4])<<16) |
                     ((response->data[5])<<8)  | ((response->data[6]));
    
    //Destroy the response packet here to clean up
    err = aPacket_Destroy(&response);
    if (err != aErrNone) { printf("Error with aPacket_Destroy: %d\n", err); }

    return err;
}
