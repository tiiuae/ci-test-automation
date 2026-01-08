# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from setuptools import setup

setup(
    name="KMTronic",
    license="Apache-2.0",
    python_requires=">=3.8",
    install_requires=[
        "pyserial",
    ],
    py_modules=["kmtronic_4ch_status", "kmtronic_4ch_control"],
    entry_points={
        "console_scripts": [
            "kmtronic-status=kmtronic_4ch_status:main",
            "kmtronic-control=kmtronic_4ch_control:main",
        ]
    },
)
