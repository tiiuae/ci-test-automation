#!/usr/bin/env sh
set -eu

target_file="${1:-/etc/sudoers}"
tmp_prefix="/tmp/sudoers.robot"

base_file="${tmp_prefix}.base"
block_file="${tmp_prefix}.block"
new_file="${tmp_prefix}.new"

cp "$target_file" "$base_file"

if grep -q "^# BEGIN ROBOT TEST SUDOERS$" "$target_file"; then
    sed "/^# BEGIN ROBOT TEST SUDOERS$/,/^# END ROBOT TEST SUDOERS$/d" \
        "$target_file" > "$base_file"
fi

{
    printf "\n# BEGIN ROBOT TEST SUDOERS\n"
    printf "ghaf ALL=(root) NOPASSWD: ALL\n"
    printf "\n# END ROBOT TEST SUDOERS\n"
} > "$block_file"

cat "$base_file" "$block_file" > "$new_file"

if command -v visudo >/dev/null 2>&1; then
    visudo -cf "$new_file"
elif [ -x /run/current-system/sw/bin/visudo ]; then
    /run/current-system/sw/bin/visudo -cf "$new_file"
else
    echo "visudo not found" >&2
    exit 1
fi

install -m 0440 "$new_file" "$target_file"
printf "__ROBOT_SUDOERS_INSTALL_DONE__\n"
