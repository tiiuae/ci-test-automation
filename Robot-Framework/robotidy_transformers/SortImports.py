"""Robotidy transformer that alphabetizes settings imports by type."""

from robotidy.transformers import Transformer


class SortImports(Transformer):
    """Sort Library, Resource, and Variables settings by their import name."""

    IMPORT_TYPES = {"LIBRARY", "RESOURCE", "VARIABLES"}

    def visit_SettingSection(self, node):
        for import_type in self.IMPORT_TYPES:
            imports = [
                setting for setting in node.body if setting.type == import_type
            ]
            if len(imports) < 2:
                continue
            sorted_imports = iter(
                sorted(imports, key=lambda setting: setting.name.casefold())
            )
            node.body = [
                next(sorted_imports) if setting.type == import_type else setting
                for setting in node.body
            ]
        return node
