---
name: r-cli-app
description: Local pointer to Posit's R CLI app skill. Use when designing command-line interfaces in R.
metadata:
  upstream: posit-dev/skills
  upstream_path: r-lib/r-cli-app/SKILL.md
  upstream_commit: b58a92e7c479b7795f4f003490b046c01e345fce
license: MIT
---

# Posit R CLI App Skill

This project tracks Posit's official `r-cli-app` skill from `posit-dev/skills`.

Upstream source:
https://github.com/posit-dev/skills/tree/b58a92e7c479b7795f4f003490b046c01e345fce/r-lib/r-cli-app

## Core guidance used in Atlas de la Crisis

- R command-line scripts should have explicit, documented arguments.
- CLI programs should communicate failures through stderr and non-zero exit status.
- Prefer scripts whose code is also understandable and testable as ordinary R.
- When the project's CLI surface grows enough to justify it, evaluate Posit's `Rapp` rather than hand-rolling complex argument parsing.

The full upstream skill should be consulted at the pinned source when making substantial R CLI changes.
