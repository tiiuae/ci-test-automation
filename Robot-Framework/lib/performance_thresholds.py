# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

thresholds = {
    'cpu': {
        'multi': 300,
        'single': 100
    },
    'mem': {
        'multi': {
            'wr': 1000,
            'rd': 5000
        },
        'single': {
            'wr': 300,
            'rd': 500
        }
    },
    'fileio': {
        'wr': 10,
        'rd': 20,
        'rd_lenovo-x1': 200
    },
    'boot_time': {
        'time_to_bootup': 60,
        'time_to_respond_to_ssh': 40,
        'time_to_respond_to_ping': 40,
        'time_to_desktop_after_reboot': 100
    },
    'iperf': 10
}
