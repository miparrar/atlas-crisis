#!/usr/bin/env python3
"""Replace model-emitted quote block IDs with exact source text."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


def canonical_body(path: Path) -> str:
    lines = path.read_text(encoding="utf-8").splitlines()
    boundaries = [index for index, line in enumerate(lines) if line == "---"]
    if len(boundaries) < 2 or boundaries[0] != 0:
        raise ValueError(f"Front matter inválido: {path}")
    body = "\n".join(lines[boundaries[1] + 1 :])
    body = re.sub(r"[ \t]+", " ", body)
    body = re.sub(r"\n{3,}", "\n\n", body)
    return body.strip()


def blocks(body: str) -> dict[str, str]:
    return {f"Q{index:04d}": block for index, block in enumerate(body.split("\n\n"), start=1) if block}


def resolve(value: Any, block_map: dict[str, str], body: str, path: str = "$") -> Any:
    if isinstance(value, dict):
        return {
            key: (
                [resolve_quote(item, block_map, body, f"{path}.{key}[{index}]")
                 for index, item in enumerate(value[key], start=1)]
                if key == "supporting_quotes" and isinstance(value[key], list)
                else resolve(value[key], block_map, body, f"{path}.{key}")
            )
            for key in value
        }
    if isinstance(value, list):
        return [resolve(item, block_map, body, f"{path}[{index}]") for index, item in enumerate(value, start=1)]
    return value


def resolve_quote(value: Any, block_map: dict[str, str], body: str, path: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{path}: cita no textual")
    if value in block_map:
        return block_map[value]
    if value in body:
        return value
    raise ValueError(
        f"{path}: referencia desconocida o cita no literal: {value[:180]}"
    )


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: resolve_quote_refs.py <document.md> <input.json> <output.json>", file=sys.stderr)
        return 2
    document_path, input_path, output_path = map(Path, sys.argv[1:])
    body = canonical_body(document_path)
    analysis = json.loads(input_path.read_text(encoding="utf-8"))
    try:
        resolved = resolve(analysis, blocks(body), body)
    except ValueError as error:
        print(f"Resolución de citas fallida: {error}", file=sys.stderr)
        return 1
    output_path.write_text(json.dumps(resolved, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
