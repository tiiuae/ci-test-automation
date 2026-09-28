#!/usr/bin/env bash
set -euo pipefail

# Run as root in gui-vm before attempting to kill a blocked application.
mark="dax-snapshot-$$-$(date +%Y%m%d-%H%M%S)"

echo "$mark" > /dev/kmsg
echo w > /proc/sysrq-trigger

sleep 1

dmesg | sed -n "/$mark/,\$p"
