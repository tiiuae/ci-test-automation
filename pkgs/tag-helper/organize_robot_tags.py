import pathlib
import re

TAGS_RE = re.compile(r"^(\s*(?:\[Tags\]|Test Tags)\s+)(.+)$")

TAG_PRIORITY = ["pre-merge", "bat", "regression",   # Test set tags from smallest to biggest
                "gui", "performance", "security", "suspension", "update",  # Test suite tags in an alphabetical order (there should be only one of these for each test)
                "lenovo-x1", "darter-pro", "dell-7330", "orin-agx", "orin-agx-64", "orin-nx", # Device tags
                "lab-only", "fmo"]  # Other important tags


def sort_key(tag: str):
    # Ignore leading dash when sorting
    return tag.lstrip("-")


def tag_priority(tag):
    normalized = sort_key(tag)
    if "SP-T" in normalized:
        return (0, normalized)
    elif normalized in TAG_PRIORITY:
        return (2, TAG_PRIORITY.index(normalized))
    else:
        return (1, normalized)


def process_file(path):
    changed = False
    lines = path.read_text().splitlines()

    for i, line in enumerate(lines):
        match = TAGS_RE.match(line)
        if not match:
            continue

        prefix, tag_str = match.groups()
        tags = tag_str.split()
        ordered = sorted(tags, key=tag_priority)

        if tags != ordered:
            lines[i] = prefix + "  ".join(ordered)
            changed = True

    if changed:
        path.write_text("\n".join(lines) + "\n")
        print(f"Updated: {path}")


def main(root="."):
    for path in pathlib.Path(root).rglob("*.robot"):
        process_file(path)


if __name__ == "__main__":
    main()
