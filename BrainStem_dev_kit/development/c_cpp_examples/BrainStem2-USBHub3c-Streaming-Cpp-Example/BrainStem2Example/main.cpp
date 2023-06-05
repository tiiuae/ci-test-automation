//
//  main.cpp
//  BrainStem2Example
//
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2022 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////

//
//  main.cpp
//  BrainStem2Example
//
//  Created by Acroname Inc. on 1/16/22.
//  Copyright (c) 2015 Acroname Inc. All rights reserved.
//

#include <stdio.h>      // standard input / output functions
#include <stdlib.h>
#include <chrono>
#include <map>

//Simple Format class.
#include <iostream>
#include <sstream>
#include <iomanip>

#include "BrainStem2/BrainStem-all.h"

using namespace std::chrono;
using namespace Acroname::BrainStem;


//Formatting class to help with 64bit values across different architectures.
template <class T>
class SimpleFormat {
public:
    static std::string formatValueDecimal(const T& numberValue, uint8_t padding) {
        std::stringstream ss;
        ss << std::setfill('0') << std::setw(padding) << numberValue;
        return ss.str();
    }
    
    static std::string formatValueHex(const T& numberValue, uint8_t padding) {
        std::stringstream ss;
        ss << "0x" << std::uppercase << std::setfill('0') << std::setw(padding) << std::hex << numberValue;
        return ss.str();
    }
};



//Function Prototypes: Examples
void Example_StreamingSpeedComparison(aUSBHub3c& cHub);
void Example_StreamingStatus(aUSBHub3c& cHub);
void Example_StreamingAsyc(aUSBHub3c& cHub);
void Example_StreamingAsycWithUserRef(aUSBHub3c& cHub);
void Example_StreamingAsycWildcards(aUSBHub3c& cHub);
void Example_StreamingEnableAll(aUSBHub3c& cHub);

//Function Prototypes: Asyc callbacks.
aErr _callback_PortVoltage(const aPacket* packet, void* pRef);
aErr _callback_PortVoltageQueue(const aPacket* packet, void* pRef);


//BrainStem streaming comes in 2x flavors.
//1. Synchronous: Simply enable the entity you are interested in and start
//   executing API calls just like you always have. The BrainStem library will
//   automatically buffer these values and provide you with the most recent value
//   when requested through an API call.
//2. Asynchronous: The user provides a callback and an optional reference to
//   the BrainStem library.  When an update is available the users callback
//   will be executed.

//Note 1: Not all API's are capable of streaming.
//Note 2: The Asynchronous option provides a dedicated worker thread for all
//        user callbacks. In other words if you block or take too much time in
//        the callback the BrainStem library will not be affected, but all user
//        callbacks will be.
//Note 3: Subindex's are typically only used in the PowerDeliveryClass. This class
//        provides helper functions to decode these.
//        PowerDeliveryClass::packDataObjectAttributes
//        PowerDeliveryClass::unpackDataObjectAttributes

int main(int argc, const char* argv[]) {

    //Connect
    ////////////////////////////////////////////////////////////////
    aErr err = aErrNone;
    aUSBHub3c cHub;
    err = cHub.discoverAndConnect(USB);

    if (err != aErrNone) { 
        printf("Failed to connect to USBHub3c. Error: %d", err); 
        return 1; 
    }
    ////////////////////////////////////////////////////////////////


    //Examples - Enable one at a time to observe the different 
    //streaming behaviors.
    ////////////////////////////////////////////////////////////////
    
    Example_StreamingSpeedComparison(cHub);

//    Example_StreamingStatus(cHub);

//    Example_StreamingAsyc(cHub);

//    Example_StreamingAsycWithUserRef(cHub);

//    Example_StreamingAsycWildcards(cHub);
    
//    Example_StreamingEnableAll(cHub);
    
    
    ////////////////////////////////////////////////////////////////


    cHub.disconnect();

    return 0;
}


//////////////////////////////////////////////////////////////////
//Examples
//////////////////////////////////////////////////////////////////

//This example highlights the differences in speed between streaming and non-streaming
//Below we will enable streaming on 2 of the USBHub3c ports while leaving the 
//remaining 6 ports non-streaming (default). We will then fetch the VBus voltage 
//as quickly as possible displaying their value and the amount of time it
//took to execute.
//Note: Once streaming is enabled the hardware will transmit values as fast
//as they become available. Once a value is read it is flagged as stale
//Subsequent calls will provide the stale value, but aErrStreamingStale
//will be returned until a new value is received. 
void 
Example_StreamingSpeedComparison(aUSBHub3c& cHub) {

    aErr err = aErrNone;

    //Enables streaming for ALL API's that support streaming within port[0].
    err = cHub.hub.port[0].setStreamEnabled(true);
    if (err != aErrNone) { printf("Could not enable streaming: %d;\n", err); }

    //Enables streaming for ALL API's that support streaming within port[1].
    err = cHub.hub.port[1].setStreamEnabled(true);
    if (err != aErrNone) { printf("Could not enable streaming: %d;\n", err); }

    aTime_MSSleep(10); //Allow streaming to start coming in.

    int count = 0;
    auto start = high_resolution_clock::now(); 
    auto stop = high_resolution_clock::now(); 
    auto duration = duration_cast<microseconds>(stop - start);

    while (count++ < 10) {
        printf("Loop: %d\n", count);

        for (int x = 0; x < aUSBHUB3C_NUM_USB_PORTS; x++) {

            int32_t voltage = 0;

            start = high_resolution_clock::now();
            err = cHub.hub.port[x].getVbusVoltage(&voltage); //Execute API's like normal.
            stop = high_resolution_clock::now();
            duration = duration_cast<microseconds>(stop - start);
            
            //aErrStreamStale is expected when a value is requested before
            //a new value has been received.  The old value is returned, but flagged as stale.
            std::string errString = std::to_string(err);
            std::string s = (err == aErrStreamStale) ?
                (errString + " (aErrStreamStale - Expected)") :
                (errString);
            
            printf("Port: %d, Voltage: %8d(uV) - Duration: %s(uS) - Err: %s\n",
                    x,
                    voltage,
                    SimpleFormat<long long int>::formatValueDecimal(duration.count(), 5).c_str(),
                    s.c_str());
        }

        printf("\n");
    }//End while

    err = cHub.hub.port[0].setStreamEnabled(false);
    if (err != aErrNone) { printf("Could not disable streaming: %d;\n", err); }

    err = cHub.hub.port[1].setStreamEnabled(false);
    if (err != aErrNone) { printf("Could not disable streaming: %d;\n", err); }
}


//In this example we will enable streaming for all the ports.  Enabling
//Through the Entity layer enables all options and subindex. Option
//codes can be found in aProtocoldefs.h.
//Once enabled we will then request the status of all streaming value
//from both the Entity and Link layers.
void 
Example_StreamingStatus(aUSBHub3c& cHub) {
    aErr err = aErrNone;

    //Enable streaming for all ports.
    printf("\n");
    for (int x = 0; x < aUSBHUB3C_NUM_USB_PORTS; x++) {
        err = cHub.hub.port[x].setStreamEnabled(true);
        if (err != aErrNone) { printf("Could not enable streaming on port: %d, err: %d;\n", x, err); }
    }

    //Wait while stuff happens.
    int count = 0;
    while (count++ < 10) {
        aTime_MSSleep(20);
    }

    //Entity Layer: Get Status - Fetched based on port[x]
    std::map<uint64_t, uint32_t> status;
    printf("\n");
    printf("EntityClass::getStreamStatus - Raw\n");
    printf("-------------------------------------------------------\n");
    for (int x = 0; x < aUSBHUB3C_NUM_USB_PORTS; x++) {
        err = cHub.hub.port[x].getStreamStatus(&status);
        
        //Print status in raw form.
        for (const auto& s : status) {
            printf("Port: %d, Stream Key: %s, Value: %d\n",
                   x,
                   SimpleFormat<uint64_t>::formatValueHex(s.first, 16).c_str(),
                   s.second);
        }
        printf("\n");
    }
    
    printf("\n");
    
    printf("EntityClass::getStreamStatus - Decoded\n");
    printf("-------------------------------------------------------\n");
    for (int x = 0; x < aUSBHUB3C_NUM_USB_PORTS; x++) {
        err = cHub.hub.port[x].getStreamStatus(&status);
        
        //Print status in extracted form.
        for (const auto& s : status) {
            printf("Port Entity: Port: %d, subindex: %d, option: %d, Value: %d\n",
                   x,
                   Link::getStreamKeyElement(s.first, Link::STREAM_KEY_SUBINDEX),
                   Link::getStreamKeyElement(s.first, Link::STREAM_KEY_OPTION),
                   s.second);
        }
        printf("\n");
    }

    //Link Layer: Get Streaming Status
    printf("\n");
    if (Link* link = cHub.getLink()) {

        //Get ALL status by using the wildcards (Link::STREAM_WILDCARD)
        std::map<uint64_t, uint32_t> allStatus;
        err = link->getStreamStatus(cHub.getModuleAddress(),
                                    Link::STREAM_WILDCARD,
                                    Link::STREAM_WILDCARD,
                                    Link::STREAM_WILDCARD,
                                    Link::STREAM_WILDCARD,
                                    &allStatus);

        if(err == aErrNone) {
            //Print status in raw form.
            printf("LinkClass::getStreamStatus - Raw\n");
            printf("-------------------------------------------------------\n");
            for (const auto& s : allStatus) {
                printf("Stream Key: %s, Value: %d\n",
                       SimpleFormat<uint64_t>::formatValueHex(s.first, 16).c_str(),
                       s.second);
            }

            printf("\n");

            //Print status in extracted form.
            printf("LinkClass::getStreamStatus - Decoded\n");
            printf("-------------------------------------------------------\n");
            for (const auto& s : allStatus) {
                printf("module: %d, cmd: %2d, option: %2d, index: %d, subindex: %3d, value %d\n",
                    Link::getStreamKeyElement(s.first, Link::STREAM_KEY_MODULE_ADDRESS),
                    Link::getStreamKeyElement(s.first, Link::STREAM_KEY_CMD),
                    Link::getStreamKeyElement(s.first, Link::STREAM_KEY_OPTION),
                    Link::getStreamKeyElement(s.first, Link::STREAM_KEY_INDEX),
                    Link::getStreamKeyElement(s.first, Link::STREAM_KEY_SUBINDEX),
                    s.second);
            }
        }
        else { printf("Error: %d, getting status.", err); }
    }

    //Disable Streaming for all ports.
    //Note: Once streaming is disable, get status calls are no longer available. 
    printf("\n");
    for (int x = 0; x < aUSBHUB3C_NUM_USB_PORTS; x++) {
        err = cHub.hub.port[x].setStreamEnabled(false);
        if (err != aErrNone) { printf("Could not disable streaming on port: %d, err: %d;\n", x, err); }
    }
}



//In this example we show how the streaming functionality can be used asynchronously
//by providing a function callback.
void 
Example_StreamingAsyc(aUSBHub3c& cHub) {
    aErr err = aErrNone;

    //Register callback.
    err = cHub.hub.port[0].registerOptionCallback(portVbusVoltage,          //Option code for cmdPORT
                                                  true,                     //Enable callback
                                                  _callback_PortVoltage,    //Callback function
                                                  NULL);                    //No ref
    if (err != aErrNone) { printf("Could not register callback: %d;\n", err); }
    
    //Wait while stuff happens.
    int count = 0;
    while (count++ < 10) {
        printf("Loop: %d\n", count);
        aTime_MSSleep(20);
    }

    //Unregister callback
    err = cHub.hub.port[0].registerOptionCallback(portVbusVoltage,  //Option code
                                                  false,            //Disable streaming
                                                  NULL,             //No callback
                                                  NULL);            //No ref
    if (err != aErrNone) { printf("Could not unregister callback: %d;\n", err); }
}



//This example is exactly the same as the previous one except we provide
//reference parameter.  This is helpful for gathering information to be handled
//later.
void 
Example_StreamingAsycWithUserRef(aUSBHub3c& cHub) {
    aErr err = aErrNone;
    
    //Thread-safe queue when used by a single producer (thread A - BrainStem Worker Thread)
    //and single consumer (thread B - Main Thread (this))
    Acroname::LocklessQueue_SPSC<int32_t> queue;

    //Register callback.
    err = cHub.hub.port[0].registerOptionCallback(portVbusVoltage,              //Option code
                                                  true,                         //Enable
                                                  _callback_PortVoltageQueue,   //Callback
                                                  (void*)&queue);               //user ref
    if (err != aErrNone) { printf("Could not register callback: %d;\n", err); }

    int count = 0;
    while (count++ < 10) {
        printf("Loop: %d\n", count);

        //Wait while stuff happens.
        aTime_MSSleep(20);

        //Process/consume queue.
        bool success = true;
        while (success) {
            int32_t voltage = 0;
            success = queue.pop(&voltage);
            if (success) {
                printf("Voltage: %.6f\n", double(voltage) / 1000000);
            }
        }
    }

    //Unregister callback
    err = cHub.hub.port[0].registerOptionCallback(portVbusVoltage,  //Option code
                                                  false,            //Disable
                                                  NULL,             //No callback
                                                  NULL);            //No ref
    if (err != aErrNone) { printf("Could not unregister callback: %d;\n", err); }
}



//Here we show how you can use the link later for even more customization.
//The benefit of this option is that you can use wildcards to preform a mass
//registration.  In this case we will register a callback for portVbusVoltage
//and for ALL ports.  This means we will need to interrogate the packet for which
//port index the packet refers too.
void 
Example_StreamingAsycWildcards(aUSBHub3c& cHub) {

    //Bulk registration - Specific cmd and option, but all indexes (Link::STREAM_WILDCARD)
    if (Link* link = cHub.getLink()) {
        link->registerStreamCallback(cHub.getModuleAddress(),   //address
                                     cmdPORT,                   //cmd
                                     portVbusVoltage,           //option
                                     Link::STREAM_WILDCARD,     //index (ie ALL)
                                     true,                      //Enable
                                     _callback_PortVoltage,     //Callback
                                     NULL);                     //No ref.
    }

    //Wait while stuff happens.
    int count = 0;
    while (count++ < 10) {
        printf("Loop: %d\n", count);
        aTime_MSSleep(20);
    }

    //Bulk un-registration callbacks.
    if (Link* link = cHub.getLink()) {
        
        //In the future this will also call enable/disable.
        link->registerStreamCallback(cHub.getModuleAddress(),   //address
                                     cmdPORT,                   //cmd
                                     portVbusVoltage,           //option
                                     Link::STREAM_WILDCARD,     //index (ie ALL)
                                     false,                     //disable
                                     NULL,                      //Callback
                                     NULL);                     //Callback ref.
    }

    aTime_MSSleep(10); //Allow callbacks to finish up.
}



//Last but not least is the enable all command.  Once executed
//the device will begin streaming all values it is capable of streaming.
//These values can be accessed through any normal API call or through
//the bulk getStatus command as shown in this example.
//Note: Not all commands are capable of streaming.
void
Example_StreamingEnableAll(aUSBHub3c& cHub) {
    aErr err = aErrNone;
    
    //Enable All
    if (Link* link = cHub.getLink()) {
        link->enableStream(cHub.getModuleAddress(),
                           Link::STREAM_WILDCARD,
                           Link::STREAM_WILDCARD,
                           Link::STREAM_WILDCARD,
                           true);
        
        //Wait for data to come in.
        aTime_MSSleep(1000);
        
        //Get ALL status.
        std::map<uint64_t, uint32_t> allStatus;
        err = link->getStreamStatus(cHub.getModuleAddress(),
                                    Link::STREAM_WILDCARD,
                                    Link::STREAM_WILDCARD,
                                    Link::STREAM_WILDCARD,
                                    Link::STREAM_WILDCARD,
                                    &allStatus);
        
        if(err == aErrNone) {
            for (const auto& s : allStatus) {
                printf("module: %d, cmd: %2d, option: %2d, index: %d, subindex: %3d, value %d\n",
                       Link::getStreamKeyElement(s.first, Link::STREAM_KEY_MODULE_ADDRESS),
                       Link::getStreamKeyElement(s.first, Link::STREAM_KEY_CMD),
                       Link::getStreamKeyElement(s.first, Link::STREAM_KEY_OPTION),
                       Link::getStreamKeyElement(s.first, Link::STREAM_KEY_INDEX),
                       Link::getStreamKeyElement(s.first, Link::STREAM_KEY_SUBINDEX),
                       s.second);
            }
        }
        else { printf("Error: %d, getting status.", err); }
        
        //Disable All
        link->enableStream(cHub.getModuleAddress(),
                           Link::STREAM_WILDCARD,
                           Link::STREAM_WILDCARD,
                           Link::STREAM_WILDCARD,
                           false);
        
    }
}



//////////////////////////////////////////////////////////////////
//End Examples
//////////////////////////////////////////////////////////////////





//////////////////////////////////////////////////////////////////
//Callback functions
//////////////////////////////////////////////////////////////////

//Basic Asynchronous callback that simpley prints out the data it receives.
aErr 
_callback_PortVoltage(const aPacket* packet, void* pRef) {
    uint64_t timestamp = 0;
    uint32_t seconds = 0;
    uint32_t uSeconds = 0;
    int32_t voltage = 0;
    
    aErr err = Link::getStreamSample(packet, &timestamp, (uint32_t*)&voltage);
    
    //The timestamp can be further decoded with helper functions. (variables not used)
    Link::getTimestampParts(timestamp, &seconds, &uSeconds);
    
    if (err == aErrNone) {
        uint8_t index = 0;
        err = aPacket_GetIndex(packet, &index);
        if (err == aErrNone) {
            printf("Port: %d, TS: %d:%06d (s:uS), Voltage: %d\n", index, seconds, uSeconds, voltage);
        }
        else { printf("Error %d, in _callback_PortVoltage::aPacket_GetIndex", err); }
    }
    else { printf("Error %d, in _callback_PortVoltage::getStreamSample", err); }

    return aErrNone;
}


//Advanced Asynchronous callback that decodes a user provide reference
//and stores the data within it.
aErr 
_callback_PortVoltageQueue(const aPacket* packet, void* pRef) {

    //Fetch user reference.  User MUST know the type that was passed in!  You have been warned!
    Acroname::LocklessQueue_SPSC<int32_t>* queue = (Acroname::LocklessQueue_SPSC<int32_t>*) pRef;

    //Fetch sample
    uint64_t timestamp = 0;
    int32_t voltage = 0;
    
    aErr err = Link::getStreamSample(packet, &timestamp, (uint32_t*)&voltage);
    
    //If successful, store the sample
    if (err == aErrNone) {
        queue->push(voltage);   //Store sample
    }
    else { printf("Error %d, in _callback_PortVoltageQueue::getStreamSample", err); }

    return aErrNone;
}

//////////////////////////////////////////////////////////////////
//End Callback functions
//////////////////////////////////////////////////////////////////




