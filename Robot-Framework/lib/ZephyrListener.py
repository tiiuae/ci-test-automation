# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from html import escape
from Zephyr import Zephyr, ZephyrTestStatuses
from robot.running import TestCase
from robot.result import TestCase as TestResult
from robot.result import Keyword as KeywordResult
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
                logger.debug(
                    f"Saving test results to Zephyr.\n Test name: {test.name}\n Test tag: {zephyr_tag}\n Test Cycle: {test_cycle}\n")
                self.zephyr.create_test_result(test_run_key=test_cycle, test_case_key=zephyr_tag, status=status, comment=self.get_message_for_result(result))
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

    def get_message_for_result(self, result: TestResult):
        """Format the result message and log link as HTML for Zephyr."""
        log_link = self.get_link_in_log(result)
        # saving message and link "as is" will form just a oneline text, so replacing \n with <br> and adding <a> to make link clickable
        message = '<br>'.join(escape(result.message).splitlines())
        link = f'<a href="{escape(log_link, quote=True)}" target="_blank" rel="noopener noreferrer">Link to the test</a>'
        message_for_result = f"{link}<br><br>{message}"
        return message_for_result

    def get_link_in_log(self, result: TestResult):
        """Return the Jenkins artifact URL pointing to this test or its failure."""
        build_id = BuiltIn().get_variable_value("${BUILD_ID}")
        if not build_id:
            logger.warn("Cannot create HTML log link: BUILD_ID Robot variable is missing or empty")
            return None
        return (
            f"https://ci-prod.vedenemo.dev/job/ghaf-hw-test/{build_id}/artifact/"
            f"Robot-Framework/test-suites/regression/log.html{self.get_log_anchor(result)}"
        )

    def get_log_anchor(self, result: TestResult):
        """Return the failed keyword's log anchor, falling back to the test."""
        target_id = result.id
        if result.status == 'FAIL':
            target_id = self.get_failed_keyword_id(result) or target_id
        return f"#{target_id}"

    def get_failed_keyword_id(self, result):
        """Return the first innermost failed keyword's HTML log anchor.

        Walk the final result in execution order, skipping successful subtrees
        so that handled failures do not become the reported failure location.
        """
        if getattr(result, 'status', None) != 'FAIL':
            return None
        children = []
        if getattr(result, 'has_setup', False):
            children.append(result.setup)
        children.extend(getattr(result, 'body', ()))
        children.extend(getattr(result, 'branches', ()))
        if getattr(result, 'has_teardown', False):
            children.append(result.teardown)
        for child in children:
            keyword_id = self.get_failed_keyword_id(child)
            if keyword_id:
                return keyword_id
        if isinstance(result, KeywordResult):
            return result.id
        return None
