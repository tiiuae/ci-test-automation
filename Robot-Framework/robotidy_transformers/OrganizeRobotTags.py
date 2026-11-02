"""Robotidy transformer that applies the repository's tag ordering."""

from robot.api import Token
from robotidy.transformers import Transformer


TAG_PRIORITY = [
    "pre-merge", "bat", "regression",  # Test set tags from smallest to biggest
    "functional", "gui", "performance", "security", "suspension", "update",  # Test suite tags
    "lenovo-x1", "darter-pro", "dell-7330", "orin-agx", "orin-agx-64", "orin-nx",  # Device tags
    "installer-only", "excl-installer", "storeDisk-only", "excl-storeDisk", "secboot-only", "excl-secboot",  # Image type tags
    "lab-only", "fmo",  # Other important tags
]


def tag_priority(tag: str):
    normalized = tag.lstrip("-")
    if "SP-T" in normalized:
        return (0, normalized)
    if normalized in TAG_PRIORITY:
        return (2, TAG_PRIORITY.index(normalized))
    return (1, normalized)


class OrganizeRobotTags(Transformer):
    """Sort suite and test tags using the repository's tag priority rules."""

    @staticmethod
    def sort_setting_tags(setting):
        tag_tokens = [
            (index, token)
            for index, token in enumerate(setting.tokens)
            if token.type == Token.ARGUMENT
        ]
        sorted_values = sorted((token.value for _, token in tag_tokens), key=tag_priority)
        tokens = list(setting.tokens)
        for (index, token), value in zip(tag_tokens, sorted_values):
            tokens[index] = Token(
                token.type,
                value,
                token.lineno,
                token.col_offset,
                token.end_col_offset,
            )
        setting.tokens = tuple(tokens)

    def visit_SettingSection(self, node):
        for setting in node.body:
            setting_type = getattr(setting, "type", "")
            if setting_type.replace("_", "").replace(" ", "") == "TESTTAGS":
                self.sort_setting_tags(setting)
        return node

    def visit_TestCase(self, node):
        for setting in node.body:
            if getattr(setting, "type", None) == "TAGS":
                self.sort_setting_tags(setting)
        return node
