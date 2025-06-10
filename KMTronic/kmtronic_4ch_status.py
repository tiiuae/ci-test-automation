# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import serial
import time
import sys


def read_relay_status(port):
    """
    Reads the status of KMTronic 4 channel relays via the specified serial port.

    :param port: Serial port (e.g., /dev/ttyUSB0)
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

        # Send the status command
        ser.write(bytearray.fromhex("FF0900"))
        time.sleep(0.1)  # Wait for the response

        # Read the response
        response = ser.read(4)  # Read 4 bytes, one byte per relay
        ser.close()

        if len(response) == 4:
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
    # Check for the port argument
    if len(sys.argv) != 2:
        print("Usage: python kmtronic_status.py <serial_port>")
        print("Example: python kmtronic_status.py /dev/ttyUSB0")
    else:
        port = sys.argv[1]
        read_relay_status(port)


if __name__ == "__main__":
    main()
