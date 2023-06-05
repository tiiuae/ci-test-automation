/****************************************************************
 * Filename: brainstem_network.cpp
 * Prepared By: James Dudley
 * Date Prepared: March 12, 2018
 * Date Revised: March 12, 2018
 * Revision: 0.0.1
 ***************************************************************/

#include "BrainStem2/BrainStem-all.h"
#include <iostream>


#define USB_CHANNEL                   0
#define RAIL0_SET_VOLTAGE       2200000     // Set voltage for MTM-PM-1 Rail 0
#define RAIL1_SET_VOLTAGE       2800000     // Set voltage for MTM-IO-SERIAL Rail 1
#define CYCLE_TIME                   20     // Time to pause between readings, ms

int main(int argc, const char * argv[]) {
    // Create each MTM object
    // Apply a module offset of 24 to the MTM-PM-1 module (determined by the DIP switch
    // on the development board
    aMTMIOSerial ioserial;
    aMTMPM1 pm;
    pm.setModuleAddress(aMTMPM1_MODULE_BASE_ADDRESS + 24);
    aMTMUSBStem stem;

    // Initialize error tracker
    aErr err = aErrNone;

    // Discover and connect to MTM-IO-SERIAL object
    // First, get a list of all available USB modules (Note: MTM-PM-1 shows up because there's
    // a pass-through USB channel on the MTM-IO-SERIAL, which is connected to the MTM-PM-1 edge
    // connector USB on the development board)
    list<linkSpec> spec_list;
    err = Link::sDiscover(USB, &spec_list);

    //
    list<linkSpec>::iterator it;
    for (it = spec_list.begin(); it != spec_list.end(); ++it) {
        if (it->model == aMODULE_TYPE_MTMIOSerial_1) {
            err = ioserial.connect(USB, it->serial_num);
            if (err != aErrNone) {
                printf("Error connecting to MTM-IO-Serial: %d\n", err);
                return 0;
            }
            break;
        }
    }
    if (!ioserial.isConnected()) {
        printf("Error finding MTM-IO-SERIAL module: no MTM-IO-SERIAL link Spec discovered/n");
        return 0;
    }

    err = pm.connectThroughLinkModule(&ioserial);
    if (err != aErrNone) {
        printf("Error connecting to MTM-PM-1: %d\n", err);
        return 0;
    }
    err = stem.connectThroughLinkModule(&ioserial);
    if (err != aErrNone) {
        printf("Error connecting to MTM-USBStem: %d\n", err);
        return 0;
    }

    err = ioserial.system.routeToMe(1);
    if (err != aErrNone) {
        printf("Error setting MTM-IO-SERIAL routeToMe: %d\n", err);
        return 0;
    }

    // 1 - Set MTM-PM-1 Rail 0 and measure the voltage using MTM-USBSTEM A2D0
    err = pm.rail[0].setVoltage(RAIL0_SET_VOLTAGE);
    if (err != aErrNone) {
        printf("Error setting Rail 0 voltage to %.3fV: %d\n", (float) RAIL0_SET_VOLTAGE / 1e6, err);
        return 0;
    }

    err = pm.rail[0].setEnable(1);
    if (err != aErrNone) {
        printf("Error enabling Rail 0: %d\n", err);
        return 0;
    }

    aTime_MSSleep(CYCLE_TIME);

    int32_t a2d0_voltage;
    err = stem.analog[0].getVoltage(&a2d0_voltage);
    if (err != aErrNone) {
        printf("Error reading A2D0 voltage: %d\n", err);
        return 0;
    }

    printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
    printf("MTM-PM-1 Rail 0: %.3fV\n", (float) RAIL0_SET_VOLTAGE / 1e6);
    printf("MTM-USBSTEM A2D0: %.3fV\n", (float) a2d0_voltage / 1e6);
    printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");

    // 2 - (optional) Toggle MTM-IO-SERIAL USB channel on/off
    err = ioserial.usb.setPortEnable(USB_CHANNEL);
    if (err != aErrNone) {
        printf("Error enabling USB channel %d: %d\n", USB_CHANNEL, err);
        return 0;
    }

    printf("Verify USB device enumeration (optional) and press Enter to continue...\n");
    std::cin.get();

    err = ioserial.usb.setPortDisable(USB_CHANNEL);
    if (err != aErrNone) {
        printf("Error disabling USB channel %d: %d\n", USB_CHANNEL, err);
        return 0;
    }


    // 3 - Set MTM-IO-SERIAL Rail 1 and measure the voltage using MTM-USBSTEM A2D1
    err = ioserial.rail[1].setVoltage(RAIL1_SET_VOLTAGE);
    if (err != aErrNone) {
        printf("Error setting Rail 1 voltage to %.3f: %d\n", (float) RAIL1_SET_VOLTAGE / 1e6, err);
        return 0;
    }

    err = ioserial.rail[1].setEnable(1);
    if (err != aErrNone) {
        printf("Error enabling Rail 1: %d\n", err);
        return 0;
    }

    aTime_MSSleep(CYCLE_TIME);

    int32_t a2d1_voltage;
    err = stem.analog[1].getVoltage(&a2d1_voltage);
    if (err != aErrNone) {
        printf("Error reading A2D1 voltage: %d\n", err);
        return 0;
    }

    printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");
    printf("MTM-IO-SERIAL Rail 1: %.3fV\n", (float) RAIL1_SET_VOLTAGE / 1e6);
    printf("MTM-USBSTEM A2D1: %.3fV\n", (float) a2d1_voltage / 1e6);
    printf("* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n");

    stem.disconnect();
    pm.disconnect();
    ioserial.disconnect();

    return 0;
}
