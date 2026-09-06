---
name: crisis-atlas
description: Work on Atlas de la Crisis, a reproducible corpus and structured-analysis pipeline for mapping competing explanations of economic crisis.
---

# Crisis Atlas Skill

## Purpose

Use this skill whenever changing ingestion, source curation, Codex batch processing, schemas, validation, or corpus structure in this repository.

## Workflow

1. Read `AGENTS.md` and `SPEC.md`.
2. Preserve the distinction between:
   - source curation;
   - document ingestion;
   - semantic extraction;
   - validation;
   - downstream analysis.
3. Never let the technical availability of a source decide the project's theoretical scope.
4. Keep LLM calls in Bash through `codex exec`.
5. Keep R focused on data work and use tidyverse style.
6. Treat Markdown + provenance + content hash as the canonical local document representation.
7. Make processing incremental using the content hash and schema hash.
8. Validate exact quotations against the source Markdown before scaling.
9. Pilot changes on 1 document before 2 and 5 when they alter ingestion or extraction behavior.

## Source additions

When adding a source:

- state its analytical tradition without treating the label as exhaustive;
- record its base URL and discovery mechanism;
- distinguish public, mixed, and paywalled access;
- add selectors only when needed;
- never bypass a paywall.

## Extraction changes

Any new analytical field requires:

1. updating `config/analysis_schema.json`;
2. updating `prompts/analyze.md`;
3. updating validation if applicable;
4. rerunning the pilot sequence.

## R style

Prefer:

- `|>`;
- `dplyr`, `purrr`, `stringr`, `readr`, `tibble`;
- small functions;
- explicit joins and selections;
- snake_case;
- clear data contracts.

Avoid unnecessary classes, mutable state, and framework-heavy abstractions.
