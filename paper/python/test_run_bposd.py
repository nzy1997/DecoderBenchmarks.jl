import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from importlib import metadata
from io import StringIO
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

from run_bposd import (
    BPOSD_LOGICAL_GRID,
    BPOSD_TIMING_GRID,
    load_paper_code,
    parse_arguments,
    run_bposd_point,
    run_seeded_worker,
    worker_seed,
)


class SeededBpOsdTests(unittest.TestCase):
    def test_worker_seed_is_stable(self):
        seed = worker_seed(20260607, 4, 0.01, 0)
        self.assertEqual(seed, worker_seed(20260607, 4, 0.01, 0))
        self.assertNotEqual(seed, worker_seed(20260607, 4, 0.01, 1))
        self.assertEqual(seed, 0xC758E02C76D5E043)

    def test_five_shot_fixture_is_deterministic(self):
        check_matrix = np.array(
            [
                [1, 1, 0, 0],
                [0, 0, 1, 1],
            ],
            dtype=np.uint8,
        )
        logicals = np.array(
            [
                [0, 0, 1, 0],
                [1, 0, 0, 0],
            ],
            dtype=np.uint8,
        )
        arguments = dict(
            check_matrix=check_matrix,
            logicals=logicals,
            distance=4,
            physical_error_rate=0.01,
            max_sim=5,
            max_error=5,
            base_seed=20260607,
            worker_index=0,
        )
        first = run_seeded_worker(**arguments)
        second = run_seeded_worker(**arguments)
        self.assertEqual(first["nsim"], 5)
        self.assertEqual(first["error_count"], 0)
        self.assertEqual(first["nsim"], second["nsim"])
        self.assertEqual(first["error_count"], second["error_count"])
        self.assertEqual(first["seed"], second["seed"])

        point = run_bposd_point(
            check_matrix=check_matrix,
            logicals=logicals,
            distance=4,
            physical_error_rate=0.01,
            max_sim=5,
            max_error=5,
            base_seed=20260607,
            workers=1,
        )
        self.assertEqual(point["decoder"], "BP-OSD")
        self.assertEqual(point["nsim"], 5)
        self.assertEqual(point["error_count"], 0)
        self.assertEqual(point["prior"], "matched_per_point")
        self.assertEqual(point["physical_error_rate"], 0.01)
        self.assertEqual(point["bp_method"], "product_sum")
        self.assertEqual(point["bp_schedule"], "serial")
        self.assertEqual(point["bp_max_iter"], 100)
        self.assertEqual(point["osd_method"], "OSD_0")
        self.assertEqual(point["osd_order"], 0)

    def test_curated_distance_four_code_derives_logicals(self):
        with tempfile.TemporaryDirectory() as temp:
            check_matrix, logicals = load_paper_code(4, temp)
        self.assertEqual(check_matrix.shape, (224, 448))
        self.assertEqual(logicals.shape, (12, 448))
        self.assertTrue(np.all((logicals == 0) | (logicals == 1)))

    def test_full_grids_match_the_paper_protocol(self):
        self.assertEqual(
            BPOSD_LOGICAL_GRID,
            [
                0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005, 0.008,
                0.01, 0.015, 0.02, 0.03, 0.04, 0.056, 0.06, 0.12, 0.15, 0.2,
            ],
        )
        self.assertEqual(
            BPOSD_TIMING_GRID,
            [0.01, 0.015, 0.02, 0.03, 0.04, 0.06, 0.12, 0.15, 0.2],
        )

    def test_invalid_cli_limits_and_probability_are_rejected(self):
        required = [
            "--mode", "smoke",
            "--distance", "4",
            "--output", "result.json",
        ]
        for invalid in (
            ["--max-sim", "0"],
            ["--max-error", "-1"],
            ["--workers", "0"],
            ["--physical-error-rate", "nan"],
            ["--physical-error-rate", "-0.01"],
            ["--physical-error-rate", "1.01"],
        ):
            with self.subTest(arguments=invalid):
                with redirect_stderr(StringIO()):
                    with self.assertRaises(SystemExit):
                        parse_arguments(required + invalid)

    def test_invalid_direct_point_limits_are_rejected(self):
        check_matrix = np.zeros((2, 4), dtype=np.uint8)
        logicals = np.zeros((2, 4), dtype=np.uint8)
        base = dict(
            check_matrix=check_matrix,
            logicals=logicals,
            distance=4,
            physical_error_rate=0.01,
            max_sim=5,
            max_error=5,
            base_seed=20260607,
            workers=1,
        )
        for field, value in (
            ("max_sim", 0),
            ("max_error", 0),
            ("workers", 0),
            ("physical_error_rate", float("nan")),
            ("physical_error_rate", -0.01),
            ("physical_error_rate", 1.01),
        ):
            with self.subTest(field=field, value=value):
                arguments = {**base, field: value}
                with self.assertRaises(ValueError):
                    run_bposd_point(**arguments)

    def test_decoder_environment_matches_lock(self):
        lock = (Path(__file__).resolve().parent / "requirements-lock.txt").read_text()
        for package, version in (
            ("ldpc", "2.3.6"),
            ("numpy", "2.3.1"),
            ("scipy", "1.16.0"),
            ("stim", "1.15.0"),
            ("pymatching", "2.2.2"),
        ):
            self.assertIn(f"{package}=={version}".lower(), lock.lower())
            self.assertEqual(metadata.version(package), version)


if __name__ == "__main__":
    unittest.main()
