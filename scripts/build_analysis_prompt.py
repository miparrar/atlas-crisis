#!/usr/bin/env python3
"""Build an analysis prompt with stable IDs for source-text blocks."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def canonical_body(path: Path) -> tuple[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    boundaries = [index for index, line in enumerate(lines) if line == "---"]
    if len(boundaries) < 2 or boundaries[0] != 0:
        raise ValueError(f"Front matter inválido: {path}")
    metadata = "\n".join(lines[1 : boundaries[1]])
    body = "\n".join(lines[boundaries[1] + 1 :])
    body = re.sub(r"[ \t]+", " ", body)
    body = re.sub(r"\n{3,}", "\n\n", body)
    return metadata, body.strip()


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: build_analysis_prompt.py <template.md> <document.md> <output>", file=sys.stderr)
        return 2
    template_path, document_path, output_path = map(Path, sys.argv[1:])
    template = template_path.read_text(encoding="utf-8")
    metadata, body = canonical_body(document_path)
    blocks = [block for block in body.split("\n\n") if block]
    source = [
        "\nMETADATOS DEL DOCUMENTO (no son evidencia):\n",
        metadata,
        "\n\nCUERPO DEL DOCUMENTO EN BLOQUES IDENTIFICADOS:\n",
        "Cada supporting_quotes debe contener únicamente uno o más identificadores de bloque como Q0001. No copies ni reescribas el texto de la cita: el sistema lo insertará literalmente después.",
    ]
    for index, block in enumerate(blocks, start=1):
        source.extend([f"\n\n[Q{index:04d}]\n", block])
    output_path.write_text(template + "".join(source) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
