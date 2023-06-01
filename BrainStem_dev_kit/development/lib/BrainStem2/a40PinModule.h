/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: a40PinModule.h                                            //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: Definition of the Acroname 40-pin module object.   //
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

#ifndef __a40PinModule_H__
#define __a40PinModule_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup a40PinModule_Constants 40 Pin Module Constants
 * @{
 */
#define a40PINSTEM_MODULE                                            2 /**< 40-Pin Module base address */

#define a40PINSTEM_NUM_A2D                                           4 /**< Number of Analog instances available */
#define a40PINSTEM_NUM_APPS                                          4 /**< Number of App instances available */

#define a40PINSTEM_BULK_CAPTURE_MAX_HZ               analog_Hz_Maximum /**< Bulk Capture Max Hertz */
#define a40PINSTEM_BULK_CAPTURE_MIN_HZ               analog_Hz_Minimum /**< Bulk Capture Min Hertz */

#define a40PINSTEM_NUM_CLOCK                                         1 /**< Number of Clock instances available */
#define a40PINSTEM_NUM_DIG                                          15 /**< Number of Digital instances available */
#define a40PINSTEM_NUM_I2C                                           2 /**< Number of I2C instances available */
#define a40PINSTEM_NUM_POINTERS                                      4 /**< Number of Pointer instances available */
#define a40PINSTEM_NUM_SERVOS                                        8 /**< Number of RC Servo instances available */

#define a40PINSTEM_NUM_STORES                                        3 /**< Number of Store instances available */
#define   a40PINSTEM_NUM_INTERNAL_SLOTS                             12 /**< Store: Number of internal slots instances available */
#define   a40PINSTEM_NUM_RAM_SLOTS                                   1 /**< Store: Number of RAM slot instances available */
#define   a40PINSTEM_NUM_SD_SLOTS                                  255 /**< Store: Number of SD slot instances available */

#define a40PINSTEM_NUM_TIMERS                                        8 /**< Number of Timer instances available */
/** @} */

// MARK: - 40PinModule Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of a 40-Pin Module
///         Allows a user to connect to and control an attached module
class a40PinModule : public Acroname::BrainStem::Module
{
public:
    
    a40PinModule(const uint8_t module = a40PINSTEM_MODULE,
                 bool bAutoNetworking = true,
                 const uint8_t model = 0) :
    Acroname::BrainStem::Module(module, bAutoNetworking, model)
    {
        
        analog[0].init(this, 0);
        analog[1].init(this, 1);
        analog[2].init(this, 2);
        analog[3].init(this, 3);
        
        app[0].init(this, 0);
        app[1].init(this, 1);
        app[2].init(this, 2);
        app[3].init(this, 3);
        
        clock.init(this, 0);
        
        digital[0].init(this, 0);
        digital[1].init(this, 1);
        digital[2].init(this, 2);
        digital[3].init(this, 3);
        digital[4].init(this, 4);
        digital[5].init(this, 5);
        digital[6].init(this, 6);
        digital[7].init(this, 7);
        digital[8].init(this, 8);
        digital[9].init(this, 9);
        digital[10].init(this, 10);
        digital[11].init(this, 11);
        digital[12].init(this, 12);
        digital[13].init(this, 13);
        digital[14].init(this, 14);
        
        i2c[0].init(this,0);
        i2c[1].init(this,1);
        
        pointer[0].init(this, 0);
        pointer[1].init(this, 1);
        pointer[2].init(this, 2);
        pointer[3].init(this, 3);
        
        servo[0].init(this, 0);
        servo[1].init(this, 1);
        servo[2].init(this, 2);
        servo[3].init(this, 3);
        servo[4].init(this, 4);
        servo[5].init(this, 5);
        servo[6].init(this, 6);
        servo[7].init(this, 7);
        
        store[storeInternalStore].init(this, storeInternalStore);
        store[storeRAMStore].init(this, storeRAMStore);
        store[storeSDStore].init(this, storeSDStore);
        
        system.init(this, 0);
        
        timer[0].init(this, 0);
        timer[1].init(this, 1);
        timer[2].init(this, 2);
        timer[3].init(this, 3);
        timer[4].init(this, 4);
        timer[5].init(this, 5);
        timer[6].init(this, 6);
        timer[7].init(this, 7);
        
    }
    Acroname::BrainStem::AnalogClass analog[a40PINSTEM_NUM_A2D]; /**< Analog Class */
    Acroname::BrainStem::AppClass app[a40PINSTEM_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::ClockClass clock; /**< Clock Class */
    Acroname::BrainStem::DigitalClass digital[a40PINSTEM_NUM_DIG]; /**< Digital Class */
    Acroname::BrainStem::I2CClass i2c[a40PINSTEM_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::PointerClass pointer[a40PINSTEM_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::RCServoClass servo[a40PINSTEM_NUM_SERVOS]; /**< RC Servo Class */
    Acroname::BrainStem::StoreClass store[a40PINSTEM_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TimerClass timer[a40PINSTEM_NUM_TIMERS]; /**< Timer Class */
};

#endif
