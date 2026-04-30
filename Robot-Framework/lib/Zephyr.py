# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import os
import requests
from http import HTTPStatus

class ZephyrTestStatuses:
    NOT_EXECUTED = 'Not Executed'
    IN_PROGRESS = 'In Progress'
    PASS = 'Pass'
    FAIL = 'Fail'
    BLOCKED = 'Blocked'

class Zephyr:
    zephyr_api: str
    project_key: str
    headers: dict
    test_statuses = ZephyrTestStatuses


    def __init__(self, jira_link= "https://jira.tii.ae", project_key="SSRCSP"):
        self.zephyr_api = f"{jira_link}/rest/atm/1.0"
        self.project_key = project_key
        token = os.getenv("JIRA_TOKEN")

        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def create_test_result(
            self,
            test_run_key: str,
            test_case_key: str,
            status: str,
            comment = ""
    ):
        """
        POST /testrun/{run}/testcase/{case}/testresult

        test_run_key == test_cycle_key: Zephyr API uses 'test run' naming in the URL, but in the GUI it's 'test cycle'.
        """

        url = f"{self.zephyr_api}/testrun/{test_run_key}/testcase/{test_case_key}/testresult"

        payload = {
            "status": status,
            "comment": comment
        }

        resp = requests.post(
            url,
            headers=self.headers,
            json=payload,
            verify=False
        )

        if resp.status_code not in (HTTPStatus.OK, HTTPStatus.CREATED):
            raise Exception(f"Failed to create test result: {resp.status_code} {resp.text}")

        return resp.json()

    def get_test_result(self, result_id):
        url =  f"{self.zephyr_api}/testresult/{result_id}"
        resp = requests.get(
            url,
            headers=self.headers,
            verify=False
        )
        return resp



zeph = Zephyr()
print(zeph.headers)
# print(zeph.create_test_result(test_run_key='SSRCSP-C170', test_case_key='SSRCSP-T164', status=zeph.test_statuses.IN_PROGRESS))
print(zeph.create_test_result(test_run_key='SSRCSP-C170', test_case_key='SSRCSP-T114', status=zeph.test_statuses.IN_PROGRESS, comment="Test Comment!"))
print(zeph.get_test_result('SSRCSP-E6103'))