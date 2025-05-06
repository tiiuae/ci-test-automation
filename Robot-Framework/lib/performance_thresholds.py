# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

'''
Threshold values for performance test cases

If a measurement differs more than threshold from any of the baselines:
- previous measurement
- mean of last baseline period
- first measurement of last baseline period
it is labeled as deviation/improvement.

Threshold can be given as absolute values (int/float)
or as relative values (string including int/float and '%' at the end).
In case of relative threshold the absolute threshold will be calculated as a percentage from the mean of the last baseline period.

Parameter 'wait_until_reset':
Baselines of a test will be automatically re-tuned if this number of
deviations are detected in a row (to the same direction)
'''

thresholds = {
    'wait_until_reset': 5,
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
        'response_to_ping': 10,
        'time_to_desktop': 12
    },
    'iperf': "40%"
}
