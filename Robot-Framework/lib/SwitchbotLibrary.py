# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import time
import hmac
import hashlib
import base64
import requests
import uuid

class SwitchbotLibrary:
    def __init__(self, token, secret):
        self.token = token
        self.secret = secret
        self.base_url = 'https://api.switch-bot.com/v1.1/devices'
        self.signature, self.timestamp, self.nonce = self.generate_signature()
        self.device_id = ''

    def generate_signature(self):
        nonce = str(uuid.uuid4())
        timestamp = int(round(time.time() * 1000))
        message = f'{self.token}{timestamp}{nonce}'.encode('utf-8')
        secret_enc = self.secret.encode('utf-8')
        signature = base64.b64encode(hmac.new(secret_enc, msg=message, digestmod=hashlib.sha256).digest()).decode('utf-8')
        return signature, timestamp, nonce

    def get_devices(self):
        headers = {
            'Authorization': self.token,
            'sign': self.signature,
            'nonce': self.nonce,
            't': str(self.timestamp),
            'Content-Type': 'application/json',
        }
        response = requests.get(self.base_url, headers=headers)
        print(response.json())
        return response.json()

    def get_device_id(self, device_name):
        devices_data = self.get_devices()
        if 'body' in devices_data and 'deviceList' in devices_data['body']:
            for device in devices_data['body']['deviceList']:
                if device['deviceName'] == device_name:
                    return device['deviceId']
        return None

    def send_command(self, command):
        headers = {
            'Authorization': self.token,
            'sign': self.signature,
            'nonce': self.nonce,
            't': str(self.timestamp),
            'Content-Type': 'application/json',
        }
        url = f'{self.base_url}/{self.device_id}/commands'
        response = requests.post(url, headers=headers, json=command)
        print(response.json())
        assert response.json()['message'] == 'success'

    def press_button(self, device_name):
        self.device_id = self.get_device_id(device_name)
        command = {
            "command": "press",
            "parameter": "default",
            "commandType": "command"
        }
        return self.send_command(command)
