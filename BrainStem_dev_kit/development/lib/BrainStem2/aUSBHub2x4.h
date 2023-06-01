/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aUSBHub2x4.h	 	  	                           //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: USBHub2x4 C++ Module object.                       //
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

#ifndef __aUSBHub2x4_H__
#define __aUSBHub2x4_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aUSBHub2x4_Constants USBHub2x4 Module Constants
 * @{
 */
#define aUSBHUB2X4_MODULE                                         6 /**< USBHub2x4 module number */

#define aUSBHUB2X4_NUM_APPS                                       4 /**< Number of App instances available */
#define aUSBHUB2X4_NUM_POINTERS                                   4 /**< Number of Pointer instances available */

#define aUSBHUB2X4_NUM_STORES                                     2 /**< Number of Store instances available */
#define   aUSBHUB2X4_NUM_INTERNAL_SLOTS                          12 /**< Store: Number of internal slots instances available */
#define   aUSBHUB2X4_NUM_RAM_SLOTS                                1 /**< Store: Number of RAM slot instances available */

#define aUSBHUB2X4_NUM_TIMERS                                     8 /**< Number of Timer instances available */
#define aUSBHUB2X4_NUM_USB                                        1 /**< Number of USB instances available */
#define aUSBHUB2x4_NUM_USB_PORTS                                  4 /**< Number of USB ports available */
/** @} */

/**
 * \defgroup aUSBHub2x4_Port_State_Defines Port State Definitions
 * \brief Bit defines for port state UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve bit value)
 * @{
 */
// Example:  if (state & _BIT(aUSBHUB2x4_USB_VBUS_ENABLED))
#define aUSBHUB2X4_USB_VBUS_ENABLED                                0 /**< USB VBUS current state */
#define aUSBHUB2X4_USB2_DATA_ENABLED                               1 /**< USB2 data current state */
#define aUSBHUB2X4_USB_ERROR_FLAG                                 19 /**< Error indicator for this port \n (see 'Port Errors' below) */
#define aUSBHUB2X4_USB2_BOOST_ENABLED                             20 /**< USB2 boost current state */
#define aUSBHUB2X4_DEVICE_ATTACHED                                23 /**< Device attached indicator for this port */
#define aUSBHUB2X4_CONSTANT_CURRENT                               24 /**< Constant current mode indicator */
/** @} */

/**
 * \defgroup aUSBHub2x4_Port_Error_Defines Port Error Definitiions
 * \brief Bit defines for port error UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve a bit value)
 * @{
 */
// Example:  if (error & _BIT(aUSBHUB2x4_ERROR_VBUS_OVERCURRENT))
#define aUSBHUB2X4_ERROR_VBUS_OVERCURRENT                          0 /**< VBUS overcurrent error */
#define aUSBHUB2X4_ERROR_OVER_TEMPERATURE                          3 /**< Over temperature error */
#define aUSBHub2X4_ERROR_DISCHARGE                                 4 /**< Discharge error */
/** @} */

// MARK: - USBHub2x4 Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of a USBHub2x4
///         Allows a user to connect to and control an attached hub
class aUSBHub2x4 : public Acroname::BrainStem::Module
{
public:

    aUSBHub2x4(const uint8_t module = aUSBHUB2X4_MODULE,
               bool bAutoNetworking = true,
               const uint8_t model = aMODULE_TYPE_USBHub2x4) :
    Acroname::BrainStem::Module(module, bAutoNetworking, model)
    {
        app[0].init(this, 0);
        app[1].init(this, 1);
        app[2].init(this, 2);
        app[3].init(this, 3);
        
        pointer[0].init(this, 0);
        pointer[1].init(this, 1);
        pointer[2].init(this, 2);
        pointer[3].init(this, 3);
        
        store[storeInternalStore].init(this, storeInternalStore);
        store[storeRAMStore].init(this, storeRAMStore);
        
        system.init(this, 0);
        
        temperature.init(this, 0);
        
        timer[0].init(this, 0);
        timer[1].init(this, 1);
        timer[2].init(this, 2);
        timer[3].init(this, 3);
        timer[4].init(this, 4);
        timer[5].init(this, 5);
        timer[6].init(this, 6);
        timer[7].init(this, 7);
        
        usb.init(this, 0);
    }
    Acroname::BrainStem::AppClass app[aUSBHUB2X4_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::PointerClass pointer[aUSBHUB2X4_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::StoreClass store[aUSBHUB2X4_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TemperatureClass temperature; /**< Temperature Class */
    Acroname::BrainStem::TimerClass timer[aUSBHUB2X4_NUM_TIMERS]; /**< Timer Class */
    Acroname::BrainStem::USBClass usb; /**< USB Class */
};

#endif /* __aUSBHub2x4_H__ */
