# Ghaf Bluetooth Test Board Firmware

This document describes how to flash, rebuild, and validate the test firmware used for the Ghaf Bluetooth connectivity test board.

The firmware is based on the Zephyr `samples/bluetooth/peripheral` application from nRF Connect SDK (NCS) `v3.2.1`, with a small local patch that makes the device resume advertising after a disconnect. This behavior is required for repeated automated connectivity testing.

## Scope

The resulting firmware is intended to run on the Nordic Semiconductor `nrf52840dk/nrf52840` board and expose a connectable Bluetooth LE peripheral that can be discovered and reconnected by a Linux host during test execution.

The files in this directory are source artifacts for a separate build/flash environment. You do not need to run the build commands from this repository directory. Copy the required `.hex` file from `firmware/` or `restart_bt.patch` from this directory to the machine or workspace where you flash or build firmware.

## Host Requirements

For flashing a prebuilt image:

- Linux host
- `tar`
- BlueZ tools, including `bluetoothctl`
- Nordic nRF Command Line Tools, including `nrfjprog`

For rebuilding the firmware:

- Python 3
- `git`
- `wget`
- `CMake`
- `dtc`
- `ninja`
- `gperf`
- `ccache`
- `dfu-util`
- `venv` support for Python
- Zephyr SDK `0.17.4`

Install the Nordic command-line tools before continuing:

- Nordic reference: <https://academy.nordicsemi.com/?nds_version_content=nrf-connect-sdk-fundamentals-lesson-1-exercise-1-installing-nrf-connect-sdk-and-vs-code-v2-9-0-v2-7-0>

- Download:
```
wget https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools-10.24.2_linux-amd64.tar.gz
```
- Extract tools:
```
sudo tar xf nrf-command-line-tools-10.24.2_linux-amd64.tar.gz -C /opt/
```
- Update your env $PATH according to shell you are using (echo $SHELL), for bashrc:
```
echo 'export PATH=/opt/nrf-command-line-tools/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

- Download SEGGER J-Link:
```
https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.tgz
```
- Extract:
```
sudo mkdir -p /opt/SEGGER
sudo tar xf JLink_Linux_V946_x86_64.tgz -C /opt/SEGGER
```
- Update your environment according to the shell you are using, for bashrc:
```
echo 'export LD_LIBRARY_PATH=/opt/SEGGER/JLink_Linux_V946_x86_64:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=/opt/SEGGER/JLink_Linux_V946_x86_64:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Directory Layout

This repository contains the following firmware-related assets:

- [`restart_bt.patch`](restart_bt.patch)
- [`firmware/ghaf_bt_release.hex`](firmware/ghaf_bt_release.hex)
- [`firmware/ghaf_bt_dev.hex`](firmware/ghaf_bt_dev.hex)
- [`firmware/ghaf_bt_prod.hex`](firmware/ghaf_bt_prod.hex)

`restart_bt.patch` does two things:

- changes the advertised device name to `Ghaf Test Bluetooth Board Release` in the provided patch; this name is only an example and can be changed before building
- restarts connectable advertising when the previous connection object is recycled after disconnect

## 0. Choose a Workflow

Use one of the following workflows:

- **Flash an existing image** if you only need to reprogram the board with one of the ready-made `.hex` files from `firmware/`.
- **Build a new image** if you need to change the firmware, for example to use a different Bluetooth device name.

The ready-made images can be flashed directly with `nrfjprog`; in that case, skip the build sections and go directly to [Flash a Prebuilt Image](#6-flash-a-prebuilt-image). The patch is only needed when rebuilding the firmware from the Zephyr sample.

## 1. Create the Build Environment

Create a clean NCS workspace:

```bash
mkdir -p ~/ncs
cd ~/ncs
```

Create and activate a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip wheel west
```

Initialize the nRF Connect SDK workspace and fetch sources:

```bash
west init -m https://github.com/nrfconnect/sdk-nrf --mr v3.2.1
west update
west zephyr-export
```

Install Python dependencies required by Zephyr and NCS:

```bash
pip install -r zephyr/scripts/requirements.txt
pip install -r nrf/scripts/requirements.txt
```

## 2. Install Zephyr SDK

Download and install Zephyr SDK `0.17.4`:

```bash
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.4/zephyr-sdk-0.17.4_linux-x86_64.tar.xz
tar xvf zephyr-sdk-0.17.4_linux-x86_64.tar.xz
cd zephyr-sdk-0.17.4
./setup.sh
```
Note: on NixOS it is highly likely that `./setup.sh` will fail on host tools installation, so do that manually:

```
find $HOME/zephyr-sdk-0.17.4/sysroots/x86_64-pokysdk-linux \
  -type f -perm -111 -print0 \
| xargs -0 python3 $HOME//zephyr-sdk-0.17.4/relocate_sdk.py \
  $HOME/zephyr-sdk-0.17.4 \
  $HOME/zephyr-sdk-0.17.4/sysroots/x86_64-pokysdk-linux/lib/ld-linux-x86-64.so.2
```

If your shell environment does not already export the SDK path, set it explicitly:

```bash
export ZEPHYR_SDK_INSTALL_DIR=$HOME/zephyr-sdk-0.17.4
```

## 3. Copy and Apply the Local Firmware Patch

Copy `restart_bt.patch` from this directory to the build machine, for example:

```bash
cp /path/to/ci-test-automation/Bluetooth_board/restart_bt.patch ~/ncs/restart_bt.patch
```

Apply the patch to the Zephyr sample:

```bash
cd ~/ncs/zephyr
git apply ../restart_bt.patch
```

The patch is expected to apply to these files inside the NCS workspace:

- `samples/bluetooth/peripheral/prj.conf`
- `samples/bluetooth/peripheral/src/main.c`

If you need to change the advertised board name, modify `CONFIG_BT_DEVICE_NAME=` in `samples/bluetooth/peripheral/prj.conf` after applying the patch.

## 4. Build the Firmware

Build the patched Zephyr Bluetooth peripheral sample for the nRF52840 DK:

```bash
cd ~/ncs
west build -p always -b nrf52840dk/nrf52840 zephyr/samples/bluetooth/peripheral
```

The expected build output is:

```text
~/ncs/build/merged.hex
```

## 5. Flash the Board

Connect the board over USB and list connected debuggers:

```bash
nrfjprog --ids
```

This command returns one or more SEGGER serial numbers, for example:

```text
1050288781
```

Flash the board using the detected device ID:

```bash
cd ~/ncs

sudo env \
  LD_LIBRARY_PATH=/opt/SEGGER/JLink_Linux_V946_x86_64 \
  PATH=/opt/nrf-command-line-tools/bin:/opt/SEGGER/JLink_Linux_V946_x86_64:$PATH \
  west flash --skip-rebuild \
  --runner nrfjprog \
  --hex-file ~/ncs/build/merged.hex \
  --dev-id 1050288781
```

Replace `1050288781` with the actual ID returned by `nrfjprog --ids`.

## 6. Flash a Prebuilt Image

If you do not need to rebuild from source, copy one of the prebuilt `.hex` files from `firmware/` to any convenient directory on the flashing machine and program it directly.

Example:

```bash
mkdir -p /tmp/ghaf-bt-firmware
cp /path/to/ci-test-automation/Bluetooth_board/firmware/ghaf_bt_release.hex /tmp/ghaf-bt-firmware/

sudo env \
  LD_LIBRARY_PATH=/opt/SEGGER/JLink_Linux_V946_x86_64 \
  PATH=/opt/nrf-command-line-tools/bin:/opt/SEGGER/JLink_Linux_V946_x86_64:$PATH \
  west flash --skip-rebuild \
  --runner nrfjprog \
  --hex-file /tmp/ghaf-bt-firmware/ghaf_bt_release.hex \
  --dev-id 1050288781
```

Available prebuilt images:

- [`firmware/ghaf_bt_release.hex`](firmware/ghaf_bt_release.hex)
- [`firmware/ghaf_bt_dev.hex`](firmware/ghaf_bt_dev.hex)
- [`firmware/ghaf_bt_prod.hex`](firmware/ghaf_bt_prod.hex)

Use this path only if the selected image already matches the test scenario you need.

## 7. Open the Serial Console

After flashing, connect to the USB CDC ACM console exposed by the board. On most Linux systems it appears as `/dev/ttyACM0`.

Example with `minicom`:

```bash
minicom -D /dev/ttyACM0 -b 115200
```

The boot log can include messages like:

```text
Bluetooth initialized
Advertising successfully started
```

If the console is empty, try to discover the board from another device and connect to it. To connect via Linux CLI, see the next section.

After a client connects, you should see `Connected` in the logs.

After disconnecting, the logs should include:

```text
Disconnected, reason 0x13
Connection object recycled
Advertising restarted
```

These messages confirm that the board is ready for repeated reconnect testing.

## 8. Validate Bluetooth Connectivity from Linux

Open `bluetoothctl` on the Linux host:

```bash
bluetoothctl
```

Run the basic validation sequence:

```text
scan on
scan off
connect <MAC_ADDR>
disconnect
connect <MAC_ADDR>
```

What to verify:

- the board is visible during scanning
- the advertised device name matches the name configured before building, for example `Ghaf Test Bluetooth Board Release`
- the initial connection succeeds
- after `disconnect`, the board starts advertising again automatically
- the board accepts a second connection without reflashing or manual reset

You can obtain the device MAC address from the `bluetoothctl` scan output.


## Troubleshooting

If `west build` fails:

- confirm that the Python virtual environment is active
- confirm that both Zephyr and NCS Python requirements were installed
- confirm that `ZEPHYR_SDK_INSTALL_DIR` points to Zephyr SDK `0.17.4`

If `git apply` fails:

- confirm that the workspace was initialized from `sdk-nrf` tag `v3.2.1`
- confirm that the patch is being applied from `~/ncs/zephyr`
- confirm that `restart_bt.patch` was copied from this directory to the build workspace

If flashing fails:

- verify that `nrfjprog --ids` returns the board ID
- verify that no other process is holding the debug probe
- verify USB permissions on the host

If the board does not reappear after disconnect:

- verify that the patch was applied before building
- check the serial console for `Advertising restarted`

## Reproducibility Notes

This procedure assumes the following pinned versions from the original setup notes:

- nRF Connect SDK: `v3.2.1`
- Zephyr SDK: `0.17.4`
- target board: `nrf52840dk/nrf52840`

If any of these versions are changed, revalidate that `restart_bt.patch` still applies cleanly and that reconnect behavior is preserved.
