<!--
    Copyright 2022-2026 TII (SSRC) and the Ghaf contributors
    SPDX-License-Identifier: CC-BY-SA-4.0
-->

# KMTronic relay boards

Control test device power using KMTronic USB relay boards with 4 or 8 channels (U8CR).
The scripts and Robot Framework library default to 4 channels. For U8CR, configure
8 channels even when using only its first four relays.

The channel count determines the allowed relay numbers, the relays affected by an
all-relays command, and the number of status bytes read.

## Command line

Run the commands in the repository's Nix development environment (`nix develop`).
Replace `/dev/ttyUSB0` with the board's serial port.

### Set relay state

Pass the serial port, `ON` or `OFF`, and an optional relay number. Without a relay
number, the command sets all relays on the configured board.

```sh
# Four channel board (default): turn on relay 2, then turn off all four relays
kmtronic-control /dev/ttyUSB0 ON 2
kmtronic-control /dev/ttyUSB0 OFF

# Eight channel board: turn on relay 8, then turn off all eight relays
kmtronic-control /dev/ttyUSB0 ON 8 --channels 8
kmtronic-control /dev/ttyUSB0 OFF --channels 8
```

### Read relay status

The command prints one line per relay, such as `Relay 1: OFF`.

```sh
# Four channel board (default)
kmtronic-status /dev/ttyUSB0

# Eight channel board
kmtronic-status /dev/ttyUSB0 --channels 8
```

The scripts can also be run directly from this directory using
`python kmtronic_4ch_control.py` or `python kmtronic_4ch_status.py` with the same
arguments. Both scripts support 4 and 8 channels despite their filenames.

## Robot Framework configuration

For U8CR, add `"relay_channels": 8` alongside `"relay_serial_port"` in the `addresses`
section of `Robot-Framework/config/test_config.json` (or the configuration selected
by `CONFIG_PATH`). Omit it or set it to `4` for a four channel board.

The existing `relay_number` under each device selects its relay on that board.
The same test keywords work with both board sizes.

## Python library

Set the channel count when creating the library instance; it defaults to 4.

```python
relay = KMTronicLibrary(port, channels=8)
relay.set_relay_state(8, "ON")
state = relay.get_relay_state(8)
relay.close_relay_board_connection()
```

## Software checks

Run from the repository root:

```sh
nix develop --command python -m unittest discover -s KMTronic/tests -v
```

These checks use a simulated serial board; they do not switch hardware relays.

The U8CR protocol is documented in the
[manufacturer's manual](https://info.kmtronic.com/manuals/user_manuals/U8CR_USB_EIGHT_CHANNEL_RELAY.pdf).
