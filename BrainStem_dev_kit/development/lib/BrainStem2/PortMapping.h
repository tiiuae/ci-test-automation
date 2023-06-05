//
//  USBMapping.h
//
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright 1994-2015. Acroname Inc.                              //
//                                                                 //
// This software is the property of Acroname Inc.  Any             //
// distribution, sale, transmission, or re-use of this code is     //
// strictly forbidden except with permission from Acroname Inc.    //
//                                                                 //
// To the full extent allowed by law, Acroname Inc. also excludes  //
// for itself and its suppliers any liability, whether based in   //
// contract or tort (including negligence), for direct,            //
// incidental, consequential, indirect, special, or punitive       //
// damages of any kind, or for loss of revenue or profits, loss of //
// business, loss of information or data, or other financial loss  //
// arising out of or in connection with this software, even if     //
// Acroname Inc. has been advised of the possibility of such       //
// damages.                                                        //
//                                                                 //
// Acroname Inc.                                                   //
// www.acroname.com                                                //
// 720-564-0373                                                    //
//                                                                 //
/////////////////////////////////////////////////////////////////////

#ifndef _PortMapping_h_
#define _PortMapping_h_

#include "BrainStem-C.h"

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

    /** Port speed enumeration */
    typedef enum PORT_SPEED {
        kPORT_SPEED_UNKNOWN = 0,    /**< kPORT_SPEED_UNKNOWN (0)*/
        kPORT_SPEED_LOW,            /**< kPORT_SPEED_LOW (1)*/
        kPORT_SPEED_FULL,           /**< kPORT_SPEED_FULL (2)*/
        kPORT_SPEED_HIGH,           /**< kPORT_SPEED_HIGH (3)*/
        kPORT_SPEED_SUPER,          /**< kPORT_SPEED_SUPER (4)*/
        kPORT_SPEED_SUPER_PLUS,     /**< kPORT_SPEED_SUPER_PLUS (5)*/
    } PORT_SPEED_t;

    /** Device Node Structure - Contains information linking the downstream
     *  device to the Acroname Hub. */
    typedef struct DeviceNode {
        //Acroname Device Information
        uint32_t hubSerialNumber; /**< Serial number of the Acroname hub where the device was found.*/
        uint8_t hubPort;/**< Port of the Acroname hub where the device was found.*/
        
        //Downstream device information.
        uint16_t idVendor;/**< Manufactures Vendor ID of the downstream device.*/
        uint16_t idProduct;/**< Manufactures Product ID of the downstream device.*/
        PORT_SPEED_t speed;/**< The devices downstream device speed.*/
        char productName[255];/**< USB string descriptor*/
        char serialNumber[255];/**< USB string descriptor*/
        char manufacturer[255];/**< USB string descriptor*/
    } DeviceNode_t;

    /// Gets downstream device USB information for all Acroname hubs.
    /// \param deviceList Pointer to the start of a list/array to be used by the function.
    /// \param deviceListLength Size of the list/array in DeviceNode_t's, not bytes.)
    /// \param devicesFound The number of DeviceNode_t's that were populated.
    /// \return aErrNone on success
    ///       - aErrParam: Passed in values are not valid. (NULL, size etc).
    ///       - aErrMemory: No more room in the list
    ///       - aErrNotFound: No Acroname devices were found.
    aLIBEXPORT aErr getDownstreamDevices(
        DeviceNode_t*   deviceList,
        uint32_t        deviceListLength,
        uint32_t*       devicesFound);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif
