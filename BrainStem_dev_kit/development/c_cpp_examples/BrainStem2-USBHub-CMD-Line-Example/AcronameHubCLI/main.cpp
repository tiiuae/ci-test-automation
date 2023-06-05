//main.cpp : Defines the entry point for the console application.
//
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2021 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////

#include <iostream>
#include <iomanip>
#include "BrainStem2/BrainStem-all.h"

//The command line arguments are parsed using the open source cxxopts.hpp header
//implementation. The original source of this file can be found at:
//https://github.com/jarro2783/cxxopts
//FYI: Windows Users std::min() and std::max() are used by cxxopts.hpp.  This 
//     can cause an issues when including windows.h which defines these as macros.
//     To combate this I added NOMINMAX to the preprocessor defines for this project.
//     Debug -> BrainStem2Example Proprities -> Configuration Properties -> C/C++ -> preprocessor
#include "cxxopts.hpp"


// Platform specific line feed.
#if defined(_MSC_VER)
#define _LF             "\r\n"
#define LF_LEN          2
#else
#define _LF             "\n"
#define LF_LEN          1
#endif


static const char* EXAMPLES_COMMANDS = _LF
"Examples:" _LF
"Note: When --serial is NOT used, the application will default to the first Acroname Hub found" _LF
"\"AcronameHubCLI --ports 0 --enable 0\"                     - Disables Port 0" _LF
"\"AcronameHubCLI --ports 0 --enable 1\"                     - Enables Port 0" _LF
"\"AcronameHubCLI --ports 1 --enable 1 --serial FEEDBEEF\"   - Enables port 1 for device 0xFEEDBEEF" _LF
"\"AcronameHubCLI --ports 1 --enable 1 --data\"              - Enables port 1 data lines only" _LF
"\"AcronameHubCLI --ports 1 --enable 0 --data\"              - Disables port 1 data lines only" _LF
"\"AcronameHubCLI --ports 2 --enable 1 --power\"             - Enables port 1 power lines only" _LF
"\"AcronameHubCLI --ports 2 --enable 0 --power\"             - Disables port 1 power lines only" _LF
;

int main(int argc, char* argv[])
{
    Acroname::BrainStem::Module* stem;
    Acroname::BrainStem::USBClass usb;
    Acroname::BrainStem::SystemClass system;
    Acroname::BrainStem::USBSystemClass usbSystem;
    Acroname::BrainStem::PortClass portClass;
    
    unsigned long serialNumber = 0;
    linkSpec* spec = NULL;
    std::vector<int> ports;
    int enable = 0;
    int upstream = 0;
    bool power = true;
    bool data = true;
    uint32_t mode = 0;
    uint8_t upstate = 0;
    int vbusState = 0;
    int hsState = 0;
    int ssState = 0;
    int offset = 0;
    aErr err = aErrNone;

    //Create cxxopts options object
    cxxopts::Options options("AcronameHubCLI.exe", "Acroname Programmable Hub Command Line Interface");
    try
    {
        options.add_options()
            ("h, help", "Prints this help message")
            ("p, ports", "The downstream ports that enable or toggle will affect (0-7). This can be a comma-separated list.", cxxopts::value<std::vector<int>>())
            ("e, enable", "Disable (0) or enable (1) port(s)", cxxopts::value<int>()->default_value("1"))
            ("t, toggle", "Toggle port(s) between enabled and disabled. If this option is present, the -e/--enable option is ignored.")
            ("w, power", "Only apply enable or toggle to port power lines")
            ("d, data", "Only apply enable or toggle to port data lines")
            ("u, upstream", "Manually select an upstream port", cxxopts::value<int>())
            ("a, auto", "Enable automatic upstream port selection. If this option is present, the -u/--upstream option is ignored.")
            ("s, serial", "Hub serial number in hexadecimal representation. Use 0 for automatic discovery.", cxxopts::value<std::string>()->default_value("0"))
            ("v, verbose", "Report port states after processing other options")
            ("r, reset", "Reset the hub. All port options are ignored.")
            ("x, examples", "Displays a list of common examples");

        auto result = options.parse(argc, argv);

        //Print arguments, if non were provided print the usage.
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        std::cout << "Arguments: ";
        for (int x = 0; x < argc; x++) { std::cout << argv[x] << " "; }
        std::cout << std::endl;
    
        if(argc == 1) { //First argument is always the app path.
            std::cout << "No arguments were provided. Printing usage" << std::endl;
            std::cout << options.help() << std::endl;
            std::cout << EXAMPLES_COMMANDS << std::endl;
            return 1;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    
        //Parser - Help
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        if (result.count("help")) {
            std::cout << options.help() << std::endl;
            std::cout << EXAMPLES_COMMANDS << std::endl;
            return 1;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    
        //Parser - Help
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        if (result.count("examples")) {
            std::cout << EXAMPLES_COMMANDS << std::endl;
            return 1;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Serial
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        if (result.count("serial")) {

            serialNumber = std::stoul(result["serial"].as<std::string>(), nullptr, 16);
            if (serialNumber == 0) { spec = aDiscovery_FindFirstModule(USB); }
            else { spec = aDiscovery_FindModule(USB, (uint32_t)serialNumber); }
            if (spec == NULL) {
                std::cerr << "Could not find any BrainStem Devices" << std::endl;
                std::cerr << options.help() << std::endl;
                return 1;
            }
        }
        else {
            spec = aDiscovery_FindFirstModule(USB);
            if (spec == NULL) {
                std::cerr << "Could not find any BrainStem Devices" << std::endl;
                std::cerr << options.help() << std::endl;
                return 1;
            }
        }
    
        if ((spec->model != aMODULE_TYPE_USBHub3p)  &&
            (spec->model != aMODULE_TYPE_USBHub2x4) &&
            (spec->model != aMODULE_TYPE_USBHub3c))
            
        {
            std::cerr << "The device that was found is not a hub. Model: " << aDefs_GetModelName(spec->model) << std::endl;
            std::cerr << options.help() << std::endl;
            aLinkSpec_Destroy(&spec);
            return 1;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Port - We need to check the range based on the device type
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        if (result.count("ports")) {
            ports = result["ports"].as<std::vector<int>>();
            for (const auto& port : ports) {
                if ((spec->model == aMODULE_TYPE_USBHub3p) ||
                    (spec->model == aMODULE_TYPE_USBHub3c))
                {
                    if ((port > 7) || (port < 0)) {
                        std::cerr << "Incorrect port value: " << port << std::endl;
                        std::cerr << "The " << aDefs_GetModelName(spec->model) << " ports range from 0-7" << std::endl;
                        std::cerr << options.help() << std::endl;
                        aLinkSpec_Destroy(&spec);
                        return 1;
                    }
                }
                else if (spec->model == aMODULE_TYPE_USBHub2x4) {
                    if ((port > 3) || (port < 0)) {
                        std::cerr << "Incorrect port value: " << port << std::endl;
                        std::cerr << "The " << aDefs_GetModelName(spec->model) << " ports range from 0-3" << std::endl;
                        std::cerr << options.help() << std::endl;
                        aLinkSpec_Destroy(&spec);
                        return 1;
                    }
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Enable - We need to check the value is within range.
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        enable = result["enable"].as<int>();
        if ((enable != 1) && (enable != 0)) {
            std::cerr << "Incorrect value for enable" << std::endl;
            std::cerr << "Acceptable values are 0 for false and 1 for true" << std::endl;
            std::cerr << options.help() << std::endl;
            aLinkSpec_Destroy(&spec);
            return 1;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Toggle
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //Nothing specific needs to be handled or tested. Option will be checked in "work".
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Upstream - We need to check the value is within range.
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        if (result.count("upstream")) {
            bool handleError = false;
            
            upstream = result["upstream"].as<int>();
            if (spec->model == aMODULE_TYPE_USBHub3c) {
                if(upstream >= 6) {
                    handleError = true;
                }
            }
            else {
                if ((upstream != 1) && (upstream != 0)) {
                    handleError = true;
                }
            }
            
            if(handleError) {
                std::cerr << "Incorrect value for upstream" << std::endl;
                if (spec->model == aMODULE_TYPE_USBHub3c) {
                    std::cerr << "Acceptable values 0-5" << std::endl;
                }
                else {
                    std::cerr << "Acceptable values are 0 for UP0 and 1 for UP1" << std::endl;
                }
                std::cerr << options.help() << std::endl;
                aLinkSpec_Destroy(&spec);
                return 1;
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Auto
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //Nothing specific needs to be handled or tested. Option will be checked in "work".
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Parser - Power and Data
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // act on both power and data by default (both flags present or both flags absent)
        power = true;
        data = true;
        if (result.count("power") && !result.count("data")) {
            // only power flag present: only act on power lines
            power = true;
            data = false;
        }
        if (result.count("data") && !result.count("power")) {
            // only data flag present: only act on power lines
            power = false;
            data = true;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        //Work
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        if (spec->model == aMODULE_TYPE_USBHub3p) {
            stem = new Acroname::BrainStem::Module(aUSBHUB3P_MODULE, true, aMODULE_TYPE_USBHub3p);
        }
        else if (spec->model == aMODULE_TYPE_USBHub2x4) {
            stem = new Acroname::BrainStem::Module(aUSBHUB2X4_MODULE, true, aMODULE_TYPE_USBHub2x4);
        }
        else if (spec->model == aMODULE_TYPE_USBHub3c) {
            stem = new Acroname::BrainStem::Module(aUSBHUB3C_MODULE, true, aMODULE_TYPE_USBHub3c);
        }
        else {
            std::cerr << "Error: device object not created" << std::endl;
            return 5;
        }
    
        err = stem->connectFromSpec(*spec);
        if (err != aErrNone) {
            std::cerr << "Error connecting to the device. Error: " << err << std::endl;
        }
        else {
            std::cout << "Sucessfully connected to " << aDefs_GetModelName(spec->model);
            std::cout << " SN: 0x" << std::setfill('0') << std::setw(8) << std::hex << std::uppercase << spec->serial_num << std::endl;
            
            usb.init(stem, 0);
            system.init(stem, 0);

            if (result.count("reset")) {
                std::cout << "Resetting device" << std::endl;
                if(stem->isConnected()) { system.reset(); }
            } else {

                for (const auto& port : ports) {
                    if (result.count("toggle")) {
                        
                        if (spec->model == aMODULE_TYPE_USBHub3c) {
                            portClass.init(stem, port);
                            
                            uint8_t dataEnabled = 0;
                            aErr err1 = portClass.getDataEnabled(&dataEnabled);
                            hsState = dataEnabled;
                            
                            uint8_t powerEnabled = 0;
                            aErr err2 = portClass.getPowerEnabled(&powerEnabled);
                            vbusState = powerEnabled;
                            
                            //Not a good way to handle this based on the current error structure.
                            err = (err1 || err2) ? (aErrUnknown) : (aErrNone);
                        }
                        else {
                            err = usb.getHubMode(&mode);
                            
                            offset = 2 * port;
                            hsState = (mode & (1 << offset)) >> offset;
                            
                            offset = 1 + 2 * port;
                            vbusState = (mode & (1 << offset)) >> offset;
                        }
                        
                        if (err == aErrNone) {
                            
                            if (data) {
                                if (hsState)    { err = usb.setDataDisable(port); }
                                else            { err = usb.setDataEnable(port); }
                            }
                            
                            if (err != aErrNone) {
                                std::cerr << "There was an error (" << err << ") toggling port " << port << " data" << std::endl;
                                break;
                            }
                            else {
                                if (power) {
                                    if (vbusState)  { err = usb.setPowerDisable(port); }
                                    else            { err = usb.setPowerEnable(port); }
                                }
                                if (err != aErrNone) {
                                    std::cerr << "There was an error (" << err << ") toggling port " << port << " power" << std::endl;
                                    break;
                                }
                            }
                        }
                        if (err == aErrNone) {
                            std::cout << "Port: " << port << " was sucessfully toggled" << std::endl;
                        }
                    } // if (result.count("toggle"))
                    else {
                        if (enable) {
                            if (power && data) { err = usb.setPortEnable(port); }
                            else
                            {
                                if (power)  { err = usb.setPowerEnable(port); }
                                if (data)   { err = usb.setDataEnable(port); }
                            }
                        }
                        else {
                            if (power && data) { err = usb.setPortDisable(port); }
                            else
                            {
                                if (power)  { err = usb.setPowerDisable(port); }
                                if (data)   { err = usb.setDataDisable(port); }
                            }
                        }
                        if (err != aErrNone) {
                            std::cerr << "There was an error (" << err << ") " << (enable ? "enabling" : "disabling") << " port " << port << std::endl;
                            break;
                        }
                        else {
                            std::cout << "Port: " << port << " was sucessfully " << (enable ? "enabled" : "disabled") << std::endl;
                        }
                    }
                } // for (const auto& port : ports)
                
                if (err == aErrNone) {
                    if (spec->model == aMODULE_TYPE_USBHub3c) {
                        usbSystem.init(stem, 0);
                        
                        if (result.count("auto")) {
                            std::cerr << "The USBHub3c does not support auto mode" << std::endl;
                            err = aErrUnimplemented;
                        }
                        else if (result.count("upstream")) {
                            err = usbSystem.setUpstream(upstream);
                            
                            if (err != aErrNone) {
                                std::cerr << "There was an error (" << err << ") " << "changing upstream mode" << std::endl;
                            }
                            else {
                                std::cout << "Upstream successfully set to port UP" << upstream << std::endl;
                            }
                        }
                    }
                    else {
                        if (result.count("auto")) {
                            err = usb.setUpstreamMode(usbUpstreamModeAuto);
                            if (err != aErrNone) {
                                std::cerr << "There was an error (" << err << ") " << "enabling automatic upstream selection" << std::endl;
                            }
                            else { std::cout << "Upstream successfully set to automatic" << std::endl; }
                        }
                        else if (result.count("upstream")) {
                            if (upstream == 0) { err = usb.setUpstreamMode(usbUpstreamModePort0); }
                            if (upstream == 1) { err = usb.setUpstreamMode(usbUpstreamModePort1); }
                            
                            if (err != aErrNone) {
                                std::cerr << "There was an error (" << err << ") " << "changing upstream mode" << std::endl;
                            }
                            else {
                                std::cout << "Upstream successfully set to port UP" << upstream << std::endl;
                            }
                        }
                    }
                }
                
                if (err == aErrNone) {
                    
                    
                    if (result.count("verbose")) {
                        if (spec->model == aMODULE_TYPE_USBHub3c) {
                            std::cerr << "USBHub3c does not support verbose mode" << std::endl;
                        }
                        else {
                            err = usb.getUpstreamState(&upstate);
                            if (err != aErrNone) {
                                std::cerr << "There was an error (" << err << ") " << "getting upstream state" << std::endl;
                            }
                            else {
                                std::cout << "Active Upstream: ";
                                if (upstate == 2) { std::cout << "None"; }
                                else { std::cout << (int)upstate; }
                                std::cout << std::endl;
                                
                                err = usb.getHubMode(&mode);
                                if (err == aErrNone) {
                                    int portCount = 4;
                                    std::cout << "Port VBUS HS";
                                    if (spec->model == aMODULE_TYPE_USBHub3p) {
                                        std::cout << " SS";
                                        portCount = 8;
                                    }
                                    std::cout << std::endl;
                                    for (int port = 0; port < portCount; port++) {
                                        offset = 2 * port;
                                        hsState = (mode & (1 << offset)) >> offset;
                                        offset = 16 + 2 * port;
                                        ssState = (mode & (1 << offset)) >> offset;
                                        offset = 1 + 2 * port;
                                        vbusState = (mode & (1 << offset)) >> offset;
                                        std::cout << std::setfill(' ') << std::setw(4) << port;
                                        std::cout << std::setfill(' ') << std::setw(5) << vbusState;
                                        std::cout << std::setfill(' ') << std::setw(3) << hsState;
                                        
                                        if (spec->model == aMODULE_TYPE_USBHub3p) {
                                            std::cout << std::setfill(' ') << std::setw(3) << ssState;
                                        }
                                        std::cout << std::endl;
                                    }
                                }
                                else {
                                    std::cerr << "There was an error (" << err << ") " << "getting hub mode" << std::endl;
                                }
                            }
                        }
                    } // if (result.count("verbose"))
                }
            }
        }

        if(stem->isConnected()) { stem->disconnect(); }

        aLinkSpec_Destroy(&spec);
    
        delete stem;
        stem = nullptr;
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
    catch (const cxxopts::OptionException& e) {
        std::cerr << "Error parsing options: " << e.what() << std::endl;
        std::cerr << options.help() << std::endl;
        return -1;
    }
    catch (...) {
        std::cerr << "Unknown Exception Caught: " << std::endl;
        std::cerr << options.help() << std::endl;
        return -2;
    }
    return err;
}
