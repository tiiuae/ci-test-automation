//
//  main.cpp
//  BrainStemConnectionExample
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


#include "BrainStem2/BrainStem-all.h"
#include <iostream>

using std::string;
using std::cout;
using std::endl;

//declarations
void discoverAndConnect_Example();
void sDiscover_Example();
void findFirstModule_Example();
void findModule_Example();
void connectFromSpec_Example();
void connectThroughLinkModule_Example();

//Main:
///////////////////////////////////////////////////////////////////////
//This example shows the various ways to discover and connect to BrainStem
//modules/devices.
//NOTE: Not all functions will be successful.  Many of the examples will
//      require slight modification in order to work with your device.
//      Please refer to the individual notes/comments in and around
//      each function.
///////////////////////////////////////////////////////////////////////

int main(int arc, const char* arg[]) {

    discoverAndConnect_Example();

    sDiscover_Example();

    findFirstModule_Example();

    findModule_Example();

    connectFromSpec_Example();

    connectThroughLinkModule_Example();

    cout << "Finished!" << endl;
}
///////////////////////////////////////////////////////////////////////

// discoverAndConnect_Example:
///////////////////////////////////////////////////////////////////////
// This is the most common form of connection. The discovery and connection
// process is enveloped into a single function.
//
// PITFALL: This function requires that the object type matches the device
//          you are attempting to connect to and will likely require modification
//          in order to work properly.
///////////////////////////////////////////////////////////////////////

void discoverAndConnect_Example() {

    // Used to catch errors connecting
    aErr err = aErrNone;
    // declaring SN variable
    uint32_t serial_number = 0;

    // TODO:
    // Uncomment the object that matches your device.

    //a40PinModule stem;
    //aEtherStem stem;
    //aMTMStemModule stem;
    //aMTMEtherStem stem;
    //aMTMIOSerial stem;
    //aMTMPM1 stem;
    //aMTMRelay stem;
    //aMTMUSBStem stem;
    //aMTMDAQ1 stem;
    //aMTMDAQ2 stem;
    //aUSBHub2x4 stem;
    aUSBHub3p stem;
    //aUSBCSwitch  stem;
    //aUSBStem stem;

    //When no serial number is provided discoverAndConnect will attempt to
    //connect to the first module it finds.  If multiple BrainStem devices
    //are connected to your machine it is unknown which device will be
    //discovered first.
    //Under the hood this function uses findFirstModule()

    cout << "Example: discoverAndConnect(USB);" << endl;
    err = stem.discoverAndConnect(USB);
    // Connection failure
    if (err != aErrNone) {
        cout << "Unable to find BrainStem Module. Error: "<< err << "." << endl;
        cout << "Are you using the correct Module/Object type?" << endl;
    }
    // successful connection
    else {
        cout << "Found and Connected to a BrainStem Module." << endl;
        stem.system.getSerialNumber(&serial_number);
    }
    stem.disconnect();
    cout << endl;

    //discoverAndConnect has an overload which accepts a Serial Number.
    //The example immediately above will attempt to fetch the serial number
    //and use it in this example. Feel free to drop in the
    //serial number of your device.
    //Under the hood this function uses a combination of sDiscover() and
    //connectFromSpec().

    // Put the serial number of your device here.
    uint32_t user_serial_number = serial_number;

    cout << "Example: discoverAndConnect(USB, Serial_Number);" << endl;
    err = stem.discoverAndConnect(USB, user_serial_number);
    // unsuccessful connection
    if (err != aErrNone) {
        cout << "Unable to find BrainStem Module, Serial Number: " << user_serial_number << ", Error: " << err << endl;
        cout << "Are you using the Module/Object type?" << endl;
    }
    // successful connection
    else {
        cout << "Found and Connected to a BrainStem Module." << endl;
    }
    stem.disconnect();
    cout << "Finished with discoverAndConnect example." << endl <<
        "--------------------------------------------------------" << endl;
}// end example

///////////////////////////////////////////////////////////////////////

// sDiscover_Example:
///////////////////////////////////////////////////////////////////////
// Highlights how to discover and interrogate multiple BrainStem devices
// without connecting to them.
// This is especially helpful for device agnostic applications.
///////////////////////////////////////////////////////////////////////
void sDiscover_Example(){

    list<linkSpec> specList;

    //USB
    cout << "Example: Link::sDiscover(USB, specList);" << endl << endl;
    specList.clear();
    Link::sDiscover(linkType::USB, &specList);
    for (auto it = specList.begin(); it != specList.end(); it++) {
        cout << "Model: "                   << it->model                << endl;
        cout << "Module: "                  << it->module               << endl;
        cout << "Serial Number: "           << it->serial_num           << endl;
        cout << "Router: "                  << it->router               << endl;
        cout << "Router Serial Number: "    << it->router_serial_num    << endl;
        cout << "USB ID: "                  << it->t.usb.usb_id         << endl << endl;
    }
    /////////////////////////////////////////////////

    //TCPIP
    cout << "Example: Link::sDiscover(TCPIP, specList);" << endl << endl;
    specList.clear();
    Link::sDiscover(linkType::TCPIP, &specList);
    for (auto it = specList.begin(); it != specList.end(); it++) {
        cout << "Model: "                   << it->model                << endl;
        cout << "Module: "                  << it->module               << endl;
        cout << "Serial Number: "           << it->serial_num           << endl;
        cout << "Router: "                  << it->router               << endl;
        cout << "Router Serial Number: "    << it->router_serial_num    << endl;
        cout << "USB ID: "                  << it->t.usb.usb_id         << endl << endl;
    }
    cout << "Finished with sDiscover example." << endl <<
        "--------------------------------------------------------" << endl;
}// end example
///////////////////////////////////////////////////////////////////////

// findFirstModule_Example:
///////////////////////////////////////////////////////////////////////
// This example is similar to Discover and Connect, except it connects
// the first BrainStem it finds, rather than connecting to a specific
// device type.
///////////////////////////////////////////////////////////////////////
void findFirstModule_Example() {

    linkSpec *spec = nullptr;

    cout << "Example: findFirstModule(USB);" << endl << endl;
    spec = aDiscovery_FindFirstModule(linkType::USB);
    if (spec != nullptr) {
        cout << "Model: "                   << spec->model              << endl;
        cout << "Module: "                  << spec->module             << endl;
        cout << "Serial Number: "           << spec->serial_num         << endl;
        cout << "Router: "                  << spec->router             << endl;
        cout << "Router Serial Number: "    << spec->router_serial_num  << endl;
        cout << "USB ID: "                  << spec->t.usb.usb_id       << endl << endl;
        aLinkSpec_Destroy(&spec); //The spec should be cleaned up when finished.
    }
    else { cout << "No USB BrainStem device  was found." << endl << endl; }


    cout << "Example: findFirstModule(TCPIP);" << endl << endl;
    spec = nullptr;
    spec = aDiscovery_FindFirstModule(linkType::TCPIP);
    if (spec != nullptr) {
        cout << "Model: "                           << spec->model              << endl;
        cout << "Module: "                          << spec->module             << endl;
        cout << "Serial Number: "                   << spec->serial_num         << endl;
        cout << "Router: "                          << spec->router             << endl;
        cout << "Router Serial Number: "            << spec->router_serial_num  << endl;
        cout << "USB ID: "                          << spec->t.usb.usb_id       << endl << endl;
        aLinkSpec_Destroy(&spec); //The spec should be cleaned up when finished.
    }
    else { cout << "No TCPIP BrainStem device  was found." << endl; }

    cout << "Finished with findFirstModule example." << endl <<
        "--------------------------------------------------------" << endl;
}
///////////////////////////////////////////////////////////////////////

// findModule_Example:
///////////////////////////////////////////////////////////////////////
// This example will connect to any BrainStem device given its serial
// number. It will not connect without a SN.
///////////////////////////////////////////////////////////////////////
void findModule_Example() {

    //TODO:
    //Plug in the serial number of your device.

    uint32_t serial_number = 0xB971001E; //Replace with your devices Serial Number.
    linkSpec *spec = nullptr;

    cout << "Example: findModule(USB, Serial_Number);" << endl << endl;
    spec = aDiscovery_FindModule(linkType::USB, serial_number);
    if(spec != nullptr) {
        cout << "Model: "                   << spec->model              << endl;
        cout << "Module: "                  << spec->module             << endl;
        cout << "Serial Number: "           << spec->serial_num         << endl;
        cout << "Router: "                  << spec->router             << endl;
        cout << "Router Serial Number: "    << spec->router_serial_num  << endl;
        cout << "USB ID: "                  << spec->t.usb.usb_id       << endl << endl;
        aLinkSpec_Destroy(&spec); //The spec should be cleaned up when finished.
    }
    else { cout << "No USB BrainStem device with serial number " << serial_number << " was found." << endl; }


    //For TCP/IP devices.  Will not be successful with USB based devices.
    cout << "Example: findModule(TCPIP, Serial_Number);" << endl << endl;
    spec = nullptr;
    spec = aDiscovery_FindModule(linkType::TCPIP, serial_number);
    if (spec != nullptr) {
        cout << "Model: "                   << spec->model              << endl;
        cout << "Module: "                  << spec->module             << endl;
        cout << "Serial Number: "           << spec->serial_num         << endl;
        cout << "Router: "                  << spec->router             << endl;
        cout << "Router Serial Number: "    << spec->router_serial_num  << endl;
        cout << "USB ID: "                  << spec->t.usb.usb_id       << endl << endl;
        aLinkSpec_Destroy(&spec); //The spec should be cleaned up when finished.
    }
    else { cout << "No TCPIP BrainStem device with serial number " << serial_number << " was found." << endl; }

    cout << "Finished with findModule example." << endl <<
        "--------------------------------------------------------" << endl;
}
///////////////////////////////////////////////////////////////////////

// connectFromSpec_Example:
///////////////////////////////////////////////////////////////////////
// Many of the discovery functions will return a linkSpec object.
// This function shows how to use that object to connect to a BrainStem
// device.
// The benefit of this connection method is that it does not care
// about which BrainStem object/module you use.
// i.e. you can connect to a USBHub3p from a USBStem object. However,
// the USBStem object does not possess a USB Entity and therfor will not be
// able to control the USBHub3p correctly. This is typically not
// recommended.
///////////////////////////////////////////////////////////////////////
void connectFromSpec_Example() {

    aErr err = aErrNone;

    aUSBHub3p stem;

    cout << "Example: connectFromSpec(linkSpec);" << endl << endl;
    linkSpec* spec = aDiscovery_FindFirstModule(linkType::USB);
    if (spec != nullptr) {

        err = stem.connectFromSpec(*spec);
        if (err != aErrNone) {
            cout << "Unable to connect to BrianStem Module. Error: " << err << endl;
        }
        else {
            cout << "Found and Connected to BrainStem Module" << endl;
            stem.disconnect();
        }
        aLinkSpec_Destroy(&spec); //The spec should be cleaned up when finished.
    }
    else { cout << "No BrainStem devices were found." << endl; }

    cout << "Finished with connectFromSpec example." << endl <<
        "--------------------------------------------------------" << endl;
}
///////////////////////////////////////////////////////////////////////


// connectThroughLinkModule_Example():
///////////////////////////////////////////////////////////////////////
// This function allows a device to share the connection of another device.
// This feature is only available for Acroname's MTM and 40pin devices.
//
// In this example we have a MTMUSBStem and a MTMDAQ2 connected to a BrainStem
// development board.  The board is powered and ONLY the MTMUSBStem is connected
// to the computer via USB cable.  The MTMDAQ2 will connect to the PC through the
// MTMUSBStem via the BrainStem Network (I2C) which is wired through the
// development board.
///////////////////////////////////////////////////////////////////////
void connectThroughLinkModule_Example() {

    aErr err = aErrNone;

    aUSBHub3p stem;

    cout << "Example: connectThroughLinkModule;" << endl << endl;

    // Create the devices required for this example
    aMTMUSBStem mtmstem;
    aMTMDAQ2 mtmdaq2;

    err = mtmstem.discoverAndConnect(USB);
    if (err != aErrNone) {
        cout << "Unable to connect to MTMUSBStem Module. Error: " << err << endl;
    }
    else {
        cout << "Found and Connected to MTMUSBStem Module" << endl;

        // Set the route functionality to route all BrainStem Network
        // traffic to the MTMStem.
        err = mtmstem.system.routeToMe(1);
        if(err != aErrNone){
            cout << "Error routing Traffic to MTMUSBStem. Error: "<< err <<endl;
        }

        // Now that the MTMUSBStem connection is up and running we can
        // use its connection to connect to the MTMDAQ2
        err = mtmdaq2.connectThroughLinkModule(&mtmstem);
        if (err != aErrNone) {
            cout << "Unable to connect to MTMDAQ2 Module. Error: " << err << endl;
        }
        else {
            cout << "Connected to MTMDAQ2 Module" << endl;
            uint8_t LED;
            string LEDStatus;

            // Once connected you can use the devices normally.
            LED = 0;
            err = mtmstem.system.getLED(&LED);
            if(err == aErrNone) {
                LEDStatus = (LED == 0 ? "Off" : "On");
                cout << "MTMUSBStem's User LED: " << LEDStatus << " Error: " << err << endl;
            }

            LED = 0;
            err = mtmdaq2.system.getLED(&LED);
            if(err == aErrNone) {
                LEDStatus = (LED == 0 ? "Off" : "On");
                cout << "MTMDAQ2's User LED: " << LEDStatus << " Error: " << err << endl;
            }

            // You should disconnect in the reverse order in which you connected.
            mtmdaq2.disconnect();
        }
        mtmstem.system.routeToMe(0);
        mtmstem.disconnect();
    }

    cout << "Finished with connectThroughLinkModule_Example." << endl <<
    "--------------------------------------------------------" << endl;
}
