.DEFAULT_GOAL := help

LLM ?= $(if $(strip $(llm)),$(llm),deepseek)
RESUME ?= 1
ifeq ($(strip $(MODEL)),)
  ifeq ($(LLM),deepseek)
    MODEL := deepseek-v4-pro
  else ifeq ($(LLM),gpt)
    MODEL := gpt-5
  else
    MODEL :=
  endif
endif
.PHONY: help doctor setup bootstrap check-project check-fast test check latest update reanalyze site publish install-monitor serve

RS_CONNECT_SERVER ?= connect.posit.cloud
RS_CONNECT_ACCOUNT ?= miparrar
RS_CONNECT_APP_ID ?= 01a081a7-cfb9-5b45-0b53-29a9a00cf0b9

help:
	@printf '%s\n' 'make setup       Preparar el entorno R y comprobar la configuración' 'make doctor      Comprobar herramientas, backend y credenciales LLM' 'make check-project Comprobar esquema, fuentes y sintaxis R' 'make check       Ejecutar todos los checks y contratos' 'make latest      Tomar la publicación más reciente de cada fuente monitoreada' 'make update      Procesar publicaciones posteriores a la última ronda válida' 'make reanalyze   Regenerar el catálogo cuando cambia prompt o esquema' 'Backend: LLM=codex|gpt|deepseek MODEL=...' 'make publish     Actualizar y publicar el sitio en Posit Connect' 'make install-monitor  Programar make publish diariamente (HOUR=8)' 'make site        Reconstruir el sitio del catálogo monitoreado' 'make serve       Servir corpus/reports en http://localhost:8000'

doctor:
	scripts/doctor.sh "$(LLM)" "$(MODEL)"

setup:
	Rscript src/bootstrap.R
	@mkdir -p corpus/posts data/analysis data/manifests data/discovery logs .tmp
	$(MAKE) check
	@echo "Entorno listo. Primera ronda: make latest"

bootstrap: setup

check-project:
	Rscript src/check.R

check-fast: check-project
	bash -n scripts/analyze.sh scripts/analyze_batch.sh scripts/update.sh scripts/install_cron.sh scripts/publish_connect.sh scripts/llm_request.sh scripts/load_env.sh scripts/doctor.sh
	@command -v python3 >/dev/null 2>&1 || { printf 'Falta herramienta: python3\n' >&2; exit 1; }
	python3 -m py_compile scripts/llm_payload.py scripts/llm_extract.py scripts/build_analysis_prompt.py scripts/resolve_quote_refs.py

test: check-project
	Rscript tests/analysis_contract.R
	Rscript tests/discovery_contract.R
	Rscript tests/site_contract.R
	python3 tests/quote_refs_contract.py

check: check-fast test

latest update: doctor
	LLM="$(LLM)" MODEL="$(MODEL)" RESUME="$(RESUME)" bash scripts/update.sh $(if $(filter latest,$@),latest,new)
	@if test -s data/manifests/catalog.txt; then \
		Rscript src/validate_analysis.R data/manifests/catalog.txt; \
		Rscript src/render_analysis.R data/manifests/catalog.txt; \
	fi

reanalyze: doctor
	@test -s data/manifests/catalog.txt || { printf 'Falta el catálogo: ejecuta make latest\n' >&2; exit 1; }
	LLM="$(LLM)" MODEL="$(MODEL)" scripts/analyze_batch.sh data/manifests/catalog.txt
	Rscript src/validate_analysis.R data/manifests/catalog.txt
	Rscript src/render_analysis.R data/manifests/catalog.txt

install-monitor: check-fast
	LLM="$(LLM)" MODEL="$(MODEL)" scripts/install_cron.sh $(if $(HOUR),$(HOUR),8)

site: check-project
	@test -s data/manifests/catalog.txt || { printf 'Falta el catálogo: ejecuta make latest\n' >&2; exit 1; }
	Rscript src/validate_analysis.R data/manifests/catalog.txt
	Rscript src/render_analysis.R data/manifests/catalog.txt

publish:
	$(MAKE) update
	RS_CONNECT_SERVER="$(RS_CONNECT_SERVER)" \
	RS_CONNECT_ACCOUNT="$(RS_CONNECT_ACCOUNT)" \
	RS_CONNECT_APP_ID="$(RS_CONNECT_APP_ID)" \
	bash scripts/publish_connect.sh

serve:
	@command -v python3 >/dev/null 2>&1 || { printf 'Falta herramienta: python3\n' >&2; exit 1; }
	@test -f corpus/reports/index.html || { printf 'Falta el sitio: ejecuta make latest o make site\n' >&2; exit 1; }
	python3 -m http.server "$${PORT:-8000}" --directory corpus/reports
