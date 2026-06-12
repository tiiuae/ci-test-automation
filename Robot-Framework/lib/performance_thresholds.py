# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

'''
Threshold values for performance test cases

If a measurement differs more than its threshold value from the mean of the last baseline period
it is labeled as deviation/improvement.

Deviation from first measurement of last baseline period is not anymore used as pass/fail criteria.
However, it is still logged.

Threshold can be given as
- absolute value (int/float)
- relative value (string including int/float and '%' at the end)
- multiple of population standard deviation (string including int/float and 'std' at the end)

In case of relative threshold the absolute threshold will be calculated as a percentage from the mean of the last baseline period.

Threshold can be defined as multiple of standard deviation when the test case has accumulated some measurement result history.
Threshold is limited to 1/3 of mean at maximum when using this std method.
'''

thresholds = {

    'cpu': {
        'multi': 700,
        'single': 40
    },
    'mem': {
        'multi': {
            'wr': "10%",
            'rd': 9000
        },
        'single': {
            'wr': 350,
            'rd': 350
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
    'iperf': "40%",
    'cpu_isolation': 7,
    'fileio_isolation': 10,
    'vm_memory_snapshot': {
        'mem_avail_pct': 20
    },
    'cyclictest': {
        # Same value is used both as the absolute pass/fail limit for avg latency measurement of the variant
        # and as the cyclictest histogram limit that defines overflow counting.
        'ghaf-host': {
            'latency_threshold_us_t1_p80': 300,
            'latency_threshold_us_t1_p95': 300,
            'latency_threshold_us_tnproc_p80': 1000,
            'latency_threshold_us_tnproc_p95': 1000,
        },
        'gui-vm': {
            'latency_threshold_us_t1_p80': 4000,
            'latency_threshold_us_t1_p95': 4000,
            'latency_threshold_us_tnproc_p80': 8000,
            'latency_threshold_us_tnproc_p95': 8000,
        },
        # The number of allowed overflows above latency_threshold_us_<variant>
        'latency_overflow_count': 10,
    },

}

'''
Parameter 'wait_until_reset':
Baselines of a test will be automatically re-tuned if this number of
deviations are detected in a row (to the same direction)
'''

static_thresholds = {
    'app_launch_time': 10,
    'app_launch_time_storedisk': 5,
    'wait_until_reset': 5
}
