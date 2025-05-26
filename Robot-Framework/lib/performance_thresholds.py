# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

'''
Threshold values for performance test cases

If a measurement differs more than threshold from any of the baselines:
- previous measurement
- mean of last baseline period
- first measurement of last baseline period
it is labeled as deviation/improvement.

Threshold can be given as
- absolute value (int/float)
- relative value (string including int/float and '%' at the end)
- multiple of population standard deviation (string including int/float and 'std' at the end)

In case of relative threshold the absolute threshold will be calculated as a percentage from the mean of the last baseline period.

Threshold can be defined as multiple of standard deviation when the test case has accumulated some measurement result history.
Threshold is limited to 1/3 of mean at maximum when using this std method.

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
            'rd': 350,
            'wr_nuc': 800,
            'rd_nuc': 800
        }
    },
    'fileio': {
        'wr': "5std",
        'rd': "5std",
        'rd_lenovo-x1': "5std"
    },
    'boot_time': {
        'response_to_ping': 10,
        'time_to_desktop': 12
    },
    'iperf': "40%"
}
