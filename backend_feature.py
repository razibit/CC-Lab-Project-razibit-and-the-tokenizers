import re
from typing import Any, Dict, List, Optional


class AnalysisStore:
    def __init__(self, max_items: int = 10):
        self._max_items = max_items
        self._entries: List[Dict[str, Any]] = []

    def add(self, payload: Dict[str, Any]) -> None:
        self._entries.append(payload)
        if len(self._entries) > self._max_items:
            self._entries = self._entries[-self._max_items :]

    def history(self) -> List[Dict[str, Any]]:
        return list(self._entries)


class FeatureAnalyzer:
    def __init__(self, store: Optional[AnalysisStore] = None):
        self.store = store or AnalysisStore()

    def analyze(self, source_code: str) -> Dict[str, Any]:
        line_count = max(1, len(source_code.splitlines()))
        keyword_count = len(re.findall(r"\b(int|float|bool|if|else|while|print|true|false)\b", source_code))
        identifier_count = len(re.findall(r"\b[a-zA-Z_][a-zA-Z0-9_]*\b", source_code))
        complexity_score = min(100, (line_count * 3) + (keyword_count * 2) + (identifier_count // 2))

        suggestions = []
        if keyword_count > 3:
            suggestions.append("Consider grouping related declarations")
        if line_count > 8:
            suggestions.append("Break long sections into smaller blocks")
        if complexity_score > 40:
            suggestions.append("Refactor complex logic for readability")

        result = {
            "line_count": line_count,
            "keyword_count": keyword_count,
            "identifier_count": identifier_count,
            "complexity_score": complexity_score,
            "suggestions": suggestions,
            "label": f"analysis-{len(self.store.history()) + 1}",
        }

        self.store.add(result)
        return result
