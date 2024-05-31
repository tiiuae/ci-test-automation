# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

thresholds = {
    'cpu': {
        'multi': 300,
        'single': 100
    },
    'mem': {
        'multi': {
            'wr': 800,
            'rd': 2000
        },
        'single': {
            'wr': 300,
            'rd': 500
        }
    },
    'fileio': {
        'wr': 10,
        'rd': 20
    },
    'iperf': 10
}
