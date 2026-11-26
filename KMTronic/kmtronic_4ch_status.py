# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import serial
import time
import argparse


def read_relay_status(port, channels=4):
    """
    Reads the status of KMTronic 4 or 8 channel relays via the specified serial port.

    :param port: Serial port (e.g., /dev/ttyUSB0)
    :param channels: Number of relays on the board (4 or 8); defaults to 4
    """
    if channels not in (4, 8):
        raise ValueError("Channels must be 4 or 8.")
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

        # Send the status command
        ser.write(bytearray.fromhex("FF0900"))
        time.sleep(0.1)  # Wait for the response

        # Read the response
        response = ser.read(channels)  # One byte per relay
        ser.close()

        if len(response) == channels:
            # Parse and display the relay statuses
            relay_status = [
                f"Relay {i + 1}: {'ON' if byte == 1 else 'OFF'}"
                for i, byte in enumerate(response)
            ]
            print("\n".join(relay_status))
        else:
            print("Error: Unexpected response length.")
    except serial.SerialException as e:
        print(f"Serial port error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


def main():
    parser = argparse.ArgumentParser(description="Read KMTronic 4 or 8 channel relay status.")
    parser.add_argument("port", help="Serial port, e.g. /dev/ttyUSB0")
    parser.add_argument("--channels", type=int, choices=(4, 8), default=4, help="Board channels (default: 4)")
    args = parser.parse_args()
    read_relay_status(args.port, channels=args.channels)


if __name__ == "__main__":
    main()
