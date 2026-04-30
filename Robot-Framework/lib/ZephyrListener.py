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

target_to_cycle_map = {
    'orin-agx': "SSRCSP-C184",
    'orin-agx-64': "SSRCSP-C185",
    'orin-nx': "SSRCSP-C186",
    'lenovo-x1': "SSRCSP-C187",
    'dell-7330': "SSRCSP-C188",
    'darter-pro': "SSRCSP-C189",
    'x1-sec-boot': "SSRCSP-C190",
}


class ZephyrListener:
    """Robot Framework listener for saving results to Jira Zephyr"""
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LISTENER_API_VERSION = 3

    def __init__(self):
        self.zephyr = Zephyr()

    def get_test_cycle(self):
        """Getting test cycle for saving results"""
        device_type = BuiltIn().get_variable_value("${DEVICE_TYPE}")
        return target_to_cycle_map[device_type]

    def find_zephyr_tag(self, tags):
        """Getting test tag from tags section"""
        for tag in tags:
            if tag.startswith('SP-T'):
                return "SSRCSP-T114"  #PLACEHOLDER!
                return tag

    def end_test(self, test: TestCase, result: TestResult):
        """Code executed after each test to save its result to Zephyr"""
        if self.zephyr.connected:
            zephyr_tag = self.find_zephyr_tag(result.tags)
            status = robot_status_to_zephyr[result.status]
            test_cycle = self.get_test_cycle()
            if test_cycle and zephyr_tag:
                self.zephyr.create_test_result(test_run_key=test_cycle, test_case_key=zephyr_tag, status=status, comment=result.message)
            else:
                logger.error(f"Failed to save test results to Zephyr.\n Test name: {test.name}\n Test tag: {zephyr_tag}\n Test Cycle: {test_cycle}\n")
        else:
            logger.error(f"Failed to save results to Zephyr: not connected")