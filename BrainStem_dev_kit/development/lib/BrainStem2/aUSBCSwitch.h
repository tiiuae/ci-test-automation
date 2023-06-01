/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aUSBCSwitch.h	 	  	                                   //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: USBCSwitch C++ Module object.                      //
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

#ifndef __aUSBCSwitch_H__
#define __aUSBCSwitch_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aUSBCSwitch_Constants USBCSwitch Module Constants
 * @{
 */
#define aUSBCSWITCH_MODULE                                      6  /**< USBCSwitch module number */

#define aUSBCSWITCH_NUM_APPS                                    4 /**< Number of App instances available */
#define aUSBCSWITCH_NUM_POINTERS                                4 /**< Number of Pointer instances available */

#define aUSBCSWITCH_NUM_STORES                                  2 /**< Number of Store instances available */
#define   aUSBCSWITCH_NUM_INTERNAL_SLOTS                       12 /**< Store: Number of internal slots instances available */
#define   aUSBCSWITCH_NUM_RAM_SLOTS                             1 /**< Store: Number of RAM slot instances available */

#define aUSBCSWITCH_NUM_TIMERS                                  8 /**< Number of Timer instances available */
#define aUSBCSWITCH_NUM_USB                                     1 /**< Number of USB instances available */ 
#define aUSBCSWITCH_NUM_MUX                                     1 /**< Number of Mux instances available */ 
#define aUSBCSWITCH_NUM_EQ                                      2 /**< Number of Equalizer instances available */ 
#define   aUSBCSWITCH_NUM_MUX_CHANNELS                          4 /**< Number of Mux channels available */ 
/** @} */

/**
 * \defgroup aUSBCSwitch_Port_State_Defines Port State Definitions
 * \brief Bit defines for port state UInt32
 * \brief (Tip: Use _BIT(X) from aDefs.h to retrieve bit value)
 * @{
 */
// Example:  if (state & _BIT(aUSBCSwitch_USB_VBUS_ENABLED))
#define usbPortStateVBUS                               0 /**< USB VBUS current state */
#define usbPortStateUSB2A                              1 /**< USB2 side A current state */
#define usbPortStateUSB2B                              2 /**< USB2 side B current state */
#define usbPortStateSBU                                3 /**< SBU current state */
#define usbPortStateSS1                                4 /**< SS1 current state */
#define usbPortStateSS2                                5 /**< SS2 A current state */
#define usbPortStateCC1                                6 /**< CC1 current state */
#define usbPortStateCC2                                7 /**< CC2 A current state */
#define set_usbPortStateCOM_ORIENT_STATUS(var, state)  ((var & ~(3 << 8 )) | (state << 8)) /**< Common side orientation status */
#define get_usbPortStateCOM_ORIENT_STATUS(var)         ((var &  (3 << 8 )) >> 8) /**< Common side orientation status */
#define set_usbPortStateMUX_ORIENT_STATUS(var, state)  ((var & ~(3 << 10 )) | (state << 10)) /**< Mux side orientation status */
#define get_usbPortStateMUX_ORIENT_STATUS(var)         ((var &  (3 << 10 )) >> 10) /**< Mux side orientation status */
#define set_usbPortStateSPEED_STATUS(var, state)       ((var & ~(3 << 12)) | (state << 12)) /**< USB speed status */
#define get_usbPortStateSPEED_STATUS(var)              ((var &  (3 << 12)) >> 12) /**< USB speed status */
#define usbPortStateCCFlip                             14 /**< CC flip status */
#define usbPortStateSSFlip                             15 /**< SS flip status */
#define usbPortStateSBUFlip                            16 /**< SBU flip status */
#define usbPortStateUSB2Flip                           17 /**< USB2 flip status */
#define get_usbPortStateDaughterCard(var)              ((var & (3 << 18)) >> 18) /**< Daughter card status */
#define usbPortStateErrorFlag                          20 /**< Error indicator for this port */
#define usbPortStateUSB2Boost                          21 /**< USB2 boost current state */
#define usbPortStateUSB3Boost                          22 /**< USB3 boost current state */
#define usbPortStateConnectionEstablished              23 /**< Connection established state */
#define usbPortStateCC1Inject                          26 /**< CC1 inject current state */
#define usbPortStateCC2Inject                          27 /**< CC2 inject current state */
#define usbPortStateCC1Detect                          28 /**< CC1 detect current state */
#define usbPortStateCC2Detect                          29 /**< CC2 detect current state */
#define usbPortStateCC1LogicState                      30 /**< CC1 logic current state */
#define usbPortStateCC2LogicState                      31 /**< CC2 logic current state */
/** @} */

/**
 * \defgroup aUSBCSwitch_Port_Orientation_Defines Port Orientation Definitions
 * \brief State defines for 2 bit orientation elements.
 * @{
 */
#define usbPortStateOff                                0 /**< Indicator for port state off */
#define usbPortStateSideA                              1 /**< Indicator for port side A */
#define usbPortStateSideB                              2 /**< Indicator for port side B */
#define usbPortStateSideUndefined                      3 /**< Indicator for port side undefined */
/** @} */

// MARK: - USBCSwitch Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of a USBCSwitch
///         Allows a user to connect to and control an attached switch
class aUSBCSwitch : public Acroname::BrainStem::Module
{
public:
    
    aUSBCSwitch(const uint8_t module = aUSBCSWITCH_MODULE,
                bool bAutoNetworking = true,
                const uint8_t model = aMODULE_TYPE_USBC_Switch) :
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
        
        mux.init(this, 0);
        
        timer[0].init(this, 0);
        timer[1].init(this, 1);
        timer[2].init(this, 2);
        timer[3].init(this, 3);
        timer[4].init(this, 4);
        timer[5].init(this, 5);
        timer[6].init(this, 6);
        timer[7].init(this, 7);
        
        usb.init(this, 0);
        
        equalizer[equalizer2p0].init(this, equalizer2p0);
        equalizer[equalizer3p0].init(this, equalizer3p0);
    }
    Acroname::BrainStem::AppClass app[aUSBCSWITCH_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::MuxClass mux; /**< Mux Class */
    Acroname::BrainStem::PointerClass pointer[aUSBCSWITCH_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::StoreClass store[aUSBCSWITCH_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TimerClass timer[aUSBCSWITCH_NUM_TIMERS]; /**< Timer Class */
    Acroname::BrainStem::USBClass usb; /**< USB Class */
    Acroname::BrainStem::EqualizerClass equalizer[aUSBCSWITCH_NUM_EQ]; /**< Equalizer Class */
    
    /** Equalizer 3P0 transmitter configs */
    enum EQUALIZER_3P0_TRANSMITTER_CONFIGS {
        MUX_1db_COM_0db_900mV = 0,
        MUX_0db_COM_1db_900mV,
        MUX_1db_COM_1db_900mV,
        MUX_0db_COM_0db_900mV,
        MUX_0db_COM_0db_1100mV,
        MUX_1db_COM_0db_1100mV,
        MUX_0db_COM_1db_1100mV,
        MUX_2db_COM_2db_1100mV,
        MUX_0db_COM_0db_1300mV,
    };
    
    /** Equalizer 3P0 receiver configs */
    enum EQUALIZER_3P0_RECEIVER_CONFIGS {
        LEVEL_1_3P0 = 0,
        LEVEL_2_3P0,
        LEVEL_3_3P0,
        LEVEL_4_3P0,
        LEVEL_5_3P0,
        LEVEL_6_3P0,
        LEVEL_7_3P0,
        LEVEL_8_3P0,
        LEVEL_9_3P0,
        LEVEL_10_3P0,
        LEVEL_11_3P0,
        LEVEL_12_3P0,
        LEVEL_13_3P0,
        LEVEL_14_3P0,
        LEVEL_15_3P0,
        LEVEL_16_3P0,
    };
    
    /** Equalizer 2P0 transmitter configs */
    enum EQUALIZER_2P0_TRANSMITTER_CONFIGS {
        TRANSMITTER_2P0_40mV = 0,
        TRANSMITTER_2P0_60mV,
        TRANSMITTER_2P0_80mV,
        TRANSMITTER_2P0_0mV,
    };
    
    /** Equalizer 3P0 receiver configs */
    enum EQUALIZER_2P0_RECEIVER_CONFIGS {
        LEVEL_1_2P0 = 0,
        LEVEL_2_2P0,
    };
    
    /** Equalizer channels */
    enum EQUALIZER_CHANNELS {
        BOTH = 0,
        MUX,
        COMMON
    };
    
    /** Daughter Cards */
    enum daughtercard_type {
        NO_DAUGHTERCARD = 0,
        PASSIVE_DAUGHTERCARD,
        REDRIVER_DAUGHTERCARD,
        UNKNOWN_DAUGHTERCARD
    };
};



#endif /* aUSBCSwitch_h */
