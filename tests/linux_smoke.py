#!/usr/bin/env python3
"""Linux lifecycle smoke for a Python container; no network or host writes required."""
import unittest
from test_agents import AgentsTest

names = [
    'test_codex_only_and_idempotent_upgrade',
    'test_both_identical_and_sibling_references_resolve',
    'test_shell_install_upgrade_uninstall',
    'test_temporary_bootstrap_uninstall_and_version_identity',
]
result = unittest.TextTestRunner(verbosity=2).run(unittest.TestSuite(AgentsTest(name) for name in names))
raise SystemExit(0 if result.wasSuccessful() else 1)
