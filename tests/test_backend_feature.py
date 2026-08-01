import unittest

from backend_feature import AnalysisStore, FeatureAnalyzer


class FeatureAnalyzerTests(unittest.TestCase):
    def test_analyzer_returns_metrics_and_suggestions(self):
        analyzer = FeatureAnalyzer(store=None)
        result = analyzer.analyze("int x;\nif (x > 0) {\n  print x;\n}\n")

        self.assertGreater(result["line_count"], 0)
        self.assertGreater(result["keyword_count"], 0)
        self.assertIn("complexity_score", result)
        self.assertTrue(result["suggestions"])

    def test_store_keeps_recent_history(self):
        store = AnalysisStore(max_items=2)
        analyzer = FeatureAnalyzer(store=store)

        analyzer.analyze("int x;")
        analyzer.analyze("float y;")
        analyzer.analyze("bool z;")

        self.assertEqual(len(store.history()), 2)
        self.assertEqual(store.history()[-1]["label"], "analysis-2")


if __name__ == "__main__":
    unittest.main()
