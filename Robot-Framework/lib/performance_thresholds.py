# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

thresholds = {
    'cpu': {
        'multi': 700,
        'single': 40,
        'single_nuc': 120
    },
    'mem': {
        'multi': {
            'wr': 1400,
            'rd': 9000
        },
        'single': {
            'wr': 350,
            'rd': 250,
            'wr_nuc': 800,
            'rd_nuc': 800
        }
    },
    'fileio': {
        'wr': 20,
        'rd': 40,
        'rd_lenovo-x1': 420
    },
    'boot_time': {
        'time_to_bootup': 60,
        'time_to_respond_to_ssh': 40,
        'time_to_respond_to_ping': 40,
        'time_to_desktop_after_reboot': 100
    },
    'iperf': 10
}
