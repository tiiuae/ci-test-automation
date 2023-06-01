/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aUSBHub3c.h	 	  	                                   //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: USBHub3c C++ Module object.                        //
//                                                                 //
// build number: source                                            //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2018 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////

#ifndef __aUSBHub3c_H__
#define __aUSBHub3c_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

#ifdef PRE_RELEASE
#include "BrainStem-PreRelease.h"
#endif

/**
 * \defgroup aUSBHub3c_Constants USBHub3c Module Constants
 * @{
 */
#define aUSBHUB3C_MODULE                                          6 /**< USBHub3c module number */

#define aUSBHUB3C_NUM_APPS                                        4 /**< Number of App instances available */
#define aUSBHUB3C_NUM_POINTERS                                    4 /**< Number of Pointer instances available */

#define aUSBHUB3C_NUM_STORES                                      2 /**< Number of Store instances available */
#define   aUSBHUB3C_NUM_INTERNAL_SLOTS                           12 /**< Store: Number of internal slots instances available */
#define   aUSBHUB3C_NUM_RAM_SLOTS                                 1 /**< Store: Number of RAM slot instances available */
#define aUSBHUB3C_STORE_INTERNAL_INDEX                            0 /**< Store: Array index for internal store */
#define aUSBHUB3C_STORE_RAM_INDEX                                 1 /**< Store: Array index for RAM store */
#define aUSBHUB3C_STORE_EEPROM_INDEX                              2 /**< Store: Array index for EEPROM store */

#define aUSBHUB3C_NUM_TEMPERATURES                                3 /**< Number of Temperature instances available */
#define aUSBHUB3C_NUM_TIMERS                                      8 /**< Number of Timer instances available */
#define aUSBHUB3C_NUM_USB                                         1 /**< Number of USB instances available */
#define aUSBHUB3C_NUM_USB_PORTS                                   8 /**< Number of USB ports available */
#define aUSBHUB3C_NUM_PD_PORTS                                    8 /**< Number of PD compatible ports available */
#define aUSBHUB3C_NUM_PD_RULES_PER_PORT                           7 /**< Number of PD Rules per port available */
#define aUSBHUB3C_NUM_RAILS                                       7 /**< Number of Rail instances available */
#define aUSBHUB3C_NUM_I2C                                         1 /**< Number of I2C instances available */
#define aUSBHUB3C_NUM_UART                                        1 /**< Number of UART instances available */

/** @} */




// MARK: - USBHub3c Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of a USBHub3c
///         Allows a user to connect to and control an attached hub
class aUSBHub3c : public Acroname::BrainStem::Module
{
public:

    // MARK: - USBHub Class
    /////////////////////////////////////////////////////////////////////
    ///  \brief Hub class implementation for use with USBHub3c
    class HubClass : public Acroname::BrainStem::USBSystemClass {
    public:
        void init(Acroname::BrainStem::Module* pModule, const uint8_t index) {
            Acroname::BrainStem::USBSystemClass::init(pModule, index);
            for (int x = 0; x < aUSBHUB3C_NUM_USB_PORTS; x++) {
                port[x].init(pModule, x);
            }
        }

        Acroname::BrainStem::PortClass port[aUSBHUB3C_NUM_USB_PORTS];
    };



    aUSBHub3c(const uint8_t module = aUSBHUB3C_MODULE,
              bool bAutoNetworking = true,
              const uint8_t model = aMODULE_TYPE_USBHub3c) :
    Acroname::BrainStem::Module(module, bAutoNetworking, model)
    {
        for(int x = 0; x < aUSBHUB3C_NUM_APPS; x++) {
            app[x].init(this, x);
        }
        
        for(int x = 0; x < aUSBHUB3C_NUM_PD_PORTS; x++) {
            pd[x].init(this, x);
        }

        for(int x = 0; x < aUSBHUB3C_NUM_POINTERS; x++) {
            pointer[x].init(this, x);
        }
        
        store[aUSBHUB3C_STORE_INTERNAL_INDEX].init(this, storeInternalStore);
        store[aUSBHUB3C_STORE_RAM_INDEX].init(this, storeRAMStore);
        store[aUSBHUB3C_STORE_EEPROM_INDEX].init(this, storeEEPROMStore);
        
        system.init(this, 0);
        
        for(int x = 0; x < aUSBHUB3C_NUM_TEMPERATURES; x++) {
            temperature[x].init(this, x);
        }
        
        for(int x = 0; x < aUSBHUB3C_NUM_TIMERS; x++) {
            timer[x].init(this, x);
        }
        
        hub.init(this, 0);
        
        for(int x = 0; x < aUSBHUB3C_NUM_RAILS; x++) {
            rail[x].init(this, x);
        }

        i2c[0].init(this, 0);
        uart[0].init(this, 0);

        usb.init(this, 0); /**< USB Class for adding minimal legacy support */
    }
    
    HubClass hub; /**< Hub Class */
    Acroname::BrainStem::AppClass app[aUSBHUB3C_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::PointerClass pointer[aUSBHUB3C_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::PowerDeliveryClass pd[aUSBHUB3C_NUM_USB_PORTS]; /**< Power Delivery Class */
    Acroname::BrainStem::RailClass rail[aUSBHUB3C_NUM_RAILS]; /**< Rail Class */
    Acroname::BrainStem::StoreClass store[aUSBHUB3C_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TemperatureClass temperature[aUSBHUB3C_NUM_TEMPERATURES]; /**< Temperature Class */
    Acroname::BrainStem::TimerClass timer[aUSBHUB3C_NUM_TIMERS]; /**< Timer Class */
    Acroname::BrainStem::I2CClass i2c[aUSBHUB3C_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::USBClass usb; /**< USB Class */
    Acroname::BrainStem::UARTClass uart[aUSBHUB3C_NUM_UART]; /**< UART Class */ 

    
    /** Port ID */
    typedef enum PORT_ID {
        kPORT_ID_0 = 0,
        kPORT_ID_1,
        kPORT_ID_2,
        kPORT_ID_3,
        kPORT_ID_4,
        kPORT_ID_5,
        kPORT_ID_CONTROL,
        kPORT_ID_POWER_C
    } PORT_ID_t;
    
};

#endif /* __aUSBHub3c_H__ */
