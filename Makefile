.PHONY: doctor bootstrap check pilot-1 pilot-2 pilot-5 validate-1 validate-2 validate-5

doctor:
	@command -v Rscript >/dev/null || (echo "missing: Rscript" && exit 1)
	@command -v codex >/dev/null || (echo "missing: codex" && exit 1)
	@command -v sha256sum >/dev/null || (echo "missing: sha256sum" && exit 1)
	@echo "system dependencies: ok"

bootstrap: doctor
	Rscript src/bootstrap.R

check: bootstrap
	bash -n scripts/analyze.sh scripts/analyze_batch.sh
	Rscript -e 'jsonlite::fromJSON("config/analysis_schema.json"); cat("schema: ok\n")'

pilot-1: bootstrap
	Rscript src/ingest_pilot.R pilot_1
	bash scripts/analyze_batch.sh data/manifests/pilot_1.txt
	Rscript src/validate_analysis.R data/manifests/pilot_1.txt

pilot-2: bootstrap
	Rscript src/ingest_pilot.R pilot_2
	bash scripts/analyze_batch.sh data/manifests/pilot_2.txt
	Rscript src/validate_analysis.R data/manifests/pilot_2.txt

pilot-5: bootstrap
	Rscript src/ingest_pilot.R pilot_5
	bash scripts/analyze_batch.sh data/manifests/pilot_5.txt
	Rscript src/validate_analysis.R data/manifests/pilot_5.txt

validate-1:
	Rscript src/validate_analysis.R data/manifests/pilot_1.txt

validate-2:
	Rscript src/validate_analysis.R data/manifests/pilot_2.txt

validate-5:
	Rscript src/validate_analysis.R data/manifests/pilot_5.txt
