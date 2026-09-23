import json
import pathlib
import sys

prompt_path, schema_path, model, backend = sys.argv[1:]
prompt = pathlib.Path(prompt_path).read_text()
schema = json.loads(pathlib.Path(schema_path).read_text())
payload = {
    "model": model,
    "messages": [{"role": "user", "content": prompt}],
    "temperature": 0,
}
if backend == "deepseek":
    payload["response_format"] = {"type": "json_object"}
else:
    payload["response_format"] = {
        "type": "json_schema",
        "json_schema": {
            "name": "atlas_analysis",
            "strict": True,
            "schema": schema,
        },
    }
json.dump(payload, sys.stdout, ensure_ascii=False)
