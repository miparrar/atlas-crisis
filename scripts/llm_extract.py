import json
import pathlib
import sys

response_path, output_path = sys.argv[1:]
data = json.loads(pathlib.Path(response_path).read_text())
try:
    content = data["choices"][0]["message"]["content"]
except (KeyError, IndexError, TypeError) as error:
    raise SystemExit(f"Respuesta LLM sin choices.message.content: {error}")
if isinstance(content, list):
    content = "".join(
        part.get("text", "") for part in content if isinstance(part, dict)
    )
if not isinstance(content, str) or not content.strip():
    raise SystemExit("Respuesta LLM vacía")
pathlib.Path(output_path).write_text(content)
