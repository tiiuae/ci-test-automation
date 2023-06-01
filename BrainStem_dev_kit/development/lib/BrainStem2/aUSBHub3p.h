/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aUSBHub3p.h	 	  	                                   //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: USBHub3p C++ Module object.                        //
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

#ifndef __aUSBHub3p_H__
#define __aUSBHub3p_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aUSBHub3p_Constants USBHub3p Module Constants
 * @{
 */
#define aUSBHUB3P_MODULE                                          6 /**< USBHub3p module number */

#define aUSBHUB3P_NUM_APPS                                        4 /**< Number of App instances available */
#define aUSBHUB3P_NUM_POINTERS                                    4 /**< Number of Pointer instances available */

#define aUSBHUB3P_NUM_STORES                                      2 /**< Number of Store instances available */
#define   aUSBHUB3P_NUM_INTERNAL_SLOTS                           12 /**< Store: Number of internal slots instances available */
#define   aUSBHUB3P_NUM_RAM_SLOTS                                 1 /**< Store: Number of RAM slot instances available */

#define aUSBHUB3P_NUM_TIMERS                                      8 /**< Number of Timer instances available */
#define aUSBHUB3P_NUM_USB                                         1 /**< Number of USB instances available */
#define aUSBHUB3P_NUM_USB_PORTS                                   8 /**< Number of USB ports available */
/** @} */

/**
 * \defgroup aUSBHub3p_Port_State_Defines Port State Definitions
 * \brief Bit defines for port state UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve bit value)
 * @{
 */
// Example:  if (state & _BIT(aUSBHUB3P_USB_VBUS_ENABLED))
#define aUSBHUB3P_USB_VBUS_ENABLED                                0 /**< USB VBUS current state */
#define aUSBHUB3P_USB2_DATA_ENABLED                               1 /**< USB2 data current state */
#define aUSBHUB3P_USB3_DATA_ENABLED                               3 /**< USB3 data current state */
#define aUSBHUB3P_USB_SPEED_USB2                                 11 /**< USB2 speed current state */
#define aUSBHUB3P_USB_SPEED_USB3                                 12 /**< USB3 speed current state */
#define aUSBHUB3P_USB_ERROR_FLAG                                 19 /**< Error indicator for this port \n (see 'Port Errors' below) */
#define aUSBHUB3P_USB2_BOOST_ENABLED                             20 /**< USB2 boost current state */
#define aUSBHUB3P_DEVICE_ATTACHED                                23 /**< Device attached indicator for this port */
/** @} */

/**
 * \defgroup aUSBHub3p_Port_Error_Defines Port Error Definitions
 * \brief Bit defines for port error UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve a bit value)
 * @{
 */
// Example:  if (error & _BIT(aUSBHUB3P_ERROR_VBUS_OVERCURRENT))
#define aUSBHUB3P_ERROR_VBUS_OVERCURRENT                          0 /**< VBUS overcurrent error */
#define aUSBHUB3P_ERROR_VBUS_BACKDRIVE                            1 /**< VBUS backdrive (backpower) error */
#define aUSBHUB3P_ERROR_HUB_POWER                                 2 /**< Hub power error */
#define aUSBHUB3P_ERROR_OVER_TEMPERATURE                          3 /**< Over temperature error */
/** @} */

// MARK: - USBHub3p Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of a aUSBHub3p
///         Allows a user to connect to and control an attached hub
class aUSBHub3p : public Acroname::BrainStem::Module
{
public:

    aUSBHub3p(const uint8_t module = aUSBHUB3P_MODULE,
              bool bAutoNetworking = true,
              const uint8_t model = aMODULE_TYPE_USBHub3p) :
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
    Acroname::BrainStem::AppClass app[aUSBHUB3P_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::PointerClass pointer[aUSBHUB3P_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::StoreClass store[aUSBHUB3P_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TemperatureClass temperature; /**< Temperature Class */
    Acroname::BrainStem::TimerClass timer[aUSBHUB3P_NUM_TIMERS]; /**< Timer Class */
    Acroname::BrainStem::USBClass usb; /**< USB Class */
};

#endif /* __aUSBHub3p_H__ */
