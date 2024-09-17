# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

thresholds = {
    'cpu': {
        'multi': 700,
        'single': 40
    },
    'mem': {
        'multi': {
            'wr': 1400,
            'rd': 9000
        },
        'single': {
            'wr': 350,
            'rd': 250
        }
    },
    'fileio': {
        'wr': 20,
        'rd': 40,
        'rd_lenovo-x1': 420
    },
    'iperf': 10
}
