# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import re
import os

# Labels to remove
labels_to_remove = ["lenovo-x1", "nuc", "orin-agx", "orin-nx", "riscv", "test:retry\(1\)"]

# JavaScript pattern to match the labels and their data
pattern = re.compile(r'\{"elapsed":"[^"]+","fail":\d+,"label":"(' + '|'.join(labels_to_remove) + r')","pass":\d+,"skip":\d+\},?')

files = ['report.html', 'log.html']

for file_name in files:
    path = os.path.join('Robot-Framework/test-suites', file_name)
    print(f'Editing file {os.path.abspath(path)}')

    # Read the HTML content
    with open(path, 'r') as f:
        content = f.read()

    # Function to replace the matched text
    def replace_func(match):
        # If the match is followed by a comma and a newline, remove the comma as well
        if match.group(0)[-1] == ',':
            return ""
        return ""

    # Replace the matched patterns with an empty string
    modified_content = pattern.sub(replace_func, content)

    # Save the modified HTML content back to the file
    with open(path, 'w') as f:
        f.write(modified_content)

    print(f'Modified file saved: {path}')
