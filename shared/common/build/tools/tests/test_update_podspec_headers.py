"""Regression coverage for the Xcode post-build podspec header updater."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "update_podspec_headers.sh"
HEADERS = (
    "SalesforceFileLogger.h",
    "SFSDKFileLogger.h",
    "SFSDKLogFileManager.h",
    "SFSDKLogger.h",
)


class UpdatePodspecHeadersTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.script = self.root / "shared/common/build/tools/update_podspec_headers.sh"
        self.script.parent.mkdir(parents=True)
        shutil.copyfile(SCRIPT, self.script)
        self.headers_dir = self.root / "built/Headers"
        self.headers_dir.mkdir(parents=True)

    def run_updater(self, project_name, subspec):
        env = dict(os.environ)
        env.update(
            PROJECT_DIR=str(self.root / "libs" / project_name),
            PROJECT_NAME=project_name,
            TARGET_BUILD_DIR=str(self.root / "built"),
            PUBLIC_HEADERS_FOLDER_PATH="Headers",
        )
        return subprocess.run(
            ["bash", str(self.script), "-s", subspec],
            env=env,
            cwd=self.root,
            capture_output=True,
            text=True,
        )

    def test_filelogger_duplicate_forwarding_names_rewrite_canonical_paths(self):
        project = self.root / "libs/SalesforceFileLogger"
        source = project / "SalesforceFileLogger"
        for header in HEADERS:
            canonical = source / ("" if header == "SalesforceFileLogger.h" else "Classes/Logger") / header
            forwarding = source / "include/SalesforceFileLogger" / header
            for path in (canonical, forwarding, self.headers_dir / header):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("// header\n")

        podspec = self.root / "SalesforceFileLogger.podspec"
        podspec.write_text("  filelogger.public_header_files = 'stale'\n  filelogger.source_files = 'unchanged'\n")
        result = self.run_updater("SalesforceFileLogger", "filelogger")
        self.assertEqual(result.returncode, 0, result.stderr)
        expected_paths = [
            "libs/SalesforceFileLogger/SalesforceFileLogger/" +
            ("" if header == "SalesforceFileLogger.h" else "Classes/Logger/") + header
            for header in sorted(HEADERS)
        ]
        updated = podspec.read_text()
        self.assertTrue(updated.startswith("  filelogger.public_header_files = "), updated)
        header_line, source_line = updated.splitlines()
        self.assertEqual(set(header_line.split(" = ", 1)[1].split(", ")), {f"'{path}'" for path in expected_paths})
        self.assertEqual(source_line, "  filelogger.source_files = 'unchanged'")

    def test_filelogger_finds_new_public_header_in_another_source_subdirectory(self):
        project = self.root / "libs/SalesforceFileLogger"
        header = "SFSDKExtraLogger.h"
        canonical = project / "SalesforceFileLogger/Classes/Utilities" / header
        forwarding = project / "SalesforceFileLogger/include/SalesforceFileLogger" / header
        for path in (canonical, forwarding, self.headers_dir / header):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("// header\n")
        podspec = self.root / "SalesforceFileLogger.podspec"
        podspec.write_text("  filelogger.public_header_files = 'stale'\n")

        result = self.run_updater("SalesforceFileLogger", "filelogger")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            podspec.read_text(),
            "  filelogger.public_header_files = "
            "'libs/SalesforceFileLogger/SalesforceFileLogger/Classes/Utilities/SFSDKExtraLogger.h'\n",
        )

    def test_filelogger_fails_on_unmatched_public_header(self):
        header = "SFSDKMissingLogger.h"
        (self.headers_dir / header).write_text("// built header\n")
        podspec = self.root / "SalesforceFileLogger.podspec"
        original = "  filelogger.public_header_files = 'stale'\n"
        podspec.write_text(original)

        result = self.run_updater("SalesforceFileLogger", "filelogger")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(header, result.stderr)
        self.assertIn("no canonical", result.stderr)
        self.assertEqual(podspec.read_text(), original)

    def test_filelogger_fails_on_ambiguous_public_header(self):
        project = self.root / "libs/SalesforceFileLogger/SalesforceFileLogger"
        header = "SFSDKDuplicateLogger.h"
        for relative in ("Classes/Logger", "Classes/Utilities"):
            path = project / relative / header
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("// header\n")
        (self.headers_dir / header).write_text("// built header\n")
        podspec = self.root / "SalesforceFileLogger.podspec"
        original = "  filelogger.public_header_files = 'stale'\n"
        podspec.write_text(original)

        result = self.run_updater("SalesforceFileLogger", "filelogger")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(header, result.stderr)
        self.assertIn("multiple canonical", result.stderr)
        self.assertEqual(podspec.read_text(), original)

    def test_other_subspec_keeps_its_existing_header_discovery(self):
        project = self.root / "libs/Other"
        header = project / "Sources/Other.h"
        header.parent.mkdir(parents=True)
        header.write_text("// header\n")
        (self.headers_dir / "Other.h").write_text("// built header\n")
        podspec = self.root / "Other.podspec"
        podspec.write_text("  other.public_header_files = 'stale'\n")

        result = self.run_updater("Other", "other")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(podspec.read_text(), "  other.public_header_files = 'libs/Other/Sources/Other.h'\n")


if __name__ == "__main__":
    unittest.main()
