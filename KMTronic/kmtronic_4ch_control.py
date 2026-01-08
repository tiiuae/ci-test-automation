# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import serial
import sys
import time


def set_relay_state(port, relay_number=None, state=None):
    """
    Sets the state of one or more relays on the KMTronic 4 channel device.

    :param port: Serial port (e.g., /dev/ttyUSB0)
    :param relay_number: Relay number (1-4), or None to control all relays
    :param state: Desired state ("ON" or "OFF"), or None to turn all off
    """
    try:
        # Configure the serial port
        ser = serial.Serial(
            port=port,
            baudrate=9600,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1,
        )

        if relay_number is None:
            # Control all relays one by one
            for relay in range(1, 5):  # Relay numbers 1 to 4
                command = (
                    bytearray.fromhex("FF")
                    + bytearray([relay])
                    + (b"\x01" if state == "ON" else b"\x00")
                )
                ser.write(command)
                time.sleep(0.1)  # Small delay between commands
            print(f"All relays set to {state}.")
        else:
            if relay_number < 1 or relay_number > 4:
                raise ValueError("Relay number must be between 1 and 4.")
            # KMTronic protocol uses 0-indexed relay numbers
            command = (
                bytearray.fromhex("FF")
                + bytearray([relay_number])
                + (b"\x01" if state == "ON" else b"\x00")
            )
            ser.write(command)
            print(f"Relay {relay_number} set to {state}.")

        ser.close()
    except serial.SerialException as e:
        print(f"Serial port error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


def main():
    # Check for sufficient arguments
    if len(sys.argv) < 3:
        print("Usage: python kmtronic_control.py <serial_port> <state> [relay_number]")
        print(
            "Example 1: python kmtronic_control.py /dev/ttyUSB0 ON 1  # Turn relay 1 ON"
        )
        print(
            "Example 2: python kmtronic_control.py /dev/ttyUSB0 OFF    # Turn all relays OFF"
        )
        sys.exit(1)

    # Parse arguments
    port = sys.argv[1]
    state = sys.argv[2].upper()

    if state not in ["ON", "OFF"]:
        print("Error: State must be 'ON' or 'OFF'.")
        sys.exit(1)

    if len(sys.argv) > 3:
        # Control a specific relay
        relay_number = int(sys.argv[3])
        set_relay_state(port, relay_number=relay_number, state=state)
    else:
        # Control all relays
        set_relay_state(port, state=state)


if __name__ == "__main__":
    main()
