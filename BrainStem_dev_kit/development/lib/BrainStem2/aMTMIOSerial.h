/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aMTMIOSerial.h	 	  	                           //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: BrainStem MTM IO Serial module object.             //
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

#ifndef __aMTMIOSerial_H__
#define __aMTMIOSerial_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aMTMIOSerial_Constants MTM-IOSerial Module Constants
 * @{
 */
#define aMTMIOSERIAL_MODULE_BASE_ADDRESS                           8 /**< MTM-IO-Serial module number */

#define aMTMIOSERIAL_NUM_APPS                                      4 /**< Number of App instances available */
#define aMTMIOSERIAL_NUM_DIGITALS                                  8 /**< Number of Digital instances available */
#define aMTMIOSERIAL_NUM_I2C                                       1 /**< Number of I2C instances available */

#define aMTMIOSERIAL_NUM_POINTERS                                  4 /**< Number of Pointer instances available */

#define aMTMIOSERIAL_NUM_RAILS                                     3 /**< Number of Rail instances available */
#define   aMTMIOSERIAL_5VRAIL                                      0 /**< Rail: 5v Rail specifier */
#define   aMTMIOSERIAL_ADJRAIL1                                    1 /**< Rail: Adjustable Rail 0 specifier */
#define   aMTMIOSERIAL_ADJRAIL2                                    2 /**< Rail: Adjustable Rail 1 specifier */
#define   aMTMIOSERIAL_MAX_MICROVOLTAGE                      5000000 /**< Rail: Max voltage in microvolts */
#define   aMTMIOSERIAL_MIN_MICROVOLTAGE                      1800000 /**< Rail: Min voltage in microvolts */

#define aMTMIOSERIAL_NUM_SERVOS                                    8 /**< Number of RC Servo instances available */

#define aMTMIOSERIAL_NUM_SIGNALS                                   5 /**< Number of Signal instances available */
#define   aMTMIOSERIAL_NUM_OUTPUT_SIGNALS                          4 /**< Signal: Number of output signal instances available */
#define   aMTMIOSERIAL_NUM_INPUT_SIGNALS                           5 /**< Signal: Number of input signal instances available */

#define aMTMIOSERIAL_NUM_STORES                                    2 /**< Number of Store instances available */
#define   aMTMIOSERIAL_NUM_INTERNAL_SLOTS                         12 /**< Store: Number of internal slots instances available */
#define   aMTMIOSERIAL_NUM_RAM_SLOTS                               1 /**< Store: Number of RAM slot instances available */

#define aMTMIOSERIAL_NUM_TIMERS                                    8 /**< Number of Timer instances available */
#define aMTMIOSERIAL_NUM_UART                                      4 /**< Number of UART instances available */
#define aMTMIOSERIAL_NUM_USB                                       1 /**< Number of USB instances available */

/* cmdUSB number of Channels */
#define   aMTMIOSERIAL_USB_NUM_CHANNELS                            4 /**< Number of channels available */

/* Upstream Modes */
#define   aUSB_UPSTREAM_CONFIG_AUTO                                0 /**< Upstream Mode specifier: Auto (Default) */
#define   aUSB_UPSTREAM_CONFIG_ONBOARD                             1 /**< Upstream Mode specifier: Onboard */
#define   aUSB_UPSTREAM_CONFIG_EDGE                                2 /**< Upstream Mode specifier: Edge Connector */

/* Upstream states */
#define   aUSB_UPSTREAM_ONBOARD                                    0 /**< Upstream State specifier: Onboard */
#define   aUSB_UPSTREAM_EDGE                                       1 /**< Upstream State specifier: Edge Connector */
/** @} */

/**
 * \defgroup aMTMIOSerial_Port_State_Defines Port State Definitions
 * \brief Bit defines for port state UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve bit value)
 * @{
 */
// Example:  if (state & _BIT(aMTMIOSERIAL_USB_VBUS_ENABLED))
#define aMTMIOSERIAL_USB_VBUS_ENABLED                              0 /**< USB VBUS current state */
#define aMTMIOSERIAL_USB2_DATA_ENABLED                             1 /**< USB2 data current state */
#define aMTMIOSERIAL_USB_ERROR_FLAG                               19 /**< Error indicator for this channel \n (see 'Port Errors' below) */
#define aMTMIOSERIAL_USB2_BOOST_ENABLED                           20 /**< USB2 boost current state */
/** @} */

/**
 * \defgroup aMTMIOSerial_Port_Error_Defines Port Error Definitions
 * \brief Bit defines for port error UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve a bit value)
 * @{
 */
// Example:  if (error & _BIT(aMTMIOSERIAL_ERROR_VBUS_OVERCURRENT))
// i.e if (error & _BIT(aMTMIOSERIAL_ERROR_VBUS_OVERCURRENT))
#define aMTMIOSERIAL_ERROR_VBUS_OVERCURRENT                        0 /**< VBUS overcurrent error */
/** @} */

// MARK: - MTMIOSerial Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of an MTM-IO-Serial
///         Allows a user to connect to and control an attached module
class aMTMIOSerial : public Acroname::BrainStem::Module
{
public:

    aMTMIOSerial(const uint8_t module = aMTMIOSERIAL_MODULE_BASE_ADDRESS,
                 bool bAutoNetworking = true,
                 const uint8_t model = aMODULE_TYPE_MTMIOSerial_1) :
    Acroname::BrainStem::Module(module, bAutoNetworking, model)
    {

        digital[0].init(this, 0);
        digital[1].init(this, 1);
        digital[2].init(this, 2);
        digital[3].init(this, 3);
        digital[4].init(this, 4);
        digital[5].init(this, 5);
        digital[6].init(this, 6);
        digital[7].init(this, 7);

        app[0].init(this, 0);
        app[1].init(this, 1);
        app[2].init(this, 2);
        app[3].init(this, 3);

        i2c[0].init(this, 0);
        
        uart[0].init(this, 0);
        uart[1].init(this, 1);
        uart[2].init(this, 2);
        uart[3].init(this, 3);
        
        pointer[0].init(this, 0);
        pointer[1].init(this, 1);
        pointer[2].init(this, 2);
        pointer[3].init(this, 3);

        rail[aMTMIOSERIAL_5VRAIL].init(this, 0);
        rail[aMTMIOSERIAL_ADJRAIL1].init(this, 1);
        rail[aMTMIOSERIAL_ADJRAIL2].init(this, 2);

        servo[0].init(this, 0);
        servo[1].init(this, 1);
        servo[2].init(this, 2);
        servo[3].init(this, 3);
        servo[4].init(this, 4);
        servo[5].init(this, 5);
        servo[6].init(this, 6);
        servo[7].init(this, 7);

        signal[0].init(this, 0);
        signal[1].init(this, 1);
        signal[2].init(this, 2);
        signal[3].init(this, 3);
        signal[4].init(this, 4);

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
    Acroname::BrainStem::AppClass app[aMTMIOSERIAL_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::DigitalClass digital[aMTMIOSERIAL_NUM_DIGITALS]; /**< Digital Class */
    Acroname::BrainStem::I2CClass i2c[aMTMIOSERIAL_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::UARTClass uart[aMTMIOSERIAL_NUM_UART]; /**< UART Class */
    Acroname::BrainStem::PointerClass pointer[aMTMIOSERIAL_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::RailClass rail[aMTMIOSERIAL_NUM_RAILS]; /**< Rail Class */
    Acroname::BrainStem::RCServoClass servo[aMTM_STEM_NUM_SERVOS]; /**< RC Servo Class */
    Acroname::BrainStem::SignalClass signal[aMTMIOSERIAL_NUM_SIGNALS]; /**< Signal Class */
    Acroname::BrainStem::StoreClass store[aMTMIOSERIAL_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TemperatureClass temperature; /**< Temperature Class */
    Acroname::BrainStem::TimerClass timer[aMTMIOSERIAL_NUM_TIMERS]; /**< Timer Class */
    Acroname::BrainStem::USBClass usb; /**< USB Class */
};

#endif /* __aMTMIOSerial_H__ */
