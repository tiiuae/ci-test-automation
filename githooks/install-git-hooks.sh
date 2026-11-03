#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

set -e

if [ ! -d ./.git/hooks ]; then
    echo "./.git/hooks not found" >&2
    exit 1
fi

if [ ! -f ./githooks/check-commit.sh ]; then
    echo "./githooks/check-commit.sh not found" >&2
    exit 1
fi

install_hook() {
    local hook_name="$1"
    local target="$2"
    local hook_path="./.git/hooks/${hook_name}"

    if [ -L "$hook_path" ] && [ "$(readlink "$hook_path")" = "$target" ]; then
        echo "${hook_path} already points to ${target}"
    elif [ -e "$hook_path" ] || [ -L "$hook_path" ]; then
        echo "${hook_path} exists already and will not be overwritten" >&2
        return 1
    else
        ln -s "$target" "$hook_path"
    fi
}

install_hook commit-msg ../../githooks/check-commit.sh
