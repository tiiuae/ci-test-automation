# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import serial
import argparse
import time


def set_relay_state(port, relay_number=None, state=None, channels=4):
    """
    Sets the state of one or more relays on the KMTronic 4 or 8 channel device.

    :param port: Serial port (e.g., /dev/ttyUSB0)
    :param relay_number: Relay number (1-channels), or None to control all relays
    :param channels: Number of relays on the board (4 or 8); defaults to 4
    :param state: Desired state ("ON" or "OFF"), or None to turn all off
    """
    if channels not in (4, 8):
        raise ValueError("Channels must be 4 or 8.")
    if relay_number is not None and not 1 <= relay_number <= channels:
        raise ValueError(f"Relay number must be between 1 and {channels}.")
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
            for relay in range(1, channels + 1):
                command = (
                    bytearray.fromhex("FF")
                    + bytearray([relay])
                    + (b"\x01" if state == "ON" else b"\x00")
                )
                ser.write(command)
                time.sleep(0.1)  # Small delay between commands
            print(f"All relays set to {state}.")
        else:
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
    parser = argparse.ArgumentParser(description="Control KMTronic 4 or 8 channel relays.")
    parser.add_argument("port", help="Serial port, e.g. /dev/ttyUSB0")
    parser.add_argument("state", type=str.upper, choices=("ON", "OFF"))
    parser.add_argument("relay_number", type=int, nargs="?", help="Omit to control all relays")
    parser.add_argument("--channels", type=int, choices=(4, 8), default=4, help="Board channels (default: 4)")
    args = parser.parse_args()
    if args.relay_number is not None and not 1 <= args.relay_number <= args.channels:
        parser.error(f"Relay number must be between 1 and {args.channels}.")
    set_relay_state(args.port, relay_number=args.relay_number, state=args.state, channels=args.channels)


if __name__ == "__main__":
    main()
