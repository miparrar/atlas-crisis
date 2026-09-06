# AGENTS.md

## Mission

Build Atlas de la Crisis as a reproducible research system to cartograph competing explanations of economic crisis.

## Non-negotiable rules

1. The project studies economic crisis broadly. Do not privilege profitability, finance, inflation, debt, technology, labour, or any other mechanism a priori.
2. Sources are curated explicitly in `config/sources.yml`. Do not perform open-web discovery unless the spec is changed.
3. The canonical local document is normalized Markdown with provenance and a SHA-256 hash of the normalized body.
4. Batch LLM work is invoked from Bash with `codex exec`. R must not call an LLM API.
5. R is used for ingestion, transformation, validation, and analysis.
6. R code follows tidyverse style: clear pipelines, snake_case names, small functions, explicit transformations, and no avoidable loops.
7. GNU Make orchestrates dependencies between stages.
8. Generated corpus and analysis outputs are not committed by default.
9. Every analytical claim extracted by the LLM must remain traceable to a source document.
10. Prefer small, testable scripts over framework-heavy abstractions.

## Required reading before changes

- Read `SPEC.md`.
- For project workflow, read `.agents/skills/crisis-atlas/SKILL.md`.
- For R command-line work, consult `.agents/skills/r-cli-app/SKILL.md`.

## Git

Use Conventional Commits:

- `feat:` new capability
- `fix:` bug fix
- `docs:` documentation
- `test:` tests
- `refactor:` behavior-preserving restructuring
- `chore:` maintenance

Keep commits focused.
