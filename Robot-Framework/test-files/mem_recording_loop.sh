#!/bin/sh

# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

# Record memory and swap snapshots to a CSV file at given interval.
#
# Arguments:
#   $1: output CSV path
#   $2: sampling interval in seconds
#   $3: timeout in seconds

set -eu

csv_path="$1"
interval_s="$2"
timeout_s="$3"
start_epoch_s="$(date +%s)"

printf "%s\n" "datetime,mem_total_kb,mem_avail_kb,swap_total_kb,swap_free_kb" > "$csv_path"

while true; do
    current_epoch_s="$(date +%s)"
    elapsed_s=$((current_epoch_s - start_epoch_s))
    if [ "$elapsed_s" -gt "$timeout_s" ]; then
        break
    fi

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    awk -v ts="$timestamp" '
        /MemTotal:/     { mem_total_kb = $2 }
        /MemAvailable:/ { mem_avail_kb = $2 }
        /SwapTotal:/    { swap_total_kb = $2 }
        /SwapFree:/     { swap_free_kb = $2 }
        END {
            printf "%s,%s,%s,%s,%s\n",
                ts, mem_total_kb, mem_avail_kb, swap_total_kb, swap_free_kb
        }
    ' /proc/meminfo >> "$csv_path"
    sleep "$interval_s"
done
