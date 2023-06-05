/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aMTMLoad1.h	 	  	                           //
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

#ifndef __aMTMLoad1_H__
#define __aMTMLoad1_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aMTMLoad1_Constants MTM-Load Module Constants
 * @{
 */
#define aMTMLOAD1_MODULE_BASE_ADDRESS                                14 /**< MTM-Load-1 module base address */

#define aMTMLOAD1_NUM_APPS                                            4 /**< Number of App instances available */
#define aMTMLOAD1_NUM_DIGITALS                                        4 /**< Number of Digital instances available */
#define aMTMLOAD1_NUM_I2C                                             1 /**< Number of I2C instances available */
#define aMTMLOAD1_NUM_POINTERS                                        4 /**< Number of Pointer instances available */

#define aMTMLOAD1_NUM_RAILS                                           1 /**< Number of Rail instances available */
#define   aMTMLOAD1_RAIL0                                             0 /**< Rail: Define for Rail 0 */
#define   aMTMLOAD1_MAX_MICROVOLTAGE                           32000000 /**< Rail: Max voltage in microvolts */
#define   aMTMLOAD1_MIN_MICROVOLTAGE                                  0 /**< Rail: Min voltage in microvolts */
#define   aMTMLOAD1_MAX_MICROAMPS                              11000000 /**< Rail: Max current in microamps */
#define   aMTMLOAD1_MIN_MICROAMPS                                     0 /**< Rail: Min current in microamps */
#define   aMTMLOAD1_MAX_MILLIWATTS                               150000 /**< Rail: Max power in milliwatts */
#define   aMTMLOAD1_MIN_MILLIWATTS                                    0 /**< Rail: Min power in milliwatts */
#define   aMTMLOAD1_MAX_MILLIOHMS                            1000000000 /**< Rail: Max resistance in milliohms */
#define   aMTMLOAD1_MIN_MILLIOHMS                                     0 /**< Rail: Min resistance in milliohms */
#define   aMTMLOAD1_MAX_VOLTAGE_LIMIT_MICROVOLTS               35000000 /**< Rail: Max voltage limit in microvolts */
#define   aMTMLOAD1_MIN_VOLTAGE_LIMIT_MICROVOLTS                -700000 /**< Rail: Min voltage limit in microvolts */
#define   aMTMLOAD1_MAX_CURRENT_LIMIT_MICROAMPS                12000000 /**< Rail: Max current limit in microamps */
#define   aMTMLOAD1_MIN_CURRENT_LIMIT_MICROAMPS                -1000000 /**< Rail: Min current limit in microamps */
#define   aMTMLOAD1_MAX_POWER_LIMIT_MILLIWATTS                   150000 /**< Rail: Max power limit in milliwatts */
#define   aMTMLOAD1_MIN_POWER_LIMIT_MILLIWATTS                        0 /**< Rail: Min power limit in milliwatts */

#define aMTMLOAD1_NUM_STORES                                          2 /**< Number of Store instances available */
#define   aMTMLOAD1_NUM_INTERNAL_SLOTS                               12 /**< Store: Number of internal slots instances available */
#define   aMTMLOAD1_NUM_RAM_SLOTS                                     1 /**< Store: Number of RAM slot instances available */

#define aMTMLOAD1_NUM_TEMPERATURES                                    1 /**< Number of Temperature instances available */
#define aMTMLOAD1_NUM_TIMERS                                          8 /**< Number of Timer instances available */
/** @} */


// MARK: - MTMLoad1 Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of an MTM-Load-1
///         Allows a user to connect to and control an attached module
class aMTMLoad1 : public Acroname::BrainStem::Module
{
public:

    aMTMLoad1(const uint8_t module = aMTMLOAD1_MODULE_BASE_ADDRESS,
            bool bAutoNetworking = true,
            const uint8_t model = aMODULE_TYPE_MTM_LOAD_1) :
    Acroname::BrainStem::Module(module, bAutoNetworking, model)
    {
        app[0].init(this, 0);
        app[1].init(this, 1);
        app[2].init(this, 2);
        app[3].init(this, 3);

        digital[0].init(this, 0);
        digital[1].init(this, 1);
        digital[2].init(this, 2);
        digital[3].init(this, 3);

        i2c[0].init(this, 0);

        pointer[0].init(this, 0);
        pointer[1].init(this, 1);
        pointer[2].init(this, 2);
        pointer[3].init(this, 3);

        rail[0].init(this, 0);

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
    Acroname::BrainStem::AppClass app[aMTMLOAD1_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::DigitalClass digital[aMTMLOAD1_NUM_DIGITALS]; /**< Digital Class */
    Acroname::BrainStem::I2CClass i2c[aMTMLOAD1_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::PointerClass pointer[aMTMLOAD1_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::RailClass rail[aMTMLOAD1_NUM_RAILS]; /**< Rail Class */
    Acroname::BrainStem::StoreClass store[aMTMLOAD1_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TemperatureClass temperature; /**< Temperature Class */
    Acroname::BrainStem::TimerClass timer[aMTMLOAD1_NUM_TIMERS]; /**< Timer Class */
};

#endif /* __aMTMLoad1_H__ */
