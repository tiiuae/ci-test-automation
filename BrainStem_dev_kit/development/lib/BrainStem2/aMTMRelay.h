/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aMTMRelay.h	 	  	                                   //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: BrainStem MTM-RELAY module object.                 //
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

#ifndef __aMTMRelay_H__
#define __aMTMRelay_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aMTMRelay_Constants MTM-Relay Module Constants
 * @{
 */
#define aMTMRELAY_MODULE_BASE_ADDRESS                              12 /**< MTM-RELAY module base address */

#define aMTMRELAY_NUM_APPS                                          4 /**< Number of App instances available */
#define aMTMRELAY_NUM_DIGITALS                                      4 /**< Number of Digital instances available */
#define aMTMRELAY_NUM_I2C                                           1 /**< Number of I2C instances available */
#define aMTMRELAY_NUM_POINTERS                                      4 /**< Number of Pointer instances available */
#define aMTMRELAY_NUM_RELAYS                                        4 /**< Number of Rail instances available */

#define aMTMRELAY_NUM_STORES                                        2 /**< Number of Store instances available */
#define   aMTMRELAY_NUM_INTERNAL_SLOTS                             12 /**< Store: Number of internal slots instances available */
#define   aMTMRELAY_NUM_RAM_SLOTS                                   1 /**< Store: Number of RAM slot instances available */

#define aMTMRELAY_NUM_TIMERS                                        8 /**< Number of Timer instances available */
/** @} */

// MARK: - MTMRelay Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of an MTM-Relay
///         Allows a user to connect to and control an attached module
class aMTMRelay : public Acroname::BrainStem::Module
{
public:
    aMTMRelay(const uint8_t module = aMTMRELAY_MODULE_BASE_ADDRESS,
              bool bAutoNetworking = true,
              const uint8_t model = aMODULE_TYPE_MTM_Relay) :
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

        relay[0].init(this, 0);
        relay[1].init(this, 1);
        relay[2].init(this, 2);
        relay[3].init(this, 3);

        store[storeInternalStore].init(this, storeInternalStore);
        store[storeRAMStore].init(this, storeRAMStore);

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
    Acroname::BrainStem::AppClass app[aMTMRELAY_NUM_APPS]; /**< App Class */
    Acroname::BrainStem::DigitalClass digital[aMTMRELAY_NUM_DIGITALS]; /**< Digital Class */
    Acroname::BrainStem::I2CClass i2c[aMTMRELAY_NUM_I2C]; /**< I2C Class */
    Acroname::BrainStem::PointerClass pointer[aMTMRELAY_NUM_POINTERS]; /**< Pointer Class */
    Acroname::BrainStem::RelayClass relay[aMTMRELAY_NUM_RELAYS]; /**< Relay Class */
    Acroname::BrainStem::StoreClass store[aMTMRELAY_NUM_STORES]; /**< Store Class */
    Acroname::BrainStem::SystemClass system; /**< System Class */
    Acroname::BrainStem::TimerClass timer[aMTMRELAY_NUM_TIMERS]; /**< Timer Class */
};

#endif /* __aMTMRelay_H__ */
