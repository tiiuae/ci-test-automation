/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aMTMUSBStem.h                                            //
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

#ifndef __aMTMStemModule_H__
#define __aMTMStemModule_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"


/**
 * \defgroup aMTMStemModule_Constants Module Constants
 * @{
 */
#define aMTM_STEM_MODULE_BASE_ADDRESS                               4 /**< MTM-Stem module base address */

#define aMTM_STEM_NUM_A2D                                           4 /**< Number of Analog instances available */
#define aMTM_STEM_NUM_APPS                                          4 /**< Number of App instances available */

#define aMTM_STEM_BULK_CAPTURE_MAX_HZ               analog_Hz_Maximum /**< Bulk Capture Max Hertz: 200000 */
#define aMTM_STEM_BULK_CAPTURE_MIN_HZ               analog_Hz_Minimum /**< Bulk Capture Min Hertz: 7000 */

#define aMTM_STEM_NUM_CLOCK                                         1 /**< Number of Clock instances available */
#define aMTM_STEM_NUM_DIG                                          15 /**< Number of Digital instances available  */
#define aMTM_STEM_NUM_I2C                                           2 /**< Number of I2C instances available */
#define aMTM_STEM_NUM_POINTERS                                      4 /**< Number of Pointer instances available */
#define aMTM_STEM_NUM_SERVOS                                        8 /**< Number of RC Servo instances available */

#define aMTM_STEM_NUM_SIGNALS                                       5 /**< Number of Signal instances available */
#define   aMTM_STEM_NUM_OUTPUT_SIGNALS                              4 /**< Signal mber of output signal instances available */
#define   aMTM_STEM_NUM_INPUT_SIGNALS                               5 /**< Signal mber of input signal instances available */

#define aMTM_STEM_NUM_STORES                                        3 /**< Number of Store instances available */
#define   aMTM_STEM_NUM_INTERNAL_SLOTS                             12 /**< Store mber of internal slots instances available  */
#define   aMTM_STEM_NUM_RAM_SLOTS                                   1 /**< Store mber of RAM slot instances available */
#define   aMTM_STEM_NUM_SD_SLOTS                                  255 /**< Store mber of SD slot instances available */

#define aMTM_STEM_NUM_TIMERS                                        8 /**< Number of Timer instances available */
/** @} */

// MARK: - MTMStemModule Class
/////////////////////////////////////////////////////////////////////
///  \brief Instantiation of base class MTM-Stem-Module
class aMTMStemModule : public Acroname::BrainStem::Module
{
public:

    aMTMStemModule(const uint8_t module = aMTM_STEM_MODULE_BASE_ADDRESS,
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

        signal[0].init(this, 0);
        signal[1].init(this, 1);
        signal[2].init(this, 2);
        signal[3].init(this, 3);
        signal[4].init(this, 4);
        
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
    Acroname::BrainStem::AnalogClass analog[aMTM_STEM_NUM_A2D]; /**< Analog Class */
    Acroname::BrainStem::AppClass app[aMTM_STEM_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::ClockClass clock; /**< Clock Class */
    Acroname::BrainStem::DigitalClass digital[aMTM_STEM_NUM_DIG]; /**< Digital Class */
    Acroname::BrainStem::I2CClass i2c[aMTM_STEM_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::PointerClass pointer[aMTM_STEM_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::RCServoClass servo[aMTM_STEM_NUM_SERVOS]; /**< RC Servo Class */
    Acroname::BrainStem::SignalClass signal[aMTM_STEM_NUM_SIGNALS]; /**< Signal Class */
    Acroname::BrainStem::StoreClass store[aMTM_STEM_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TimerClass timer[aMTM_STEM_NUM_TIMERS]; /**< Timer Class */
};

#endif
