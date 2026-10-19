# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from Zephyr import Zephyr, ZephyrTestStatuses
from robot.running import TestCase
from robot.result import TestCase as TestResult
from robot.libraries.BuiltIn import BuiltIn
from robot.api import logger


robot_status_to_zephyr = {
        'PASS': ZephyrTestStatuses.PASS,
        'FAIL': ZephyrTestStatuses.FAIL,
        'NOT RUN': ZephyrTestStatuses.NOT_EXECUTED,
        'SKIP': ZephyrTestStatuses.BLOCKED
}

# each tuple represents (%Installer%, %Secure Boot%, %Architecture%)
target_to_cycle_map = {
    'orin-agx64': {
        (False, True, 'x86_64'): "SSRCSP-C223",
        (False, True, 'aarch64'): "SSRCSP-C222",
    },
    'orin-agx': {
        (False, False, 'x86_64'): "SSRCSP-C225",
        (False, False, 'aarch64'): "SSRCSP-C224",
    },
    'orin-nx': {
        (False, False, 'x86_64'): "SSRCSP-C221",
        (False, False, 'aarch64'): "SSRCSP-C220",
    },
    'darp11': {
        (True, True,   'x86_64'): "SSRCSP-C216",
        (True, False,  'x86_64'): "SSRCSP-C218",
        (False, True,  'x86_64'): "SSRCSP-C217",
        (False, False, 'x86_64'): "SSRCSP-C219",
    },
    'lenovo-x1':{
        (True, True,   'x86_64'): "SSRCSP-C213",
        (True, False,  'x86_64'): "SSRCSP-C214",
        (False, True,  'x86_64'): "SSRCSP-C212",
        (False, False, 'x86_64'): "SSRCSP-C226",
    }
}

class ZephyrListener:
    """Robot Framework listener for saving results to Jira Zephyr"""
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LISTENER_API_VERSION = 3

    def __init__(self):
        self.zephyr = Zephyr()

    def get_target(self):
        job_env_var = BuiltIn().get_variable_value("${JOB}")
        if not job_env_var:
            raise ValueError("JOB env variable is missing or empty")

        device_type_env_var = BuiltIn().get_variable_value("${DEVICE_TYPE}")
        if not device_type_env_var:
            raise ValueError("DEVICE_TYPE env variable is missing or empty")

        return self.parse_target(job_env_var, device_type_env_var)

    def get_test_cycle(self):
        """Getting test cycle for saving results"""
        target = self.get_target()
        device = target['device']
        secure_boot = target['secure boot']
        installer = target['installer']
        aarch = target['aarch']
        return target_to_cycle_map[device][(installer, secure_boot, aarch)]

    def find_zephyr_tag(self, tags):
        """Getting test tag from tags section"""
        for tag in tags:
            if tag.startswith('SP-T'):
                return "SSRC"+tag

    def end_test(self, test: TestCase, result: TestResult):
        """Code executed after each test to save its result to Zephyr"""
        if self.zephyr.connected:
            zephyr_tag = self.find_zephyr_tag(result.tags)
            status = robot_status_to_zephyr[result.status]
            test_cycle = self.get_test_cycle()
            if test_cycle and zephyr_tag:
                logger.info(
                    f"Saving test results to Zephyr.\n Test name: {test.name}\n Test tag: {zephyr_tag}\n Test Cycle: {test_cycle}\n")
                self.zephyr.create_test_result(test_run_key=test_cycle, test_case_key=zephyr_tag, status=status, comment=result.message)
            else:
                logger.error(f"Failed to save test results to Zephyr.\n Test name: {test.name}\n Test tag: {zephyr_tag}\n Test Cycle: {test_cycle}\n")

    def parse_device(self, device_type):
        if 'darter' in device_type:
            return 'darp11'

        if ('lenovo-x1' in device_type) or ('x1-sec-boot' in device_type):
            return 'lenovo-x1'

        if 'orin-nx' in device_type:
            return 'orin-nx'

        if 'orin-agx' in device_type:
            return 'orin-agx'

        if 'agx-64' in device_type:
            return 'orin-agx64'

    def parse_target(self, job_target, device_type):
        structured_target = {
            'device': self.parse_device(device_type),
            'secure boot': 'sec-boot' in device_type,
            'installer': True if 'installer' in job_target else False,
            'aarch': 'aarch64' if 'aarch64' in job_target else 'x86_64'
        }

        return structured_target
