#!/usr/bin/env python3
"""Contract test: quote references are resolved only from source blocks."""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory() as temporary:
    directory = Path(temporary)
    document = directory / "document.md"
    model_output = directory / "model.json"
    resolved_output = directory / "resolved.json"
    document.write_text(
        "---\n"
        "title: Test\n"
        "---\n\n"
        "Primer párrafo.\n\n"
        "El autor afirma que la restricción importa.",
        encoding="utf-8",
    )
    model_output.write_text(
        json.dumps({"problem": {"phenomenon": {"supporting_quotes": ["Q0002"]}}}),
        encoding="utf-8",
    )
    subprocess.run(
        ["python3", "scripts/resolve_quote_refs.py", str(document), str(model_output), str(resolved_output)],
        cwd=ROOT,
        check=True,
    )
    resolved = json.loads(resolved_output.read_text(encoding="utf-8"))
    assert resolved["problem"]["phenomenon"]["supporting_quotes"] == [
        "El autor afirma que la restricción importa."
    ]

    model_output.write_text(
        json.dumps({"problem": {"phenomenon": {"supporting_quotes": ["Q9999"]}}}),
        encoding="utf-8",
    )
    rejected = subprocess.run(
        ["python3", "scripts/resolve_quote_refs.py", str(document), str(model_output), str(resolved_output)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    assert rejected.returncode != 0

print("Contrato de citas por referencias: resolución exacta y rechazo de referencias inexistentes.")
