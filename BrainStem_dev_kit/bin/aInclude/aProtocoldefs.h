/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aProtocoldefs.h                                           //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: Defines used for Brainstem communications.         //
//                                                                 //
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

#ifndef _aProtocolDefs_H_
#define _aProtocolDefs_H_

#include "aError.h"

/////////////////////////////////////////////////////////////////////
/// BrainStem Protocol Definitions

/** \defgroup aProtocoldefs Protocol Defines
 * \ref aProtocoldefs "aProtocoldefs.h" Provides protocol and BrainStem
 * specific defines for entities, communication, and protocol specifics.
 */

/////////////////////////////////////////////////////////////////////
/// BrainStem model codes
#ifndef __aMODULE_DEF__
#define __aMODULE_DEF__

#define aMODULE_TYPE_USBStem_1                                      4
#define aMODULE_TYPE_EtherStem_1                                    5
#define aMODULE_TYPE_MTMIOSerial_1                                 13
#define aMODULE_TYPE_MTM_PM_1                                      14
#define aMODULE_TYPE_MTM_EtherStem                                 15
#define aMODULE_TYPE_MTM_USBStem                                   16
#define aMODULE_TYPE_USBHub2x4                                     17
#define aMODULE_TYPE_MTM_Relay                                     18
#define aMODULE_TYPE_USBHub3p                                      19
#define aMODULE_TYPE_MTM_DAQ_1                                     20
#define aMODULE_TYPE_USBC_Switch                                   21
#define aMODULE_TYPE_MTM_DAQ_2                                     22
#define aMODULE_TYPE_MTM_LOAD_1                                    23
#define aMODULE_TYPE_USBHub3c                                      24

#endif // __aMODULE_DEF__



/////////////////////////////////////////////////////////////////////
/// **8 Bytes** - Packet protocol payload maximum.
#define aBRAINSTEM_MAXPACKETBYTES                                  28

/////////////////////////////////////////////////////////////////////
/// UEI and Command support for C/C++ and Reflex languages.

/** \defgroup UEI_Defines (UEI Specific Defines)
 *
 * @{
 */

/// **0x1F** - Mask bits for Index on index byte.
#define ueiSPECIFIER_INDEX_MASK                                  0x1F
/// **0xE0** -  Mask bits for Return value on index byte.
#define ueiSPECIFIER_RETURN_MASK                                 0xE0
/// **1 << 5** - Specifier Bit for UEI response to host.
#define ueiSPECIFIER_RETURN_HOST                                 0x20
/// **2 << 5** - Specifier Bit for UEI response to Module over I2C.
#define ueiSPECIFIER_RETURN_I2C                                  0x40
/// **3 << 5** - Specifier Bit for UEI response to VM on module.
#define ueiSPECIFIER_RETURN_VM                                   0x60
/// **1 << 7** - Error flag on response in index byte.
#define ueiREPLY_ERROR                                           0x80
/// **1 << 6** - Stream flag on response in index byte.
#define ueiREPLY_STREAM                                          0x40

/// **0x40** - Option byte code for UEI Get request.
#define ueiOPTION_GET                                            0x40
/// **0x00** - Option byte code for UEI Val response.
#define ueiOPTION_VAL                                            0x00
/// **0x80** - Option byte code for UEI Set request.
#define ueiOPTION_SET                                            0x80
/// **0xC0** - Option byte code for UEI Ack response.
#define ueiOPTION_ACK                                            0xC0
/// **0x3F** - Mask for getting command option from option byte.
#define ueiOPTION_MASK                                           0x3F
/// **0xC0** - Mask for getting Operation Get/Set/Val/Ack
#define ueiOPTION_OP_MASK                                        0xC0


#define ueiBYTES_CONTINUE                                        0x80
#define ueiBYTES_CONTINUE_MASK                                   0x7F
/** @} */



/////////////////////////////////////////////////////////////////////
// Command codes

/////////////////////////////////////////////////////////////////////
// Internal commands, not exposed at C/C++ API
#define cmdHB                                                       0
#define   val_HB_S2H_UP                                             0
#define   val_HB_S2H_DOWN                                           1
#define   val_HB_H2S_UP                                             2
#define   val_HB_H2S_DOWN                                           3
#define   val_HB_M2R_UP                                             4
#define   val_HB_M2R_DOWN                                           5
#define cmdROUTE                                                    1
#define cmdI2C_XMIT                                                 2
#define cmdMAGIC                                                 0xAD
#define cmdFORCEROUTE                                            0xAF

/////////////////////////////////////////////////////////////////////
// API Commands

/** \defgroup cmdSYSTEM_Defines System Command Defines
 * System entity defines
 *
 * @{
 */

/// **3** - System entity command code.
#define cmdSYSTEM                                                   3

/** \defgroup cmdSYSTEM_Command_Options System Command Options
 * \ingroup cmdSYSTEM_Defines
 *
 * @{
 */

/// **1** - Module address option code.
#define    systemModule                                             1
/// **2** - Router address option code.
#define    systemRouter                                             2
/// **3** - Heartbeat interval option code.
#define    systemHBInterval                                         3
/// **4** - User LED option code.
#define    systemLED                                                4
/// **5** - Sleep option code.
#define    systemSleep                                              5
/// **6** - Boot Slot option code.
#define    systemBootSlot                                           6
/// **255** - Disable boot slot value for Boot Slot option.
#define       aSystemBootSlotNone                                 255
/// **7** - Firmware Version option code.
#define    systemVersion                                            7
/// **8** - Model option code.
#define    systemModel                                              8
/// **9** - Serial Number option code.
#define    systemSerialNumber                                       9
/// **10** - System save option code.
#define    systemSave                                              10
/// **11** - System reset option code.
#define    systemReset                                             11
/// **12** - Input voltage option code.
#define    systemInputVoltage                                      12
/// **13** - Module Offset option code.
#define    systemModuleHardwareOffset                              13
/// **14** - Module Base address option code.
#define    systemModuleBaseAddress                                 14
/// **15** - Module Software offset option code.
#define    systemModuleSoftwareOffset                              15
/// **16** - Router address setting option code.
#define    systemRouterAddressSetting                              16
/// **17** - IP configuration setting option code
#define    systemIPConfiguration                                   17
#define        systemIPModeDHCP                                     0
#define        systemIPModeStatic                                   1
#define        systemIPModeDefault                                  0
/// **18** - IP address setting option code
#define    systemIPAddress                                         18
/// **19** - Static IP address setting option code
#define    systemIPStaticAddressSetting                            19
/// **20** - Route to me setting option code
#define    systemRouteToMe                                         20
/// **21** - Input current option code.
#define    systemInputCurrent                                      21
/// **22** - System uptime option code.
#define    systemUptime                                            22
/// **23** - System max temperature option code.
#define    systemMaxTemperature                                    23
/// **24** - System log events option code.
#define    systemLogEvents                                         24
/// **25** - Unregulated System Voltage option code.
#define    systemUnregulatedVoltage                                25
/// **26** - Unregulated System Current option code.
#define    systemUnregulatedCurrent                                26
/// **27** - System temperature option code
#define    systemTemperature                                       27
/// **28** - System min temperature option code
#define    systemMinTemperature                                    28
/// **29** - System input power source option code
#define    systemInputPowerSource                                  29
/// **30** - System input power behavior option code
#define    systemInputPowerBehavior                                31
/// **31** - System input power behavior config option code
#define    systemInputPowerBehaviorConfig                          31
/// **32** - System name option code
#define    systemName                                              32
/// **33** - System power limit option code
#define    systemPowerLimit                                        33
/// **34** - System power limit max option code
#define    systemPowerLimitMax                                     34
/// **35** - System power limit state option code
#define    systemPowerLimitState                                   35
/// **36** -
#define    systemResetEntityToFactoryDefaults                      36
/// **37** -
#define    systemResetDeviceToFactoryDefaults                      37
/// **38** - Setting the link interface for control
#define    systemLinkInterface                                     38
/// **0** System Link is automatically defined
#define         systemLinkAuto                                      0
/// **1** System Link through control port
#define         systemLinkUSBControl                                1
/// **2** System Link through the Hub (upstream connection)
#define         systemLinkUSBHub                                    2
/// **39** - Reserved Option Code for Acroname Internal Use Only
#define    systemReserved                                          39
/// **40** - Hardware Version option code
#define    systemHardwareVersion                                   40
/// **41** - System Error option code
#define    systemErrors                                            41
/// **0** - Thermal Protection bit for operational Errors option code.
#define       systemErrors_ThermalProtection_Bit                    0
/// **1** - Output Power Protection bit for operational Errors option code.
#define       systemErrors_OutputPowerProtection_Bit                1

//TODO: Back down once entity is settled.
/// **45** - Number of Options for System, always last entry
#define    systemNumberOfOptions                                   45


/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////


/** \defgroup cmdSLOT_Defines Slot Command Defines
 *  System entity defines
 *
 * @{
 */

/// **4** - Slot Command Code.
#define cmdSLOT                                                     4

/** \defgroup cmdSLOT_Command_Options Slot Command Options
 * \ingroup cmdSLOT_Defines
 *
 * @{
 */

/// **1** - Slot Capacity option code.
#define    slotCapacity                                             1
/// **2** - Slot size option code
#define    slotSize                                                 2
/// **3** - Slot Open Read option code.
#define    slotOpenRead                                             3
/// **4** - Slot Open Write option code.
#define    slotOpenWrite                                            4
/// **5** - Slot Seek option code.
#define    slotSeek                                                 5
/// **6** - Slot Read option code.
#define    slotRead                                                 6
/// **7** - Slot Write option code.
#define    slotWrite                                                7
/// **8** - Slot Close option code.
#define    slotClose                                                8
/// **0x80** - Bit Slot error code.
#define    bitSlotError                                          0x80

/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////
// Allows users to create custom behavior via reflex code.

/** \defgroup cmdAPP_Defines App Command Defines
 * App Entity defines
 *
 * @{
 */

/// **5** - App command code.
#define cmdAPP                                                      5

/** \defgroup cmdAPP_Command_Options App Command Options
 * \ingroup cmdAPP_Defines
 *
 * @{
 */
/// **1** - Execute option code.
#define    appExecute                                               1
/// **2** - Return option code.
#define    appReturn                                                2
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdMUX_Defines Mux Command Defines
 * Mux Entity defines
 *
 * @{
 */

/// **6** - Mux command code.
#define cmdMUX                                                      6

/** \defgroup cmdMUX_Command_Options Mux Command Options
 * \ingroup cmdMUX_Defines
 *
 * @{
 */

/// **1** - Channel enable option code.
#define    muxEnable                                                1
/// **2** - Select the active channel on the mux.
#define    muxChannel                                               2
/// **3** - Get voltage measurement for the channel.
#define    muxVoltage                                               3
/// **4** - Get voltage measurement for the channel.
#define    muxConfig                                                4
#define       muxConfig_default                                     0
#define       muxConfig_splitMode                                   1
#define       muxConfig_channelpriority                             2
/// **5** - Get voltage measurement for the channel.
#define    muxSplit                                                 5
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdPOINTER_Defines Pointer command defines
 * Pointer entity defines.
 *
 * @{
 */

/// **7** -  Pointer command code.
#define cmdPOINTER                                                  7

/** \defgroup cmdPOINTER_Command_Options Pointer command options
 * \ingroup cmdPOINTER_Defines
 *
 * @{
 */

/// **1** - Pointer offset option code.
#define    pointerOffset                                            1
/// **2** - Pointer mode option code.
#define    pointerMode                                              2
/// **0** - Static pointer mode for pointer mode option code.
#define       pointerModeStatic                                     0
/// **1** - Increment pointer mode for pointer mode option code.
#define       pointerModeIncrement                                  1
/// **pointerModeStatic** - Default pointer mode for pointer mode option code.
#define       DefaultPointerMode                                    0
/// **3** - Set Transfer store option code.
#define    pointerTransferStore                                     3
/// **4** - Char pointer option code.
#define    pointerChar                                              4
/// **5** - Short pointer option code.
#define    pointerShort                                             5
/// **6** - Int pointer option code.
#define    pointerInt                                               6
/// **7** - Transfer to Store option code.
#define    pointerTransferToStore                                   7
/// **8** - Transfer From store option code.
#define    pointerTransferFromStore                                 8

/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/// Write and read devices on I2C bus.
#define cmdI2C                                                      8
/// Set pullup enable and disable on stems which support software control
#define    i2cSetPullup                                             1
/// Route-to address (Reserved for internal use)
#define cmdRTA                                                      9

/// Possible speed settings for I2C bus.
#define     i2cDefaultSpeed                                         0
#define     i2cSpeed_100Khz                                         1
#define     i2cSpeed_400Khz                                         2
#define     i2cSpeed_1000Khz                                        3



/////////////////////////////////////////////////////////////////////
/** \defgroup cmdSERVO_Defines RCServo command defines
 * RCServo entity defines.
 *
 * @{
 */

/// **13** - RC Servo command code.
#define cmdSERVO                                                   13

/** \defgroup cmdSERVO_Command_Options RCServo command options
 * \ingroup cmdSERVO_Defines
 *
 * @{
 */
/// **1** - RCServo enable/disable option code.
#define    servoEnable                                              1
/// **2** - RCServo position option code.
#define    servoPosition                                            2
/// **3** - RCServo reverse option code.
#define    servoReverse                                             3

/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdSIGNAL Signal command defines
 * Signal entity defines.
 *
 * @{
 */

/// **14** - cmdSIGNAL command code.
#define cmdSIGNAL                                                  14

/** \defgroup cmdSIGNAL_Command_Options Digital signal command options
 * \ingroup cmdSIGNAL_Defines
 *
 * @{
 */
/// **1** - Signal enable/disable option code.
#define    signalEnable                                              1
/// **2** - Signal get/set inversion of duty cycle
#define    signalInvert                                              2
/// **3** - Signal get/set period in nanoseconds.
#define    signalT3Time                                              3
/// **4** - Signal get/set active time in nanoseconds (See reference).
#define    signalT2Time                                              4

/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdEQUALIZER Equalizer command defines
 * Equalizer entity defines.
 *
 * @{
 */

/// **14** - cmdSIGNAL command code.
#define cmdEQUALIZER                                             15

/** \defgroup cmdEQUALIZER_Command_Options Equalizer signal command options
 * \ingroup cmdEQUALIZER_Defines
 *
 * @{
 */
/// **1** - Equalizer receiver config
#define    equalizerReceiverConfig                                1
/// **2** - Equalizer driver config
#define    equalizerTransmitterConfig                             2
/// **3** - Equalizer manual configuration
#define    equalizerManualConfig                                  3

/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////
/// **0** - Equalizer for USB 2.0
#define    equalizer2p0                                           0
/// **1** - Equalizer for USB 3.0
#define    equalizer3p0                                           1

/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////

/// Debug command
#define cmdDEBUG                                                   23

/// app NOTIFY currently resverve for future use.
#define cmdNOTIFY                                                  24

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdANALOG_Defines Analog Command defines
 * Analog Entity defines.
 *
 * @{
 */

/// **30** - Analog command code.
#define cmdANALOG                                                  30

/** \defgroup cmdANALOG_Command_Options Analog Command options
 * \ingroup cmdANALOG_Defines
 *
 * @{
 */

/// **1** - Analog configuration option code.
#define    analogConfiguration                                      1
/// **0** - Input configuration for configuration option code.
#define      analogConfigurationInput                               0
/// **1** - Output configuration for configuration option code.
#define      analogConfigurationOutput                              1
/// **2** - HiZ configuration for configuration option code.
#define      analogConfigurationHiZ                                 2
/// **2** - Analog Value option code.
#define    analogValue                                              2
/// **3** - Analog Voltage option code.
#define    analogVoltage                                            3
/// **4** - Analog Bulk Capture Sample Rate option code.
#define    analogBulkCaptureSampleRate                              4
/// **7000** - minimum hertz sample rate for Bulk capture Sample Rate option code.
#define    analog_Hz_Minimum                                     7000
/// **200000** - maximum hertz sample rate for Bulk capture Sample Rate option code.
#define    analog_Hz_Maximum                                   200000
/// **5** - Bulk Capture number of samples option code.
#define    analogBulkCaptureNumberOfSamples                         5
/// **6** - Bulk Capture option code.
#define    analogBulkCapture                                        6
/// **7** - Bulk Capture State option code.
#define    analogBulkCaptureState                                   7
/// **0** - Idle state for Bulk Capture state option code.
#define      bulkCaptureIdle                                        0
/// **1** - Pending state for Bulk Capture state option code.
#define      bulkCapturePending                                     1
/// **2** - Finished state for Bulk Capture state option code.
#define      bulkCaptureFinished                                    2
/// **3** - Error state for Bulk Capture state option code.
#define      bulkCaptureError                                       3
/// **8** - Analog Range option code.
#define    analogRange                                              8
/// **0** - +/- 64mV range for Analog Range option code.
#define      analogRange_P0V064N0V064                               0
/// **1** - +/- 640mV range for Analog Range option code.
#define      analogRange_P0V64N0V64                                 1
/// **2** - +/- 128mV range for Analog Range option code.
#define      analogRange_P0V128N0V128                               2
/// **3** - +/- 1.28V range for Analog Range option code.
#define      analogRange_P1V28N1V28                                 3
/// **4** - 0-1.28V range for Analog Range option code.
#define      analogRange_P1V28N0V0                                  4
/// **5** - +/- 256mV range for Analog Range option code.
#define      analogRange_P0V256N0V256                               5
/// **6** - +/- 2.56V range for Analog Range option code.
#define      analogRange_P2V56N2V56                                 6
/// **7** - 0-2.56V range for Analog Range option code.
#define      analogRange_P2V56N0V0                                  7
/// **8** - +/- 512mV range for Analog Range option code.
#define      analogRange_P0V512N0V512                               8
/// **9** - +/- 5.12V range for Analog Range option code.
#define      analogRange_P5V12N5V12                                 9
/// **10** - 0-5.12V range for Analog Range option code.
#define      analogRange_P5V12N0V0                                 10
/// **11** - +/- 1.024V range for Analog Range option code.
#define      analogRange_P1V024N1V024                              11
/// **12** - +/- 10.24V range for Analog Range option code.
#define      analogRange_P10V24N10V24                              12
/// **13** - 0-10.24V range for Analog Range option code.
#define      analogRange_P10V24N0V0                                13
/// **14** - 0-2.048V range for Analog Range option code.
#define      analogRange_P2V048N0V0                                14
/// **15** - 0-4.096V range for Analog Range option code.
#define      analogRange_P4V096N0V0                                15
/// **9** - Analog Enable option code.
#define    analogEnable                                             9
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdDIGITAL_Defines Digital command defines
 * Digital entity defines.
 *
 * @{
 */

/// **31** - Digital command code.
#define cmdDIGITAL                                                 31

/** \defgroup cmdDIGITAL_Command_Options Digital command options
 * \ingroup cmdDIGITAL_Defines
 *
 * @{
 */
/// **1** - Digital configuration option code.
#define    digitalConfiguration                                     1
/// **0** - Input Digital configuration for configuration option code.
#define        digitalConfigurationInput                         0x00
/// **1** - Output Digital configuration for configuration option code.
#define        digitalConfigurationOutput                        0x01
/// **2** - RC Servo Input Digital configuration for configuration option code.
#define        digitalConfigurationRCServoInput                  0x02
/// **3** - RC Servo Output Digital configuration for configuration option code.
#define        digitalConfigurationRCServoOutput                 0x03
/// **4** - Hi Z the digital pin.
#define        digitalConfigurationHiZ                           0x04
/// **0** - Input digital configuration with pull-up.
#define        digitalConfigurationInputPullUp                   0x00
/// **4** - Input digital configuration with no pull-up/pull-down.
#define        digitalConfigurationInputNoPull                   0x04
/// **5** - Input digital configuration with pull-down.
#define        digitalConfigurationInputPullDown                 0x05
/// **6** - Signal output configuration
#define        digitalConfigurationSignalOutput                  0x06
/// **7** - Signal input configuration
#define        digitalConfigurationSignalInput                   0x07
/// **8** - Signal input conter configuration
#define        digitalConfigurationSignalCounterInput            0x08
/// **9** - State option code.
#define    digitalState                                             2
#define    digitalStateAll                                          3
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////


/** \defgroup cmdRAIL_Defines Rail command defines
 * Rail entity defines.
 *
 * @{
 */

/// **32** - Rail command code.
#define cmdRAIL                                                    32

/** \defgroup cmdRAIL_Command_Options Rail command options
 * \ingroup cmdRAIL_Defines
 *
 * @{
 */

/// **1** - Rail Voltage option code.
#define    railVoltage                                                      1
/// **2** - Rail Current option code.
#define    railCurrent                                                      2
/// **3** - Rail Current limit option code.
#define    railCurrentLimit                                                 3
/// **4** - Rail Temperature option code.
#define    railTemperature                                                  4
/// **5** - Rail Enable option code.
#define    railEnable                                                       5
/// **6** - Rail Value option code.
#define    railValue                                                        6
/// **7** - Rail Kelvin sensing Mode option code.
#define    railKelvinSensingEnable                                          7
/// **0** - Kelvin Sensing off mode for Kelvin Sensing mode option code.
#define       kelvinSensingOff_Value                                        0
/// **1** - Kelvin Sensing on mode for Kelvin Sensing mode option code.
#define       kelvinSensingOn_Value                                         1
/// **8** - Kelving Sensing state option code.
#define    railKelvinSensingState                                           8
/// **9** - Operational mode option code.
/// railOperationalMode is a bit masked field with two multi bit fields.
#define    railOperationalMode                                              9
/// **0-3** - Operational Mode hardware configuration offset region (bits[0:3]).
#define       railOperationalMode_HardwareConfiguration_Offset              0
/// **0** - Auto operational mode for operational mode option code.
#define         railOperationalModeAuto_Value                               0
/// **1** - Linear mode for operational mode option code.
#define         railOperationalModeLinear_Value                             1
/// **2** - Switcher mode for operational mode option code.
#define         railOperationalModeSwitcher_Value                           2
/// **3** - Switcher Linear mode for operational mode option code.
#define         railOperationalModeSwitcherLinear_Value                     3
/// **4-7** - Operational Mode offset region (bits[4:7]).
#define       railOperationalMode_Mode_Offset                               4
/// **0** - Constant Current mode for operational mode option code.
#define         railOperationalModeConstantCurrent_Value                    0
/// **1** - Constant Voltage mode for operational mode option code.
#define         railOperationalModeConstantVoltage_Value                    1
/// **2** - Constant Power mode for operational mode option code.
#define         railOperationalModeConstantPower_Value                      2
/// **3** - Constant Resistance mode for operational mode option code.
#define         railOperationalModeConstantResistance_Value                 3
/// **15** - Factory Reserved Operating Mode.
#define         railOperationalModeFactoryReserved_Value                    0xF
/// **0** - Default operational mode for operational mode option code.
#define       DefaultOperationalRailMode_Value                              0
/// **10** - Operational state option code.
/// The railOperationalState is a bit masked field that has single bit
/// and multi-bit entries.
#define    railOperationalState                                             10
/// **0** - Initializing bit for operational state option code.
#define       railOperationalState_Initializing_Bit                         0
/// **1** - Enabled bit for operational state option code.
#define       railOperationalState_Enabled_Bit                              1
/// **2** - Fault bit for operational state option code.
#define       railOperationalState_Fault_Bit                                2
/// **3-7** These bits are unused
/// **8** - Hardware Configuration region (bits[8-15]) for operational state.
#define       railOperationalState_HardwareConfiguration_Offset             8
/// **0** - Linear state for operational state option mode.
#define         railOperationalStateLinear_Value                            0
/// **1** - Switcher state for operational state option mode.
#define         railOperationalStateSwitcher_Value                          1
/// **2** - Switcher Linear state for operational state option mode.
#define         railOperationalStateSwitcherLinear_Value                    2
/// **16** - Over Voltage Fault bit for operational state option mode.
#define       railOperationalStateOverVoltageFault_Bit                      16
/// **17** - Under Voltage Fault bit for operational state option mode.
#define       railOperationalStateUnderVoltageFault_Bit                     17
/// **18** - Over Current Fault bit for operational state option mode.
#define       railOperationalStateOverCurrentFault_Bit                      18
/// **19** - Over Power Fault bit for operational state option mode.
#define       railOperationalStateOverPowerFault_Bit                        19
/// **20** - Reverse Polarity Fault bit for operational state option mode.
#define       railOperationalStateReversePolarityFault_Bit                  20
/// **21** - Over Temperature Fault bit for operational state option mode.
#define       railOperationalStateOverTemperatureFault_Bit                  21
/// **22** - Reverse Current Fault bit for operational state option mode.
#define       railOperationalStateReverseCurrentFault_Bit                   22
/// **23** - This bit is Unused
/// **24-31** - Operating Mode region (bits[24:31]) for operational state.
#define       railOperationalStateOperatingMode_Offset                      24
/// **0** - Constant Current mode for operational state option code.
#define         railOperationalStateConstantCurrent_Value                   0
/// **1** - Constant Voltage mode for operational state option code.
#define         railOperationalStateConstantVoltage_Value                   1
/// **2** - Constant Power mode for operational state option codes.
#define         railOperationalStateConstantPower_Value                     2
/// **3** - Constant Resistance mode for operational state option code.
#define         railOperationalStateConstantResistance_Value                3
/// **11** - Rail Setpoint Voltage option code
#define    railVoltageSetpoint                                              11
/// **12** - Rail Setpoint Current option code.
#define    railCurrentSetpoint                                              12
/// **13** - Rail Voltage min limit option code.
#define    railVoltageMinLimit                                              13
/// **14** - Rail Voltage max limit option code.
#define    railVoltageMaxLimit                                              14
/// **15** - Rail power option code.
#define    railPower                                                        15
/// **16** - Rail Setpoint power option code.
#define    railPowerSetpoint                                                16
/// **17** - Rail power limit option code.
#define    railPowerLimit                                                   17
/// **18** - Rail resistance option code.
#define    railResistance                                                   18
/// **19** - Rail Setpoint resistance option code.
#define    railResistanceSetpoint                                           19
/// **20** - Rail Clear Fault Codes.
#define    railClearFaults                                                  20
/// **63** - Factory Reserved Code.
#define    railFactoryReserved                                              62
/// **63** - Factory Reserved Code.
#define    railFactoryReserved2                                             63
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdTEMPERATURE_Defines Temperature command defines
 * Temperature entity defines.
 *
 * @{
 */

/// **33** - Temperature command code.
#define cmdTEMPERATURE                                             33

/** \defgroup cmdTEMPERATURE_Command_Options Temperature command options
 * \ingroup cmdTEMPERATURE_Defines
 *
 * @{
 */

/// **1** - Temperature option code.
#define    temperatureMicroCelsius                                  1
/// **2** - Min temperature option code.
#define    temperatureMinimumMicroCelsius                           2
/// **3** - Max temperature option code.
#define    temperatureMaximumMicroCelsius                           3
/// **4** Reset temperature entity option code
#define    temperatureResetEntityToFactoryDefaults                  4
/// **2** - Number of Options for temperature, always last entry
#define    temperatureNumberOfOptions                               5

/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////
/** \defgroup cmdRELAY_Defines Relay command defines
 * Relay entity defines.
 *
 * @{
 */

/// **34** - Relay command code.
#define cmdRELAY                                                    34

/** \defgroup cmdRELAY_Command_Options Relay command options
 * \ingroup cmdRELAY_Defines
 *
 * @{
 */
/// **1** - Relay State option code.
#define    relayEnable                                               1
/// **2** - Relay Voltage option code.
#define    relayVoltage                                              2
/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdUART_Defines UART command defines
 * UART entity defines.
 *
 * @{
 */
/// **35** - UART command code.
#define cmdUART                                                     35

/** \defgroup cmdUART_Command_Options UART command options
 * \ingroup cmdUART_Defines
 *
 * @{
 */

/// **1** - UART Channel Enable code
#define     uartEnable                                              1
/// **2** - UART Channel BaudRate code
#define     uartBaudRate                                            2
/// **3** - UART Channel Serial Protocol
#define     uartProtocol                                            3
/// **0** - UART Protocol - Format: Undefined
#define         uartProtocol_Undefined                              0
/// **1** - UART Protocol - Format: ExtronCompatible
#define         uartProtocol_Extron_Value                           1
/// **4** - Number of Options for uart, always last entry
#define    uartNumberOfOptions                                      4

/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdPOWERDELIVERY_Defines Power Delivery command defines
 * Power Delivery entity defines.
 *
 * @{
 */
/// **35** - Power Delivery command code.
#define cmdPOWERDELIVERY                                            36

/** \defgroup cmdPOWERDELIVERY_Command_Options Power Delivery command options
 * \ingroup cmdPOWERDELIVERY_Defines
 *
 * @{
 */

#define     powerdeliveryPartnerLocal                                   0
#define     powerdeliveryPartnerRemote                                  1

#define     powerdeliveryPowerRoleDisabled                              0
#define     powerdeliveryPowerRoleSource                                1
#define     powerdeliveryPowerRoleSink                                  2
#define     powerdeliveryPowerRoleSourceSink                            3

//TODO: Fix numbering
/// **1** - TODO  Channel Enable code
#define     powerdeliveryPowerDataObject                                1
#define     powerdeliveryPowerDataObjectList                            2
#define     powerdeliveryPowerDataObjectEnabled                         3
#define     powerdeliveryPowerDataObjectEnabledList                     4
#define     powerdeliveryNumberOfPowerDataObjects                       5
#define     powerdeliveryRequestDataObject                              6
#define     powerdeliveryConnectionState                                7
#define       pdConnectionState_None                                    0
#define       pdConnectionState_Source                                  1
#define       pdConnectionState_Sink                                    2
#define       pdConnectionState_PoweredCable                            3
#define       pdConnectionState_PoweredCableWithSink                    4
#define     powerdeliveryPartnerPowerRule                               8
#define     powerdeliveryPartnerSourcePowerRuleIndex                    9
#define     powerdeliveryCableVDM                                       10
#define     powerdeliveryAnalogCCValue                                  11
#define     powerdeliveryMaxPortCurrent                                 12
#define     powerdeliveryCurrentLimitBehavior                           13
#define     powerdeliveryCurrentLimitLatch                              14
#define     powerdeliveryResetPowerDataObjectToDefault                  15
#define     powerdeliveryCableVoltageMax                                16
#define       pdCableVoltage_Invalid                                     0
#define       pdCableVoltage_20VDC                                       1
#define       pdCableVoltage_30VDC                                       2
#define       pdCableVoltage_40VDC                                       3
#define       pdCableVoltage_50VDC                                       4
#define     powerdeliveryCableCurrentMax                                17
#define       pdCableCurrent_Invalid                                     0
#define       pdCableCurrent_3Amps                                       1
#define       pdCableCurrent_5Amps                                       2
#define     powerdeliveryCableSpeedMax                                  18
#define       pdCableSpeed_Invalid                                       0
#define       pdCableSpeed_USB2p0                                        1
#define       pdCableSpeed_USB3p2_Gen1                                   2
#define       pdCableSpeed_USB3p2_USB4p0_Gen2                            3
#define       pdCableSpeed_USB4p0_Gen3                                   4
#define     powerdeliveryCableType                                      19
#define       pdCableType_Invalid                                        0
#define       pdCableType_Passive                                        1
#define       pdCableType_Active                                         2
#define     powerdeliveryCableOrientation                               20
#define       pdCableOrientation_Invalid                                 0
#define       pdCableOrientation_CC1                                     1
#define       pdCableOrientation_CC2                                     2
#define     powerdeliveryMaxPortPower                                   21
#define     powerdeliveryPowerRole                                      22
#define       pdPowerRole_None                                           0
#define       pdPowerRole_Source                                         1
#define       pdPowerRole_Sink                                           2
#define       pdPowerRole_SourceSink                                     3
#define     powerdeliveryPowerRolePreferred                             23
#define       pdPowerRolePreferred_None                                  0
#define       pdPowerRolePreferred_Source                                1
#define       pdPowerRolePreferred_Sink                                  2
#define       pdPowerRolePreferred_FollowData                            3
#define       pdPowerRolePreferred_Auto                                  4
#define     powerdeliveryPeakCurrentConfiguration                       24
#define     powerdeliveryFastRoleSwapCurrent                            25
#define     powerdeliveryAnalogCCEnabled                                26
#define     powerdeliverySendAlert                                      27
#define     powerdeliveryAuthenticationEnable                           28
#define     powerdeliveryMessageCaptureEnable                           29
#define     powerdeliveryMessageCaptureSlot                             30
#define     powerdeliveryManufacturerVIDPID                             31
#define     powerdeliveryBatteryVIDPID                                  32
#define     powerdeliveryBatteryStatus                                  33
#define     powerdeliveryBatteryCapacity                                34
#define     powerdeliveryBatteryCapabilities                            35
#define     powerdeliveryAlert                                          36
#define     powerdeliveryCountryInfo                                    37
#define     powerdeliveryStatus                                         38
#define     powerdeliveryManufacturerString                             39
#define     powerdeliveryPPSStatus                                      40
#define     powerdeliveryOverride                                       41

#define     powerdeliveryRequestCommand                                 42
#define         pdRequestHardReset                                      0
#define         pdRequestSoftReset                                      1
#define         pdRequestDataReset                                      2
#define         pdRequestPowerRoleSwap                                  3
#define         pdRequestPowerFastRoleSwap                              4
#define         pdRequestDataRoleSwap                                   5
#define         pdRequestVconnSwap                                      6
#define         pdRequestSinkGoToMinimum                                7
#define         pdRequestRemoteSourcePowerDataObjects                   8
#define         pdRequestRemoteSinkPowerDataObjects                     9
#define     powerDeliveryRequestStatus                                  43

#define     powerdeliveryFlagMode                                       44
#define         pdFlagDualRoleData                                      1
#define         pdFlagDualRolePower                                     2
#define         pdFlagUnconstrainedPower                                3
#define         pdFlagSuspendPossible                                   4
#define         pdFlagUSBComPossible                                    5
#define         pdFlagUnchunkedMessageSupport                           6
#define         pdFlagHigherCapability                                  7
#define         pdFlagCapabilityMismatch                                8
#define         pdFlagGivebackFlag                                      9
#define         pdFlagLast                                              10

#define     powerdeliveryLogEnable                                      45
#define     powerdeliveryLogPacket                                      46

#define     powerdeliveryResetEntityToFactoryDefaults                   54
#define     powerdeliveryNumberOfOptions                                55
/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdPORT_Defines Port command defines
 * Port entity defines.
 *
 * @{
 */
/// **35** - Port command code.
#define cmdPORT                                                     37

/** \defgroup cmdPORT_Command_Options Port command options
 * \ingroup cmdPORT_Defines
 *
 * @{
 */

/// **1** - Vbus Voltage option code
#define     portVbusVoltage                                         1
/// **2** - Vbus Current option code
#define     portVbusCurrent                                         2
/// **3** - Vconn Voltage option code
#define     portVconnVoltage                                        3
/// **4** - Vconn Current option code
#define     portVconnCurrent                                        4
/// **5** - Port Enabled option code
#define     portPortEnabled                                         5
/// **6** - Port Power Enabled option code
#define     portPowerEnabled                                        6
/// **7** - Port Data Enabled option code
#define     portDataEnabled                                         7
/// **8** - Port HS Data Enabled option code
#define     portDataHSEnabled                                       8
/// **9** - Port HS1 Data Enabled option code
#define     portDataHS1Enabled                                      9
/// **10** - Port HS2 Data Enabled option code
#define     portDataHS2Enabled                                     10
/// **11** - Port SS Data Enabled option code
#define     portDataSSEnabled                                      11
/// **12** - Port SS1 Data Enabled option code
#define     portDataSS1Enabled                                     12
/// **13** - Port SS2 Data Enabled option code
#define     portDataSS2Enabled                                     13
/// **14** - CC Enabled option code
#define     portCCEnabled                                          14
/// **15** - CC1 Enabled option code
#define     portCC1Enabled                                         15
/// **16** - CC2 Enabled option code
#define     portCC2Enabled                                         16
/// **17** - Vconn Enabled option code
#define     portVconnEnabled                                       17
/// **18** - Vconn1 Enabled option code
#define     portVconn1Enabled                                      18
/// **19** - Vconn2 Enabled option code
#define     portVconn2Enabled                                      19
/// **20** - Port State option code
#define    portPortState                                           20
/// **21** - Port Errors option code
#define    portErrors                                              21
/// **22** - Port Current Limit option code.
#define    portCurrentLimit                                        22
/// **23** - Port Current Limit Mode option code.
#define    portCurrentLimitMode                                    23
/// **24** - Port Power Limit option code.
#define    portPowerLimit                                          24
/// **25** - Port Power Limit Mode option code.
#define    portPowerLimitMode                                      25
/// **26** - Port available power option code
#define    portAvailablePower                                      26
/// **27** - Port Name option code
#define    portName                                                27
/// **28** - Port CC Bias option code
#define    portCCBias                                              28
#define       portCCBias_InvalidCurrent                             0
#define       portCCBias_DefaultCurrent                             1
#define       portCCBias_1p5Current                                 2
#define       portCCBias_3p0Current                                 3
/// **30** - Port Power mode option code
#define     portPowerMode                                          30
/// **0** - Port Power Mode - Mode: None/Disabled
#define         portPowerMode_none_Value                            0
/// **1** - Port Power Mode - Mode: Standard Downstream Port (SDP)
#define         portPowerMode_sdp_Value                             1
/// **2** - Port Power Mode - Mode: Charging Downstream Port (CDP) or Dedicated Charging Port (DCP)
#define         portPowerMode_cdp_dcp_Value                         2
/// **4** - Port Power Mode - Mode: Qualcom Quick Charge (QC)
#define         portPowerMode_qc_Value                              3
/// **5** - Port Power Mode - Mode: Power Delivery (PD)
#define         portPowerMode_pd_Value                              4
/// **5** - Port Power Mode - Mode: Power Supply Mode
#define         portPowerMode_ps_Value                              5
/// **31** - Port Data Role option code
#define     portDataRole                                           31
/// **0** - Port Data Role - Role: Disabled
#define         portDataRole_Disabled_Value                         0
/// **1** - Port Data Role - Role: Upstream Port
#define         portDataRole_Upstream_Value                         1
/// **2** - Port Data Role - Role:Downstream Port
#define         portDataRole_Downstream_Value                       2
/// **3** - Port Data Role - Role:Control Port
#define         portDataRole_Control_Value                          3

/// **32** - Port Data Speed option code
#define     portDataSpeed                                          32
/// **0** - Port Data Speed - Speed: Low Speed (1.5Mbps) bit indicator
#define         portDataSpeed_ls_1p5M_Bit                           0
/// **1** - Port Data Speed - Speed: Full Speed (12Mbps) bit indicator
#define         portDataSpeed_fs_12M_Bit                            1
/// **2** - Port Data Speed - Speed: High Speed (480Mbps) bit indicator
#define         portDataSpeed_hs_480M_Bit                           2
/// **3** - Port Data Speed - Speed: Super Speed (5Gbps) bit indicator
#define         portDataSpeed_ss_5G_Bit                             3
/// **4** - Port Data Speed - Speed: Super Speed Plus (10Gbps) bit indicator
#define         portDataSpeed_ss_10G_Bit                            4
/// **6** - Port Data Speed - USB 2.0 Connected
#define         portDataSpeed_Connected_2p0_Bit                     6
/// **7** - Port Data Speed - USB 3.0 Connected
#define         portDataSpeed_Connected_3p0_Bit                     7
/// **33** - Port Mode option code
#define    portPortMode                                            33
/// **0** - Port Mode - Power enable bit
#define         portPortMode_powerEnabled_Bit                       0
/// **1** - Port Mode - USB 2.0 (HS) 1 side enable bit.
#define         portPortMode_HS1Enabled_Bit                         1
/// **2** - Port Mode - USB 2.0 (HS) 2 side enable bit
#define         portPortMode_HS2Enabled_Bit                         2
/// **3** - Port Mode - USB 3.0 (SS) 1 side enable bit
#define         portPortMode_SS1Enabled_Bit                         3
/// **4** - Port Mode - USB 3.0 (SS) 2 side enable bit
#define         portPortMode_SS2Enabled_Bit                         4
/// **5** - Port Mode - CC 1 enable bit
#define         portPortMode_CC1Enabled_Bit                         5
/// **6** - Port Mode - CC 2 enable bit
#define         portPortMode_CC2Enabled_Bit                         6
/// **5** - Port Mode - CC 1 enable bit
#define         portPortMode_Vconn1Enabled_Bit                      7
/// **6** - Port Mode - CC 2 enable bit
#define         portPortMode_Vconn2Enabled_Bit                      8
/// **0** - Port Mode - Port Power Mode offset within Port Mode
#define         portPortMode_portPowerMode_Offset                  16
/// **XX** - Port Mode - Port Power Mode offset (Pre offset shift)
#define             portPortMode_portPowerMode_Mask               0x7
/// **0** - Port Mode - Port Power Mode: None/Disabled
#define             portPortMode_portPowerMode_none_Value           0
/// **1** - Port Mode - Port Power Mode: Standard Downstream Port (SDP)
#define             portPortMode_portPowerMode_sdp_Value            1
/// **2** - Port Mode - Mode: Charging Downstream Port (CDP) or Dedicated Charging Port (DCP)
#define             portPortMode_cdp_dcp_Value                      2
/// **3** - Port Mode - Port Power Mode: Qualcom Quick Charge (QC)
#define             portPortMode_portPowerMode_qc_Value             3
/// **4** - Port Mode - Port Power Mode: Power Delivery (PD)
#define             portPortMode_portPowerMode_pd_Value             4
/// **5** - Port Mode - Port Power Mode: Power Supply Mode (PS)
#define             portPortMode_portPowerMode_ps_Value             5
/// **34** - Port Voltage Setpoint for VBUS Override
#define    portVoltageSetpoint                                     34
/// **35** - Port Allocated Power
#define    portAllocatedPower                                      35
/// **36** - Port Change HighSpeed Data Signal Routing Behavior
#define    portDataHSRoutingBehavior                               36
/// **0** - Port Data Routing Behavior - Auto Follow CC
#define       portDataHSRoutingBehavior_FollowCC                    0
/// **1** - Port Data Routing Behavior - Side 1 Only
#define       portDataHSRoutingBehavior_Side1                       1
/// **2** - Port Data Routing Behavior - Side 2 Only
#define       portDataHSRoutingBehavior_Side2                       2
/// **3** - Port Data Routing Behavior - Side 1 and 2 Shorted
#define       portDataHSRoutingBehavior_Shorted                     3
/// **37** - Port Change SuperSpeed Data Signal Routing Behavior
#define    portDataSSRoutingBehavior                               37
/// **0** - Port Data Routing Behavior - Auto Follow CC
#define       portDataSSRoutingBehavior_FollowCC                    0
/// **1** - Port Data Routing Behavior - Side 1 Only
#define       portDataSSRoutingBehavior_Side1                       1
/// **2** - Port Data Routing Behavior - Side 2 Only
#define       portDataSSRoutingBehavior_Side2                       2
/// **38** - Vbus Accumulated Power option code
#define    portVbusAccumulatedPower                                38
/// **39** - Reset Vbus Accumulated power
#define    portResetVbusAccumulatedPower                           39
/// **40** - Vconn Accumulated Power option code
#define    portVconnAccumulatedPower                               40
/// **41** - Reset Vconn Accumulated power
#define    portResetVconnAccumulatedPower                          41
/// **42** - Port USB 2.0 High Speed Boost Settings
#define    portHSBoost                                             42

/// **44** - Port Reset to Factory Defaults option code
#define    portResetEntityToFactoryDefaults                        44
/// **45** - Number of Options for Port, always last entry
#define     portNumberOfOptions                                    45
/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
/** \defgroup cmdUSBSYSTEM_Defines USB System command defines
 * USB System entity defines.
 *
 * @{
 */
/// **38** - USB System command code.
#define cmdUSBSYSTEM                                               38

/** \defgroup cmdUSBSYSTEM_Command_Options USB System command options
 * \ingroup cmdUSBSYSTEM_Defines
 *
 * @{
 */

/// **1** - Power and Data Mode option code
#define    usbsystemPowerDataMode                                   1
/// **2** - Upstream Port option code (default port is 0)
#define    usbsystemUpstreamPort                                    2
/// **255** - UpstreamPort None to turn off all upstream connections.
#define        usbsystemUpstreamPortNone                            255
/// **3** - Enumeration Delay option code
#define    usbsystemEnumerationDelay                                3
/// **4**  - Data Role List option code
#define    usbsystemDataRoleList                                    4
/// **5**  - Enabled List option code
#define    usbsystemEnabledList                                     5
/// **6**  - Mode List option code
#define    usbsystemModeList                                        6
/// **7**  - State List option code
#define    usbsystemStateList                                       7
/// **8**  - Power behavior option code
#define    usbsystemPowerBehavior                                   8
/// **9**  - Power behavior config option code
#define    usbsystemPowerBehaviorConfig                             9
/// **10**  - Data behavior option code
#define    usbsystemDataBehavior                                    10
/// **0**  - usbsystemDataBehavior - HardCoded ports
#define         usbsystemDataBehavior_HardCoded                     0
/// **1**  - usbsystemDataBehavior - Reserved
#define         usbsystemDataBehavior_Reserved                      1
/// **2**  - usbsystemDataBehavior - Use port priority
#define         usbsystemDataBehavior_PortPriority                  2
/// **11**  - Data behavior config option code
#define    usbsystemDataBehaviorConfig                              11
/// **12**  - Selector mode option code
#define    usbsystemSelectorMode                                    12
/// **13** - Resets USBSystem reset to default option code.
#define    usbsystemResetEntityToFactoryDefaults                    13

/// **16** - Number of Options for USB System, always last entry
#define    usbsystemNumberOfOptions                                 16

/** @} */
/** @} */
/////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////

/** \defgroup cmdCAPACITY_Defines Capacity command defines
 * Capacity command.
 *
 * @{
 */
/// **73** - Capacity command code.
#define cmdCAPACITY                                                73

/** \defgroup cmdCAPACITY_Command_Options Capacity command options
 * \ingroup cmdCAPACITY_Defines
 *
 * @{
 */
/// **1** - UEI command option.
#define    capacityUEI                                              1
/// **3** - SubClass size command option.
#define    capacitySubClassSize                                     3
/// **4** - Class Quantity command option.
#define    capacityClassQuantity                                    4
/// **5** - SubClass Quantity command option.
#define    capacitySubClassQuantity                                 5
/// **6** - Entity Group command option.
#define    capacityEntityGroup                                      6
/// **7** - Build command option.
#define    capacityBuild                                          255
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdSTORE_Defines Store command defines
 * Store entity defines.
 *
 * @{
 */
/// **77** - Store command code.
#define cmdSTORE                                                  77

/** \defgroup cmdSTORE_Command_Options Store command options
 * \ingroup cmdSTORE_Defines
 *
 * @{
 */
/// **1** - Slot Enable option code.
#define    storeSlotEnable                                         1
/// **2** - Slot Disable option code.
#define    storeSlotDisable                                        2
/// **3** - Slot State option code.
#define    storeSlotState                                          3
/// **4** - Write Slot option code.
#define    storeWriteSlot                                          4
/// **5** - Read Slot option code.
#define    storeReadSlot                                           5
/// **6** - Close Slot option code.
#define    storeCloseSlot                                          6
/// **7** - Lock Slot option code.
#define    storeLock                                               7
/// **8** - Number of Options for cmdStore, always last entry
#define    storeNumberOfOptions                                    8

/** @} */

/** \defgroup cmdSTORE_Types Store command options
 * \ingroup cmdSTORE_Defines
 *
 * @{
 */

/////////////////////////////////////////////////////////////////////
/// **0** - Internal store type.
#define    storeInternalStore                                       0
/// **1** - RAM store type.
#define    storeRAMStore                                            1
/// **2** - SD Store type.
#define    storeSDStore                                             2
/// **3** - EEPROM Store type.
#define    storeEEPROMStore                                         3
/// **2** - Max type index.
#define    storeMaxStoreIndex                                       3
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdTIMER_Defines Timer command options
 * Timer Entity Defines.
 *
 * @{
 */
/// **79** - Timer command code.
#define cmdTIMER                                                    79

/** \defgroup cmdTIMER_Command_Options Timer command options
 * \ingroup cmdTIMER_Defines
 *
 * @{
 */
/// **1** - Timer expiration option code.
#define    timerExpiration                                          1
/// **2** - Timer Mode option code.
#define    timerMode                                                2
/// **0** - Single mode for timer mode option code.
#define       timerModeSingle                                       0
/// **1** - Repeat mode for timer mode option code.
#define       timerModeRepeat                                       1
/// **timerModeSingle** - Default mode for timer mode option code.
#define       DefaultTimerMode                                      0
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdCLOCK_Defines Clock command defines
 * Clock entity defines.
 *
 * @{
 */

/// **83** - Clock command code.
#define cmdCLOCK                                                   83

/** \defgroup cmdCLOCK_Command_Options Clock command options
 * \ingroup cmdCLOCK_Defines
 *
 * @{
 */
/// **1** - Year option code.
#define    clockYear                                                1
/// **2** - Month option code.
#define    clockMonth                                               2
/// **3** - Day option code.
#define    clockDay                                                 3
/// **4** - Hour option code.
#define    clockHour                                                4
/// **5** - Minute option code.
#define    clockMinute                                              5
/// **6** - Second option code.
#define    clockSecond                                              6
/** @} */
/** @} */

/////////////////////////////////////////////////////////////////////

/** \defgroup cmdUSB_Defines USB c ommand defines
 * USB entity defines.
 *
 * @{
 */
/// **18** - USB command code.
#define cmdUSB                                                     18

/** \defgroup cmdUSB_Command_Options USB command options
 * \ingroup cmdUSB_Defines
 *
 * @{
 */
/// **1** - Port Enable option code.
#define    usbPortEnable                                            1
/// **2** - Port Disable option code.
#define    usbPortDisable                                           2
/// **3** - Data Enable option code.
#define    usbDataEnable                                            3
/// **4** - Data Disable option code.
#define    usbDataDisable                                           4
/// **5** - Power Enable option code.
#define    usbPowerEnable                                           5
/// **6** - Power Disable option code.
#define    usbPowerDisable                                          6
/// **7** - Port Current option code.
#define    usbPortCurrent                                           7
/// **8** - Port Voltage option code.
#define    usbPortVoltage                                           8
/// **9** - Hub Mode option code.
#define    usbHubMode                                               9
// Option codes 10 and 11 are reserved.
/// **12** - Hub Clear Error Status option code.
#define    usbPortClearErrorStatus                                 12
/// **13** - SystemTemperature option code.
// Option code 13 is reserved.
#define    usbUpstreamMode                                         14
/// **2** - UpstreamMode Auto for upstream mode option code.
#define         usbUpstreamModeAuto                                 2
/// **0** - UpstreamMode Port 0 for upstream mode option code.
#define         usbUpstreamModePort0                                0
/// **1** - UpstreamMode Port 1 for upstream mode option code.
#define         usbUpstreamModePort1                                1
/// **255** - UpstreamMode None to turn off all upstream connections.
#define         usbUpstreamModeNone                               255
/// **1** - UpstreamMode default for upstream mode option code.
#define         usbUpstreamModeDefault                              2
/// **15** - UpstreamState option code.
#define    usbUpstreamState                                         15
/// **2** - UpstreamMode Auto for upstream mode option code.
#define         usbUpstreamStateNone                                 2
/// **0** - UpstreamMode Port 0 for upstream mode option code.
#define         usbUpstreamStatePort0                                0
/// **1** - UpstreamMode Port 1 for upstream mode option code.
#define         usbUpstreamStatePort1                                1
/// **16** - Downstream ports enumeration delay option code.
#define    usbHubEnumerationDelay                                   16
/// **17** - Set or get the port current limit option code.
#define    usbPortCurrentLimit                                      17
/// **18** - Set/Get upstream boost mode.
#define    usbUpstreamBoostMode                                     18
/// **19** - Set/Get downstream boost mode.
#define    usbDownstreamBoostMode                                   19
/// **0** - Boost mode off, no boost
#define        usbBoostMode_0                                       0
/// **1** - Boost mode 4%
#define        usbBoostMode_4                                       1
/// **2** - Boost mode 8%
#define        usbBoostMode_8                                       2
/// **3** - Boost mode 12%
#define        usbBoostMode_12                                      3
/// **20** - Set/Get Port mode (bit-packed)
///  The portMode bits follow and numbered according to their bit position.
///  if they are set i.e. a 1 in the bit position the corresponding setting
///  is enabled.
#define    usbPortMode                                              20
/// **0** - Standard Downstream port (0.5A max)
#define        usbPortMode_sdp                                      0
/// **1** - Charging Downstream port (5A max)
#define        usbPortMode_cdp                                      1
/// **2** - Trickle changing functionality
#define        usbPortMode_charging                                 2
/// **3** - Electrical pasthrough of VBUS
#define        usbPortMode_passive                                  3
/// **4** - USB2 dataline A side enabled
#define        usbPortMode_USB2AEnable                              4
/// **4** - USB2 dataline B side enabled
#define        usbPortMode_USB2BEnable                              5
/// **5** - USB VBUS enabled
#define        usbPortMode_VBusEnable                               6
/// **6** - USB SS Speed dataline side A enabled
#define        usbPortMode_SuperSpeed1Enable                        7
/// **7** - USB SS Speed dataline side B enabled
#define        usbPortMode_SuperSpeed2Enable                        8
/// **8** - USB2 Boost Mode Enabled
#define        usbPortMode_USB2BoostEnable                          9
/// **9** - USB3 Boost Mode Enabled
#define        usbPortMode_USB3BoostEnable                          10
/// **10** - Auto-connect Mode Enabled
#define        usbPortMode_AutoConnectEnable                        11
/// **11** - CC1 Enabled
#define        usbPortMode_CC1Enable                                12
/// **12** - CC2 Enabled
#define        usbPortMode_CC2Enable                                13
/// **13** - SBU1 Enabled
#define        usbPortMode_SBUEnable                                14
/// **15** - Flip CC1 and CC2
#define        usbPortMode_CCFlipEnable                             15
/// **16** - Flip Super speed data lines
#define        usbPortMode_SSFlipEnable                             16
/// **17** - Flip Side Band Unit lines.
#define        usbPortMode_SBUFlipEnable                            17
/// **18** - Flip Side Band Unit lines.
#define        usbPortMode_USB2FlipEnable                           18
/// **19** - Internal Use
#define        usbPortMode_CC1InjectEnable                          19
/// **20** - Internal Use
#define        usbPortMode_CC2InjectEnable                          20
/// **21** - Hi-Speed Data Enable option code.
#define    usbHiSpeedDataEnable                                     21
/// **22** - Hi-Speed Data Disable option code.
#define    usbHiSpeedDataDisable                                    22
/// **23** - SuperSpeed Data Enable option code.
#define    usbSuperSpeedDataEnable                                  23
/// **24** -SuperSpeed Data Disable option code.
#define    usbSuperSpeedDataDisable                                 24
/// **25** - Get downstream port speed option code.
#define    usbDownstreamDataSpeed                                   25
/// **0** - Unknown
#define        usbDownstreamDataSpeed_na                            0
/// **1** - Hi-Speed (2.0)
#define        usbDownstreamDataSpeed_hs                            1
/// **2** - SuperSpeed (3.0)
#define        usbDownstreamDataSpeed_ss                            2
/// **3** - TODO
#define        usbDownstreamDataSpeed_ls                            3
/// **26** USB connect mode option code
#define    usbConnectMode                                           26
/// **0** - Auto connect disabled
#define        usbManualConnect                                     0
/// **1** - Auto connect enabled
#define        usbAutoConnect                                       1
/// **27** - CC1 Enable option code (USB Type C).
#define    usbCC1Enable                                             27
/// **28** - CC2 Disable option code (USB Type C).
#define    usbCC2Enable                                             28
/// **29** - SBU1/2 enable option code (USB Type C).
#define    usbSBUEnable                                             29
/// **30** - CC1 get current option code (USB Type C).
#define    usbCC1Current                                            30
/// **31** - CC2 get current option code (USB Type C).
#define    usbCC2Current                                            31
/// **32** - CC1 get voltage option code (USB Type C).
#define    usbCC1Voltage                                            32
/// **33** - CC2 get voltage option code (USB Type C).
#define    usbCC2Voltage                                            33
/// **34** - TODO
#define    usbPortState                                             34
/// **35** - TODO
#define    usbPortError                                             35
/// **36** - TODO
#define    usbCableFlip                                             36
/// **37** - USB Alt Mode configuration.
#define    usbAltMode                                               37
/// **0** - Disabled mode
#define        usbAltMode_disabled                                  0
/// **1** - Normal mode (USB 3.1)
#define        usbAltMode_normal                                    1
/// **2** - Alt Mode - 4 lanes of display port "Common" side connected to host
#define        usbAltMode_4LaneDP_ComToHost                         2
/// **3** - Alt Mode - 4 lanes of display port "Mux" side connected to host
#define        usbAltMode_4LaneDP_MuxToHost                         3
/// **4** - Alt Mode - 2 lanes of display port "Common" side connected to host with USB3.1
#define        usbAltMode_2LaneDP_ComToHost_wUSB3                   4
/// **5** - Alt Mode - 2 lanes of display port "Mux" side connected to host with USB3.1
#define        usbAltMode_2LaneDP_MuxToHost_wUSB3                   5
/// **6** - Alt Mode - 2 lanes of display port "Common" side connected to host with USB3.1 with channels 1.2 and 3,4 inverted
#define        usbAltMode_2LaneDP_ComToHost_wUSB3_Inverted          6
/// **7** - Alt Mode - 2 lanes of display port "Mux" side connected to host with USB3.1 with channels 1.2 and 3,4 inverted
#define        usbAltMode_2LaneDP_MuxToHost_wUSB3_Inverted          7
/// **38** - SBU1 get voltage option code (USB Type C).
#define    usbSBU1Voltage                                            38
/// **39** - SBU2 get voltage option code (USB Type C).
#define    usbSBU2Voltage                                            39
/** @} */
/** @} */



/** \defgroup cmdSTREAM_Defines Stream command defines
 * Stream entity defines.
 *
 * @{
 */
/// **38** - Stream command code.
#define cmdSTREAM                                               93

/** \defgroup cmdSTREAM_Command_Options Stream command options
 * \ingroup cmdSTREAM_Defines
 *
 * @{
 */

/// **1** - Stream Enable option code for enable from a stream key
#define    streamEnable                                    1
/// **2** - Stream Disable option code for disable from a stream key
#define    streamDisable                                    2
/// **3** - Stream Capacity option code for asking if a specific stream key will stream
#define    streamCapacity                                   3

/// **4** - Number of Options for Stream, always last entry
#define    streamNumberOfOptions                                   4

/** @} */
/** @} */




/////////////////////////////////////////////////////////////////////

/// Factory Command - For internal use only
#define cmdFACTORY                                                   94
#define     factoryError_Bit                                          7
#define     factoryStart_Bit                                          6
#define     factoryEnd_Bit                                            5
#define     factorySet_Bit                                            4
#define     factoryCommand1_Value                                     1
#define     factoryCommand2_Value                                     2
#define     factoryCommand3_Value                                     3

/////////////////////////////////////////////////////////////////////

/// Upgrade command.
#define cmdUPGRADE                                                   95


/////////////////////////////////////////////////////////////////////

/// Last command.
#define cmdLAST                                                      95

#endif //_aProtocolDefs_H_
