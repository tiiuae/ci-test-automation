/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aUSBStem.h                                                //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: Definition of the Acroname USBStem module object.  //
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

#ifndef __aUSBStem_H__
#define __aUSBStem_H__

#include "BrainStem-all.h"
#include "aProtocoldefs.h"

/**
 * \defgroup aUSBStem_Constants USBStem Module Constants
 * @{
 */

#define aUSBSTEM_MODULE                             a40PINSTEM_MODULE /**< USBStem module base address */

#define aUSBSTEM_NUM_A2D                           a40PINSTEM_NUM_A2D /**< Number of Analog instances available */
#define aUSBSTEM_NUM_APPS                         a40PINSTEM_NUM_APPS /**< Number of App instances available */

#define aUSBSTEM_BULK_CAPTURE_MAX_HZ   a40PINSTEM_BULK_CAPTURE_MAX_HZ /**< Bulk Capture Max Hertz */
#define aUSBSTEM_BULK_CAPTURE_MIN_HZ   a40PINSTEM_BULK_CAPTURE_MIN_HZ /**< Bulk Capture Min Hertz */

#define aUSBSTEM_NUM_CLOCK                       a40PINSTEM_NUM_CLOCK /**< Number of Clock instances available */
#define aUSBSTEM_NUM_DIG                           a40PINSTEM_NUM_DIG /**< Number of Digital instances available */
#define aUSBSTEM_NUM_I2C                           a40PINSTEM_NUM_I2C /**< Number of I2C instances available */
#define aUSBSTEM_NUM_POINTERS                 a40PINSTEM_NUM_POINTERS /**< Number of Pointer instances available */
#define aUSBSTEM_NUM_SERVOS                     a40PINSTEM_NUM_SERVOS /**< Number of RC Servo instances available */

#define aUSBSTEM_NUM_STORES                     a40PINSTEM_NUM_STORES /**< Number of Store instances available */
#define   aUSBSTEM_NUM_INTERNAL_SLOTS   a40PINSTEM_NUM_INTERNAL_SLOTS /**< Store: Number of internal slots instances available */
#define   aUSBSTEM_NUM_RAM_SLOTS             a40PINSTEM_NUM_RAM_SLOTS /**< Store: Number of RAM slot instances available */
#define   aUSBSTEM_NUM_SD_SLOTS               a40PINSTEM_NUM_SD_SLOTS /**< Store: Number of SD slot instances available */

#define aUSBSTEM_NUM_TIMERS                     a40PINSTEM_NUM_TIMERS /**< Number of Timer instances available */
/** @} */

// MARK: - USBStem Class
/////////////////////////////////////////////////////////////////////
///  \brief Concrete Module implementation of a USBStem
///         Allows a user to connect to and control an attached module
class aUSBStem : public a40PinModule
{
public:

    aUSBStem(const uint8_t module = aUSBSTEM_MODULE,
             bool bAutoNetworking = true,
             const uint8_t model = aMODULE_TYPE_USBStem_1) :
    a40PinModule(module, bAutoNetworking, model)
    {
        
    }
};

#endif
