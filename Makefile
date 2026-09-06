.PHONY: check pilot-1 pilot-2 pilot-5 validate-1 validate-2 validate-5

check:
	bash -n scripts/analyze.sh scripts/analyze_batch.sh
	jq empty config/analysis_schema.json

pilot-1:
	Rscript src/ingest_pilot.R pilot_1
	bash scripts/analyze_batch.sh data/manifests/pilot_1.txt
	Rscript src/validate_analysis.R data/manifests/pilot_1.txt

pilot-2:
	Rscript src/ingest_pilot.R pilot_2
	bash scripts/analyze_batch.sh data/manifests/pilot_2.txt
	Rscript src/validate_analysis.R data/manifests/pilot_2.txt

pilot-5:
	Rscript src/ingest_pilot.R pilot_5
	bash scripts/analyze_batch.sh data/manifests/pilot_5.txt
	Rscript src/validate_analysis.R data/manifests/pilot_5.txt

validate-1:
	Rscript src/validate_analysis.R data/manifests/pilot_1.txt

validate-2:
	Rscript src/validate_analysis.R data/manifests/pilot_2.txt

validate-5:
	Rscript src/validate_analysis.R data/manifests/pilot_5.txt
