# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import os
import requests
from robot.api import logger
from http import HTTPStatus

class ZephyrError(Exception):
    pass

class ZephyrTestStatuses:
    """Container for supported Zephyr Scale Plugin test statuses"""
    NOT_EXECUTED = 'Not Executed'
    IN_PROGRESS = 'In Progress'
    PASS = 'Pass'
    FAIL = 'Fail'
    BLOCKED = 'Blocked'

class Zephyr:
    """Class for integration with Zephyr Scale Plugin"""
    connected: bool
    zephyr_api: str
    project_key: str
    test_statuses = ZephyrTestStatuses

    def __init__(self, project_key="SSRCSP"):
        """ Initialize Zephyr Scale API client."""
        self.token = os.getenv("JIRA_TOKEN")
        self.jira_link = os.getenv("JIRA_LINK")

        self.zephyr_api = f"{self.jira_link}/rest/atm/1.0"
        self.project_key = project_key
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        self.session = requests.Session()
        self.session.headers.update(headers)
        self.session.verify = False

        self.check_connection()

    def check_connection(self):
        """Check connection to Zephyr Scale."""
        try:
            if not self.jira_link:
                raise ZephyrError("No jira link found")

            if not self.token:
                raise ZephyrError("No token found")

            self.get_testcases(query=f'projectKey = "{self.project_key}"', maxResults=1 )
            logger.console("Successfully connected to Zephyr")
            self.connected = True

        except Exception as exc:
            logger.warn(f"Failed to connect to Zephyr!\n Trying to do test request, but failed with an error:\n {exc}")
            self.connected = False

    def check_http_status(self, resp, error_message, *expected_statuses):
        """Validate HTTP response status code."""
        if resp.status_code not in expected_statuses:
            raise ZephyrError(f"{error_message}\nHTTP Status Code: {resp.status_code} {resp.text}")

    def get_testcases(self, query, maxResults=200, startAt=0):
        """
        Search Zephyr Scale test cases.

        Further description of query parameter copied from
            https://support.smartbear.com/zephyr-scale-server/api-docs/v1/, /testcase/search GET section

        query: A query to filter Test Cases. The query syntax is similar to the JIRA JQL.

        Available fields: projectKey, key, name, status, priority, component, folder, estimatedTime, labels, owner and
            custom fields. When filtering by custom fields, the field name must be quoted.
        Available operators: =, >, >=, <, <=, IN
        For Single and Multi Choice custom fields, operator "=" is not supported, use "IN" instead
        Available logical operators: AND
        """
        url = f"{self.zephyr_api}/testcase/search"

        payload = {
            "query": query,
            "maxResults": maxResults,
            "startAt": startAt
        }
        resp = self.session.get(url=url, params=payload)
        self.check_http_status(resp, f"Failed to find test cases.\n Query: {query}", HTTPStatus.OK)

        return resp.json()

    def create_test_result(
            self,
            test_run_key: str,
            test_case_key: str,
            status: str,
            comment = ""
    ):
        """
        Create a test result for a test case inside a test cycle.

        POST /testrun/{run}/testcase/{case}/testresult

        test_run_key == test_cycle_key: Zephyr API uses 'test run' naming in the URL, but in the GUI it's 'test cycle'.
        """

        url = f"{self.zephyr_api}/testrun/{test_run_key}/testcase/{test_case_key}/testresult"

        payload = {
            "status": status,
            "comment": comment
        }

        resp = self.session.post(url=url, json=payload)
        self.check_http_status(resp,
                               f"Failed to create test result.\n"
                               f" Test Cycle: {test_run_key}\n"
                               f" Test Case: {test_case_key}\n"
                               f" Status: {status}\n",
                               HTTPStatus.CREATED, HTTPStatus.OK)

        return resp.json()
