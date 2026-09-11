# Specification

## 1. Purpose

Atlas de la Crisis aims to **cartograph economic crisis** by building a plural, traceable corpus of economists' and other relevant authors' posts and blogs.

The system should make it possible to compare:

- diagnoses of crisis;
- main theses;
- causal mechanisms;
- empirical evidence;
- indicators;
- concepts;
- periods and geographies;
- agreements and controversies across schools.

The project is inspired by Wes McKinney's **Spicy Takes** workflow: curate sources, normalize documents, process them systematically with an LLM, and store structured outputs. Atlas de la Crisis changes the analytical target from provocative takes to competing explanations of economic crisis.

## 2. Initial scope

Phase 1 is restricted to public blog posts and posts from newsletter-style sites.

Out of scope for the first phase:

- books;
- journal articles and PDFs;
- general web search;
- RAG;
- embeddings;
- interactive chat;
- institutional datasets.

## 3. Source model

Sources are curated in `config/sources.yml`.

Each source records:

- stable id;
- author;
- school or analytical tradition;
- thematic focus and a curatorial note;
- publication name;
- base URL;
- discovery method;
- HTML selectors when needed;
- explicit feed-entry exclusion rules when a recurring format is outside the document policy;
- access status;
- whether automated ingestion is enabled.

The intellectual corpus may include sources that are not yet technically ingestible. Technical availability must not determine theoretical pluralism.

The curated catalog comprises Michael Roberts, Adam Tooze, Paul Krugman, Michael Pettis, Ann Pettifor, Kate Mackenzie, Fernando Rugitsky, Grace Blakeley, Branko Milanović, Stephanie Kelton, and Rana Foroohar. The automatically monitored subset is Michael Roberts, Adam Tooze, Paul Krugman, and Kate Mackenzie, recorded in `monitored_source_ids`. Other catalog entries remain disabled until their access, discovery mechanism, authorship rules, and selectors are verified. Tradition and focus labels are descriptive and non-exhaustive; they must not constrain extraction.

For monitored sources, record the RSS feed, archive URL, platform, language, verification date, access notes, extraction readiness, and whether monitoring is active. RSS identifies recent posts; it does not establish complete historical coverage or full-text availability. Select substantive authored posts about economic crisis broadly, with publicly accessible full text. Exclude reader comments, site controls, partial previews, and audiovisual or link-only entries without substantive authored text. Recurring ineligible formats may be excluded by source-specific, versioned title rules before discovery.

Automatic discovery is restricted to `monitored_source_ids` entries with `monitor: true`. The baseline round selects the latest feed entry for each source. Subsequent rounds process every entry that precedes the last confirmed URL in the current feed. If that URL is absent, discovery fails explicitly rather than assuming continuity.

## 4. Document contract

Each ingested post is stored locally as Markdown under `corpus/posts/`.

Front matter must contain at least:

- `source_id`;
- `document_id`;
- `author`;
- `publication`;
- `title`;
- `published_at` when available;
- `source_url`;
- `discovered_at`;
- `retrieved_at`;
- `access_status`;
- `content_sha256`.

`content_sha256` hashes only the normalized document body, not volatile retrieval metadata.

## 5. LLM contract

LLM processing is performed only through Bash invoking Codex CLI.

Canonical invocation pattern:

```bash
codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  --output-schema config/analysis_schema.json \
  --output-last-message OUTPUT \
  -
```

The prompt is passed through stdin.

R must not call OpenAI, ellmer, LangChain, or another LLM client for batch document analysis.

## 6. Structured analysis

Contract version 2 produces an academic reading sheet in Spanish, with original-language quotations. Each document records a summary, analytical usability status, limitations, and a single reading organized around the article's central problem. The model first extracts relevant material and then reorganizes it in this order:

1. phenomenon: what phenomenon or problem the author identifies;
2. explanation: how the author explains or interprets it, including causal relations, conditions, uncertainty and alternatives;
3. constitutive_elements: actors, relations, processes, institutions, variables or concepts and their role in the explanation;
4. evidence: empirical or historical material the author uses, its cited source, and whether it is available in the text or merely referred to;
5. theory: concepts, propositions, authors or frameworks used, discussed or rejected, with explicit versus inferred attribution.

Secondary tensions and derivations are integrated into the central reconstruction rather than emitted as independent problems. Every populated analytical item includes the minimum non-empty supporting quotations needed from the normalized body. Do not infer theory from an author's catalog tradition. Preserve the distinction between author claims, alternatives rejected by the author, and extractor inferences. Missing explanation is null; missing elements, evidence or theory use empty arrays. Context such as periods, geographies and indicators belongs in the relevant descriptions, only when supported by the document.

A partial or analytically insufficient document has `problem: null` and records its limitations. The status `analizable` describes the usability of the supplied text, not verified completeness of the original or human approval. Human review remains necessary for interpretation, attribution and evidence quality.

The JSON Schema in `config/analysis_schema.json` is the authoritative output contract. `prompts/analyze.md` defines extraction instructions. The static HTML site provides a home page, author indexes and article readings. Each reading follows the five dimensions and exposes supporting quotations and provenance; it is generated locally from validated JSON and Markdown. The visual reference is Spicy Takes' author-to-post navigation and layered summaries and quotations, adapted to an academic reading workflow.

## 7. Incrementality

The normalized source URL is the stable publication identity. A new URL creates a document; an existing URL reuses its corpus path. A document is reprocessed when its verified `content_sha256`, JSON Schema hash, or prompt hash changes. Retrieval timestamps alone must not invalidate the semantic analysis cache.

A cached JSON file is reusable only if it still passes schema, document-hash, and exact-quotation validation. Legacy analysis files do not satisfy version 2 and must be regenerated before validation or rendering.

Feed state is transactional. Discovery writes a pending state; the confirmed state and cumulative monitored catalog advance only after the complete pending batch has been ingested, analyzed, and validated.

## 8. Validation

Before scaling, verify:

- correct source and URL;
- usable normalized text;
- provenance fields;
- valid SHA-256;
- JSON Schema compliance;
- quotations are exact substrings of the source document;
- no unnecessary reprocessing;
- analytical outputs are plausible and traceable.

## 9. Persistence

Versioned:

- source definitions;
- prompts;
- schemas;
- code;
- specs;
- skills.

Local/generated by default:

- downloaded Markdown corpus;
- LLM JSON outputs;
- manifests and logs.

This avoids publishing third-party copyrighted text as part of the Git repository.

## 10. Publication

The intermediate publishable artifact is the generated static site under `corpus/reports/`, not the canonical Markdown corpus. When GitHub Pages is enabled, `make publish` synchronizes that site into the versioned `docs/` directory, commits only the generated publication, and pushes `main`; `main/docs` is the remote publication target. Building the site requires only validated local JSON and Markdown; it does not download sources or call an LLM.

The site is organized as a home page, one index per author, and one page per article. It can be served locally for human review before deployment. Remote hosting is configured separately and must publish only the generated site directory.

Generated pages remain local by default. This project explicitly enables GitHub Pages for `main/docs` as its publication target; article pages contain quotations from third-party texts and must therefore be reviewed before `make publish`.
