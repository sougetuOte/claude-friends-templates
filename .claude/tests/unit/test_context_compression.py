#!/usr/bin/env python3
"""
Context Compression Tests
TDD Red Phase: テストファースト実装
コンテキスト圧縮機能のテストケース
"""

import json
import base64
import unittest
from pathlib import Path
import sys

# Add parent directory to path
# test_context_compression.py is in .claude/tests/unit/
# handover-generator.py is in .claude/scripts/
scripts_path = Path(__file__).parent.parent.parent / "scripts"
sys.path.insert(0, str(scripts_path))

# Import the module with hyphen in name
import importlib.util

spec = importlib.util.spec_from_file_location(
    "handover_generator", scripts_path / "handover-generator.py"
)
handover_generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(handover_generator)
HandoverGenerator = handover_generator.HandoverGenerator


class TestContextCompression(unittest.TestCase):
    """Context compression functionality tests"""

    def setUp(self):
        """Set up test environment"""
        self.generator = HandoverGenerator()
        self.test_context = {
            "tasks": [f"Task {i}" for i in range(100)],
            "activities": ["Activity " * 50 for _ in range(50)],
            "notes": "This is a very long context " * 100,
            "metadata": {
                "timestamp": "2025-09-29T10:00:00Z",
                "agent": "builder",
                "project": "test-project",
            },
        }

    def test_compress_context_reduces_size(self):
        """Test that context compression reduces data size significantly"""
        original_json = json.dumps(self.test_context)
        original_size = len(original_json.encode())

        # Method to be implemented
        compressed = self.generator.compress_context(self.test_context)

        self.assertIsNotNone(compressed)
        self.assertIn("compressed_data", compressed)
        self.assertIn("original_size", compressed)
        self.assertIn("compressed_size", compressed)
        self.assertIn("compression_ratio", compressed)

        # Verify significant size reduction (at least 50% compression)
        ratio = compressed["compression_ratio"]
        self.assertGreaterEqual(ratio, 0.5, "Compression ratio should be at least 50%")

    def test_decompress_context_restores_original(self):
        """Test that decompression restores original context exactly"""
        compressed = self.generator.compress_context(self.test_context)
        decompressed = self.generator.decompress_context(compressed["compressed_data"])

        self.assertEqual(decompressed, self.test_context)

    def test_compress_handles_empty_context(self):
        """Test compression of empty context"""
        empty_context = {}
        compressed = self.generator.compress_context(empty_context)

        self.assertIsNotNone(compressed)
        self.assertIn("compressed_data", compressed)

        # Verify decompression works
        decompressed = self.generator.decompress_context(compressed["compressed_data"])
        self.assertEqual(decompressed, empty_context)

    def test_compress_handles_large_context(self):
        """Test compression of very large context (> 1MB)"""
        large_context = {
            "huge_data": "x" * (1024 * 1024),  # 1MB of data
            "arrays": [[i for i in range(1000)] for _ in range(100)],
        }

        compressed = self.generator.compress_context(large_context)

        # Should achieve good compression on repetitive data
        self.assertIn("compression_ratio", compressed)
        self.assertGreaterEqual(
            compressed["compression_ratio"],
            0.9,
            "Large repetitive data should compress well",
        )

    def test_compress_preserves_special_characters(self):
        """Test that special characters are preserved through compression"""
        special_context = {
            "unicode": "こんにちは世界 🌍",
            "symbols": "!@#$%^&*()",
            "quotes": 'He said "Hello"',
            "newlines": "Line1\nLine2\rLine3\r\nLine4",
        }

        compressed = self.generator.compress_context(special_context)
        decompressed = self.generator.decompress_context(compressed["compressed_data"])

        self.assertEqual(decompressed, special_context)

    def test_compress_with_compression_level(self):
        """Test different compression levels"""
        # Test maximum compression
        compressed_max = self.generator.compress_context(
            self.test_context, compression_level=9
        )

        # Test fastest compression
        compressed_fast = self.generator.compress_context(
            self.test_context, compression_level=1
        )

        # Maximum compression should be smaller or equal
        self.assertLessEqual(
            compressed_max["compressed_size"], compressed_fast["compressed_size"]
        )

    def test_compress_context_metadata_included(self):
        """Test that compression metadata is properly included"""
        compressed = self.generator.compress_context(self.test_context)

        self.assertIn("algorithm", compressed)
        self.assertIn("timestamp", compressed)
        self.assertEqual(compressed["algorithm"], "gzip")

    def test_compress_handles_binary_data(self):
        """Test compression of context containing binary data"""
        binary_context = {
            "text": "Regular text",
            "binary": base64.b64encode(b"\x00\x01\x02\x03").decode(),
            "mixed": ["text", 123, {"nested": True}],
        }

        compressed = self.generator.compress_context(binary_context)
        decompressed = self.generator.decompress_context(compressed["compressed_data"])

        self.assertEqual(decompressed, binary_context)

    def test_compress_error_handling(self):
        """Test error handling for invalid input"""

        # Non-serializable object
        class CustomObject:
            pass

        invalid_context = {"object": CustomObject()}

        with self.assertRaises(TypeError):
            self.generator.compress_context(invalid_context)

    def test_decompress_error_handling(self):
        """Test error handling for invalid compressed data"""
        # Invalid base64 data
        with self.assertRaises(Exception):
            self.generator.decompress_context("invalid_base64_data")

        # Invalid gzip data
        valid_base64_invalid_gzip = base64.b64encode(b"not gzip data").decode()
        with self.assertRaises(Exception):
            self.generator.decompress_context(valid_base64_invalid_gzip)

    def test_compress_context_integration_with_handover(self):
        """Test integration with handover document generation"""
        # Create a handover with large context
        large_context = "Very detailed context information " * 1000

        handover = self.generator.create_handover_document(
            from_agent="planner",
            to_agent="builder",
            context=large_context,
            compress_large_context=True,  # New parameter
        )

        self.assertIn("context", handover)

        # If context is large, it should be compressed
        if "compressed_context" in handover:
            self.assertIn("compressed_data", handover["compressed_context"])
            # Verify it can be decompressed
            decompressed = self.generator.decompress_context(
                handover["compressed_context"]["compressed_data"]
            )
            # When string context is compressed, it's wrapped in a dict
            # So we need to extract the original context from the dict
            if isinstance(decompressed, dict) and "context" in decompressed:
                self.assertEqual(decompressed["context"], large_context)
            else:
                self.assertEqual(decompressed, large_context)

    def test_selective_compression(self):
        """Test selective compression of specific fields"""
        context = {
            "small_data": "small",
            "large_data": "large" * 10000,
            "metadata": {"keep": "uncompressed"},
        }

        # Compress only large fields
        compressed = self.generator.compress_context(
            context, compress_fields=["large_data"]
        )

        self.assertIn("compressed_fields", compressed)
        self.assertIn("large_data", compressed["compressed_fields"])
        self.assertEqual(compressed["small_data"], "small")
        self.assertEqual(compressed["metadata"], {"keep": "uncompressed"})


if __name__ == "__main__":
    unittest.main()
