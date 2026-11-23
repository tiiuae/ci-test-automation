#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Read bounded original Robot messages for one test, without executing tests."""

import argparse
import json
from pathlib import Path
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET

from ai_investigation import cases

from report_output import json_text, redact, redact_data


def read_context(
    path,
    test_id,
    keyword="",
    contains="",
    max_messages=12,
    max_lines=100,
    max_chars=18000,
):
    stack = []
    selected = False
    found = False
    output = {"test_id": test_id, "messages": [], "truncated": False}
    line_budget, char_budget = max_lines, max_chars
    for action, element in ET.iterparse(path, events=("start", "end")):
        if action == "start":
            stack.append((element.tag, element.get("name", "")))
            if element.tag == "test":
                selected = element.get("id") == test_id
                found = found or selected
            continue
        if selected and element.tag == "msg":
            context = [name for tag, name in stack if tag == "kw"]
            text = redact(element.text or "")
            if (
                not keyword or any(keyword.lower() in name.lower() for name in context)
            ) and (not contains or contains.lower() in text.lower()):
                lines = text.splitlines()
                indexes = set()
                for index, line in enumerate(lines):
                    if not contains or contains.lower() in line.lower():
                        indexes.update(
                            range(max(0, index - 2), min(len(lines), index + 3))
                        )
                result = []
                for index in sorted(indexes):
                    if line_budget <= 0 or char_budget <= 0:
                        output["truncated"] = True
                        break
                    line = lines[index]
                    offset = (
                        max(0, line.lower().find(contains.lower()) - 200)
                        if contains
                        else 0
                    )
                    excerpt = line[offset : offset + min(1600, char_budget)]
                    result.append(
                        {"line": index + 1, "character_offset": offset, "text": excerpt}
                    )
                    output["truncated"] = (
                        output["truncated"] or offset > 0 or len(excerpt) < len(line)
                    )
                    line_budget -= 1
                    char_budget -= len(excerpt)
                output["messages"].append(
                    {
                        "time": element.get("time", element.get("timestamp", "")),
                        "level": element.get("level"),
                        "context": context,
                        "lines": result,
                    }
                )
                if (
                    len(output["messages"]) >= max_messages
                    or line_budget <= 0
                    or char_budget <= 0
                ):
                    output["truncated"] = True
                    break
        if element.tag == "test" and selected:
            break
        stack.pop()
        element.clear()
    if not found:
        raise ValueError(f"Test ID not found in XML: {test_id}")
    return redact_data(output)


def case_context(output, case_id):
    """Resolve raw context internally; packets contain only portable case IDs."""
    report = json.loads((output / "analysis.json").read_text())
    for cid, _, _, phase, test in cases(report):
        if cid == case_id:
            base = unquote(urlsplit(report["source_url"]).path)
            path = unquote(urlsplit(phase["xml_url"]).path)
            if not path.startswith(base):
                raise ValueError("Case XML is outside the selected source")
            cache = (output / "cache").resolve()
            xml = (cache / path[len(base):]).resolve()
            if not xml.is_relative_to(cache):
                raise ValueError("Case XML is outside the cache")
            return xml, test["id"]
    raise ValueError("Unknown case ID")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xml", type=Path, nargs="?")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--case-id")
    parser.add_argument("--test-id")
    parser.add_argument("--keyword", default="")
    parser.add_argument("--contains", default="")
    parser.add_argument("--max-messages", type=int, default=12)
    parser.add_argument("--max-lines", type=int, default=100)
    parser.add_argument("--max-chars", type=int, default=18000)
    args = parser.parse_args()
    if min(args.max_messages, args.max_lines, args.max_chars) < 1:
        parser.error("Output limits must be positive")
    packet_mode = args.output and args.case_id and not (args.xml or args.test_id)
    xml_mode = args.xml and args.test_id and not (args.output or args.case_id)
    if not (packet_mode or xml_mode):
        parser.error("Use --output with --case-id, or XML with --test-id")
    try:
        if args.output:
            args.xml, args.test_id = case_context(args.output, args.case_id)
        if args.xml.stat().st_size > 1024**3:
            parser.error("XML exceeds the helper's 1 GiB limit")
        result = read_context(
            args.xml,
            args.test_id,
            args.keyword,
            args.contains,
            args.max_messages,
            args.max_lines,
            args.max_chars,
        )
    except (OSError, ValueError, KeyError, TypeError, ET.ParseError) as error:
        parser.error(redact(str(error)))
    print(json_text(result), end="")


if __name__ == "__main__":
    main()
