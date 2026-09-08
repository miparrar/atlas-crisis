.DEFAULT_GOAL := help
.PHONY: help doctor setup bootstrap check latest update site install-monitor serve

help:
	@printf '%s\n' 'make setup       Preparar el entorno R y comprobar la configuración' 'make doctor      Comprobar herramientas y autenticación de Codex' 'make check       Comprobar el proyecto sin instalar ni llamar al LLM' 'make latest      Tomar la publicación más reciente de cada fuente monitoreada' 'make update      Procesar publicaciones posteriores a la última ronda válida' 'make install-monitor  Programar make update diariamente (HOUR=8)' 'make site        Reconstruir el sitio del catálogo monitoreado' 'make serve       Servir corpus/reports en http://localhost:8000'

doctor:
	@for tool in Rscript bash awk sed cut sha256sum mktemp codex; do \
		command -v "$$tool" >/dev/null 2>&1 || { printf 'Falta herramienta: %s\n' "$$tool" >&2; exit 1; }; \
	done
	@codex login status || { printf 'Autentica Codex con: codex login\n' >&2; exit 1; }
	@echo "Herramientas y autenticación: ok"

setup: doctor
	Rscript src/bootstrap.R
	@mkdir -p corpus/posts data/analysis data/manifests data/discovery logs .tmp
	$(MAKE) check
	@echo "Entorno listo. Primera ronda: make latest"

bootstrap: setup

check:
	bash -n scripts/analyze.sh scripts/analyze_batch.sh scripts/update.sh scripts/install_cron.sh
	Rscript src/check.R
	Rscript tests/analysis_contract.R
	Rscript tests/discovery_contract.R
	Rscript tests/site_contract.R

latest update: doctor check
	bash scripts/update.sh $(if $(filter latest,$@),latest,new)

install-monitor: check
	scripts/install_cron.sh $(if $(HOUR),$(HOUR),8)

site: check
	@test -s data/manifests/catalog.txt || { printf 'Falta el catálogo: ejecuta make latest\n' >&2; exit 1; }
	Rscript src/validate_analysis.R data/manifests/catalog.txt
	Rscript src/render_analysis.R data/manifests/catalog.txt

serve:
	@command -v python3 >/dev/null 2>&1 || { printf 'Falta herramienta: python3\n' >&2; exit 1; }
	@test -f corpus/reports/index.html || { printf 'Falta el sitio: ejecuta make latest o make site\n' >&2; exit 1; }
	python3 -m http.server "$${PORT:-8000}" --directory corpus/reports
