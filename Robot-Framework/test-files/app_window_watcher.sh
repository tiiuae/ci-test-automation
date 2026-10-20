#!/bin/sh

set -eu

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 EXPECTED_WINDOW [EXPECTED_WINDOW ...]" >&2
    exit 2
fi

watch_dir=$(mktemp -d)
watch_fifo=$watch_dir/events
watch_pid=

cleanup() {
    if [ -n "$watch_pid" ]; then
        kill "$watch_pid" 2>/dev/null || true
        wait "$watch_pid" 2>/dev/null || true
    fi
    rm -f "$watch_fifo"
    rmdir "$watch_dir" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 2' HUP INT TERM

mkfifo "$watch_fifo"
exec 3<> "$watch_fifo"
WAYLAND_DISPLAY=wayland-1 stdbuf -oL lswt --watch > "$watch_fifo" 2>&1 &
watch_pid=$!

# Give lswt time to establish its Wayland subscription before launching the app.
sleep 0.1
# KEY_ENTER is Linux input event code 28.
printf '%s input: pressing ENTER\n' "$(date '+%Y-%m-%d %H:%M:%S.%3N')" >&2
start_ms=$(date +%s%3N)
YDOTOOL_SOCKET=${YDOTOOL_SOCKET:-/tmp/.ydotool_socket} ydotool key 28:1 28:0
printf '%s input: pressed ENTER\n' "$(date '+%Y-%m-%d %H:%M:%S.%3N')" >&2

while IFS= read -r line; do
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S.%3N')" "$line" >&2
    for expected_window in "$@"; do
        case "$line" in
            *"$expected_window"*)
                end_ms=$(date +%s%3N)
                elapsed_ms=$((end_ms - start_ms))
                printf '%d.%03d\n' \
                    "$((elapsed_ms / 1000))" "$((elapsed_ms % 1000))"
                exit 0
                ;;
        esac
    done
done <&3

exit 1
