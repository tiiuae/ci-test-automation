# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import re


def get_systemctl_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'State: (\w+)', output)

    if match:
        return match.group(1)
    else:
        raise Exception("Couldn't parse systemctl status")

def get_service_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'Active: (\w+) \((\w+)', output)

    if match:
        return match.group(1), match.group(2)
    else:
        raise Exception("Couldn't parse systemctl status")


def find_pid(output, proc_name):
    pid = None
    output = output.split('\n')
    for line in output:
        if proc_name in line:
            pid = line.split()[1]
            break
    if pid:
        return pid
    else:
        return None

def verify_shutdown_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'ExecStop=.*\(code=(\w+), status=(.*)\)', output)
    if match:
        return match.group(1), match.group(2)
    else:
        raise Exception("Couldn't parse shutdown status")
