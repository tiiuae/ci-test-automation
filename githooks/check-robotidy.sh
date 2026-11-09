#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
export PYTHONPATH="${repo_root}/Robot-Framework${PYTHONPATH:+:$PYTHONPATH}"

if ! command -v robotidy >/dev/null 2>&1; then
    echo "WARNING: Robotidy is not installed or not on PATH; cannot check Robot Framework files." >&2
    echo "Enter the repository devshell with 'nix develop', then preview with 'robotidy --diff Robot-Framework'." >&2
    echo "If the changes look right, run 'robotidy --overwrite Robot-Framework', review, and stage them." >&2
    exit 1
fi

if (($# == 0)); then
    mapfile -d '' -t staged_files < <(
        git diff --cached --name-only --diff-filter=ACMR -z -- '*.robot' '*.resource'
    )
    if ((${#staged_files[@]} == 0)); then
        exit 0
    fi
    set -- "${staged_files[@]}"
fi

robotidy --check "$@" || {
    echo >&2
    echo "Preview the changes with 'robotidy --diff Robot-Framework'." >&2
    echo "If they look right, apply them with 'robotidy --overwrite Robot-Framework', review, and stage the changes." >&2
    echo "Then try the commit again." >&2
    exit 1
}
