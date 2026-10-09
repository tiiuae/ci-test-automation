# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import datetime
from robot.libraries.BuiltIn import BuiltIn
import logging


def set_variable_by_name(name, value):
    var_name = '${' + name + '}'
    BuiltIn().set_global_variable(var_name, value)

def count_lines(output):
    lines = [line for line in output.splitlines()]
    return len(lines)

def get_matching_lines(output, match):
    return [line for line in output.splitlines() if match in line]

def get_epoch_time(timestamp):
    epoch_time = int(datetime.datetime.fromisoformat(timestamp).timestamp())
    return epoch_time

def normalize_nix_store_paths(output):
    paths = sorted(
        path.removeprefix('/nix/store/')
        for path in output.splitlines()
        if path != 'lost+found'
    )
    logging.info(f'Normalized Nix store paths:\n' + '\n'.join(paths))
    return paths

def save_nix_store_path_differences(visible_paths, provided_paths):
    visible = set(visible_paths)
    provided = set(provided_paths)
    unexpected_paths = sorted(visible - provided)
    missing_paths = sorted(provided - visible)
    logging.info(f'Unexpected paths visible:\n' + '\n'.join(unexpected_paths))
    logging.info(f'Provided paths missing:\n' + '\n'.join(missing_paths))
