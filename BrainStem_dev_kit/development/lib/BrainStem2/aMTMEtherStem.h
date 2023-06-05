/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aMTMEtherStem.h                                           //
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

#ifndef __aMTMEtherStem_H__
#define __aMTMEtherStem_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"


/**
 * \defgroup aMTMEtherStem_Constants MTM-EterStem Module Constants
 * @{
 */
#define aMTM_ETHERSTEM_MODULE_BASE_ADDRESS  aMTM_STEM_MODULE_BASE_ADDRESS /**< MTM-EtherStem module base address */

#define aMTM_ETHERSTEM_NUM_STORES                    aMTM_STEM_NUM_STORES /**< Number of Store instances available */
#define   aMTM_ETHERSTEM_NUM_INTERNAL_SLOTS  aMTM_STEM_NUM_INTERNAL_SLOTS /**< Store: Number of internal slots instances available */
#define   aMTM_ETHERSTEM_NUM_RAM_SLOTS            aMTM_STEM_NUM_RAM_SLOTS /**< Store: Number of RAM slot instances available */
#define   aMTM_ETHERSTEM_NUM_SD_SLOTS              aMTM_STEM_NUM_SD_SLOTS /**< Store: Number of SD slot instances available */

#define aMTM_ETHERSTEM_NUM_A2D                          aMTM_STEM_NUM_A2D /**< Number of Analog instances available */
#define aMTM_ETHERSTEM_NUM_APPS                        aMTM_STEM_NUM_APPS /**< Number of App instances available */

#define aMTM_ETHERSTEM_BULK_CAPTURE_MAX_HZ  aMTM_STEM_BULK_CAPTURE_MAX_HZ /**< Bulk Capture Max Hertz */
#define aMTM_ETHERSTEM_BULK_CAPTURE_MIN_HZ  aMTM_STEM_BULK_CAPTURE_MIN_HZ /**< Bulk Capture Min Hertz */

#define aMTM_ETHERSTEM_NUM_CLOCK                      aMTM_STEM_NUM_CLOCK /**< Number of Clock instances available */
#define aMTM_ETHERSTEM_NUM_DIG                          aMTM_STEM_NUM_DIG /**< Number of Digital instances available */
#define aMTM_ETHERSTEM_NUM_I2C                          aMTM_STEM_NUM_I2C /**< Number of I2C instances available */
#define aMTM_ETHERSTEM_NUM_POINTERS                aMTM_STEM_NUM_POINTERS /**< Number of Pointer instances available */
#define aMTM_ETHERSTEM_NUM_SERVOS                    aMTM_STEM_NUM_SERVOS /**< Number of RC Servo instances available */

#define aMTM_ETHERSTEM_NUM_SIGNALS                  aMTM_STEM_NUM_SIGNALS /**< Number of Signal instances available */
#define   aMTM_ETHERSTEM_NUM_OUTPUT_SIGNALS  aMTM_STEM_NUM_OUTPUT_SIGNALS /**< Signal: Number of output signal instances available */
#define   aMTM_ETHERSTEM_NUM_INPUT_SIGNALS    aMTM_STEM_NUM_INPUT_SIGNALS /**< Signal: Number of input signal instances available */

#define aMTM_ETHERSTEM_NUM_STORES                    aMTM_STEM_NUM_STORES /**< Number of Store instances available */
#define   aMTM_ETHERSTEM_NUM_INTERNAL_SLOTS  aMTM_STEM_NUM_INTERNAL_SLOTS /**< Store: Number of internal slots instances available */
#define   aMTM_ETHERSTEM_NUM_RAM_SLOTS            aMTM_STEM_NUM_RAM_SLOTS /**< Store: Number of RAM slot instances available */
#define   aMTM_ETHERSTEM_NUM_SD_SLOTS              aMTM_STEM_NUM_SD_SLOTS /**< Store: Number of SD slot instances available */

#define aMTM_ETHERSTEM_NUM_TIMERS                    aMTM_STEM_NUM_TIMERS /**< Number of Timer instances available */
/** @} */

// MARK: - MTMEtherStem Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of an MTM-EtherStem
///         Allows a user to connect to and control an attached module
class aMTMEtherStem : public aMTMStemModule
{
public:

    aMTMEtherStem(const uint8_t module = aMTM_ETHERSTEM_MODULE_BASE_ADDRESS,
                  bool bAutoNetworking = true,
                  const uint8_t model = aMODULE_TYPE_MTM_EtherStem) :
    aMTMStemModule(module, bAutoNetworking, model)
    {

    }
};

#endif
