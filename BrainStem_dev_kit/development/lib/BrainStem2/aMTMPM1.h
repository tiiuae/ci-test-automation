/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aMTMPM1.h	 	  	                           //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: BrainStem MTM-PM1 module object.                   //
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

#ifndef __aMTMPM1_H__
#define __aMTMPM1_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aMTMPM1_Constants MTM Power Module Constants
 * @{
 */
#define aMTMPM1_MODULE_BASE_ADDRESS                                 6 /**< MTM-PM-1 module base address */

#define aMTMPM1_NUM_APPS                                            4 /**< Number of App instances available */
#define aMTMPM1_NUM_DIGITALS                                        2 /**< Number of Digital instances available */
#define aMTMPM1_NUM_I2C                                             1 /**< Number of I2C instances available */
#define aMTMPM1_NUM_POINTERS                                        4 /**< Number of Pointer instances available */

#define aMTMPM1_NUM_RAILS                                           2 /**< Number of Rail instances available */
#define   aMTMPM1_RAIL0                                             0 /**< Rail: Define for Rail 0 */
#define   aMTMPM1_RAIL1                                             1 /**< Rail: Define for Rail 1 */
#define   aMTMPM1_MAX_MICROVOLTAGE                            5000000 /**< Rail: Max voltage in microvolts */
#define   aMTMPM1_MIN_MICROVOLTAGE                            1800000 /**< Rail: Min voltage in microvolts */
#define   aMTMPM1_MAX_CURRENT_LIMIT_MICROAMPS                 3000000 /**< Rail: Max current in microamps */
#define   aMTMPM1_MIN_CURRENT_LIMIT_MICROAMPS                       0 /**< Rail: Min current in microamps */

#define aMTMPM1_NUM_STORES                                          2 /**< Number of Store instances available */
#define   aMTMPM1_NUM_INTERNAL_SLOTS                               12 /**< Store: Number of internal slots instances available */
#define   aMTMPM1_NUM_RAM_SLOTS                                     1 /**< Store: Number of RAM slot instances available */

#define aMTMPM1_NUM_TEMPERATURES                                    1 /**< Number of Temperature instances available */
#define aMTMPM1_NUM_TIMERS                                          8 /**< Number of Timer instances available */
/** @} */

// MARK: - MTMPM1 Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of an MTM-PM-1
///         Allows a user to connect to and control an attached module
class aMTMPM1 : public Acroname::BrainStem::Module
{
public:

    aMTMPM1(const uint8_t module = aMTMPM1_MODULE_BASE_ADDRESS,
            bool bAutoNetworking = true,
            const uint8_t model = aMODULE_TYPE_MTM_PM_1) :
    Acroname::BrainStem::Module(module, bAutoNetworking, model)
    {
        app[0].init(this, 0);
        app[1].init(this, 1);
        app[2].init(this, 2);
        app[3].init(this, 3);
        
        digital[0].init(this, 0);
        digital[1].init(this, 1);

        i2c[0].init(this, 0);
        
        pointer[0].init(this, 0);
        pointer[1].init(this, 1);
        pointer[2].init(this, 2);
        pointer[3].init(this, 3);
        
        rail[0].init(this, 0);
        rail[1].init(this, 1);
        
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
    }
    Acroname::BrainStem::AppClass app[aMTMPM1_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::DigitalClass digital[aMTMPM1_NUM_DIGITALS]; /**< Digital Class */
    Acroname::BrainStem::I2CClass i2c[aMTMPM1_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::PointerClass pointer[aMTMPM1_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::RailClass rail[aMTMPM1_NUM_RAILS]; /**< Rail Class */
    Acroname::BrainStem::StoreClass store[aMTMPM1_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TemperatureClass temperature; /**< Temperature Class */
    Acroname::BrainStem::TimerClass timer[aMTMPM1_NUM_TIMERS]; /**< Timer Class */
};

#endif /* __aMTMPM1_H__ */
