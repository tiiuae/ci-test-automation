# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Mask generated exports at their output boundary; raw downloads stay separate."""

from hashlib import sha256
import json
import logging
import os
import re
from urllib.parse import unquote_plus


SECRET_LABEL = re.compile(
    r"(?:^|[_-])(?:password|passwd|passw0rd|passw|passphrase|sshpass|"
    r"secret(?:[_-]?key)?|pw|pwd|pass|token|api[_-]?key|authorization)$", re.I
)
# The boundary prevents retries inside a long word when no :// follows it.
URL = re.compile(r"(?<![\w.+-])([A-Za-z][A-Za-z0-9+.-]*://)[^\s<>\"']*")
URL_PARAMETER = re.compile(r"(?:^|&)([^=&]+)=([^&]*)")
GITHUB_TOKEN = re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b")
MAX_REDACTION_CHARS = 2 * 1024 * 1024


def redact_url(match):
    """Mask standard URL userinfo and explicit query/fragment credential fields."""
    text = match.group()
    authority = len(match[1])
    netloc = re.split(r"[/?#]", text[authority:], maxsplit=1)[0]
    spans = []
    at = netloc.rfind("@")
    if at >= 0:
        spans.append((authority, authority + at))
    fragment = text.find("#", authority)
    query = text.find("?", authority)
    components = []
    if query >= 0 and (fragment < 0 or query < fragment):
        components.append((query + 1, fragment if fragment >= 0 else len(text)))
    if fragment >= 0:
        components.append((fragment + 1, len(text)))
    for start, end in components:
        for pair in URL_PARAMETER.finditer(text[start:end]):
            if SECRET_LABEL.search(unquote_plus(pair[1])):
                spans.append((start + pair.start(2), start + pair.end(2)))
    parts = []
    cursor = 0
    for start, end in spans:
        parts.extend((text[cursor:start], "[redacted]"))
        cursor = end
    parts.append(text[cursor:])
    return "".join(parts)


def redact(text, location="text"):
    if len(text) > MAX_REDACTION_CHARS:
        message = f"{len(text)} characters exceed masking limit at {location}"
        logging.getLogger(__name__).warning("Omitted masking input: %s", message)
        return f"[redacted: {message}]"
    for name in ("JENKINS_API_TOKEN", "JIRA_TOKEN"):
        secret = os.environ.get(name)
        if secret:
            text = text.replace(secret, "[redacted]")
    return GITHUB_TOKEN.sub("[redacted]", URL.sub(redact_url, text))


def redact_data(value, location="$"):
    """Mask exports recursively while retaining container order and string types."""
    if isinstance(value, str):
        return type(value)(redact(str(value), location))
    if isinstance(value, (list, tuple, set, frozenset)):
        items = [redact_data(item, f"{location}[{index}]") for index, item in enumerate(value)]
        if isinstance(value, list):
            value[:] = items
            return value
        return type(value)(items)
    if isinstance(value, dict):
        masked = {}
        for index, (key, item) in enumerate(value.items()):
            sensitive = SECRET_LABEL.search(key) if isinstance(key, str) else False
            # PASS is also the Robot result counter.
            if key == "PASS" and isinstance(item, (int, float)):
                sensitive = False
            masked_key = redact_data(key, f"{location}.keys[{index}]")
            if masked_key in masked:
                base, suffix = masked_key, 2
                while masked_key in masked or masked_key in value:
                    masked_key = f"{base}#{suffix}"
                    suffix += 1
            field = (f"{location}.{masked_key}"
                     if isinstance(masked_key, str) and masked_key.isidentifier() and len(masked_key) <= 80
                     else f"{location}.values[{index}]")
            masked[masked_key] = (
                "[redacted]" if sensitive and item is not None else redact_data(item, field)
            )
        value.clear()
        value.update(masked)
    return value


def json_text(value):
    return json.dumps(redact_data(value), indent=2, ensure_ascii=False) + "\n"


def write_json(path, value, max_bytes=None):
    content = json_text(value).encode("utf-8")
    if max_bytes is not None and len(content) > max_bytes:
        raise ValueError("Normalized JSON export exceeds its size limit")
    path.write_bytes(content)


def write_html(path, template, context):
    # Mask before HTML escaping so quoted credentials remain recognizable.
    path.write_text(template.render(redact_data(context)) + "\n", encoding="utf-8")


def print_text(text, **kwargs):
    print(redact(text), **kwargs)


def save_evidence(output, text):
    content = redact(text).encode("utf-8")
    if len(content) > 2 * 1024 * 1024:
        raise ValueError("Redacted supplementary evidence exceeds 2 MiB")
    digest = sha256(content).hexdigest()
    relative = "investigation-evidence/" + digest + ".txt"
    path = output / relative
    path.parent.mkdir(exist_ok=True)
    if not path.resolve().is_relative_to(output.resolve()):
        raise ValueError("Saved supplementary evidence must stay inside the output directory")
    if path.exists():
        if path.is_symlink() or path.read_bytes() != content:
            raise ValueError("Saved supplementary evidence conflicts with its digest")
    else:
        path.write_bytes(content)
    return relative, digest
