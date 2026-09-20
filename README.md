# banamex-one-mna

## Estructura del proyecto

```
banamex-one-mna/
├── src/
│   └── banamex_one_mna/
│       ├── agents/          # agente principal, agente revisor, orquestación
│       ├── tools/           # herramientas: consulta de historial, búsqueda, etc.
│       ├── prompts/         # prompts versionados como archivos (.md/.yaml), no en el código
│       ├── ingestion/       # transcripción, redacción de PII, normalización
│       ├── retrieval/       # chunking, embeddings, índice
│       ├── schemas/         # modelos Pydantic de cliente, interacción, salida
│       └── config.py
├── configs/                 # modelos, umbrales, rutas (YAML), separados por entorno
├── pipelines/                # dvc.yaml y params.yaml
├── data/                     # solo punteros .dvc, README y sample/
├── evals/                    # golden set, métricas, scripts de evaluación
├── tests/                    # unitarios de herramientas y esquemas, pruebas de humo del agente
├── notebooks/                # exploración; nada de aquí se importa desde src
├── docs/                     # arquitectura, decisiones (ADRs), diagrama del flujo
├── scripts/                  # datos sintéticos, descarga del remoto
├── .github/workflows/        # CI
├── .env.example
├── .gitignore
├── .pre-commit-config.yaml
├── Makefile
├── pyproject.toml
└── README.md
```

## Justificación de la estructura

**`src/` layout (en vez de paquete en la raíz).**
Evita que el código se importe accidentalmente desde el directorio de trabajo sin estar instalado, lo cual oculta errores de empaquetado y de `PYTHONPATH`. Fuerza a instalar el paquete (`pip install -e .`) igual que lo haría un usuario final o el CI, así lo que se prueba es lo que realmente se distribuye.

**`agents/`, `tools/`, `prompts/`, `ingestion/`, `retrieval/`, `schemas/` como módulos separados.**
El sistema tiene responsabilidades muy distintas (orquestación de agentes, herramientas invocables, preparación de datos, búsqueda semántica, contratos de datos) que cambian a ritmos y por razones distintas. Separarlas evita un módulo monolítico y permite testear, versionar y modificar cada pieza de forma independiente. En particular:
- **`prompts/` como archivos, no como strings en el código:** permite versionar prompts con diffs legibles, iterarlos sin tocar lógica Python, y que alguien no-técnico (o un proceso de eval) los revise o edite sin leer código.
- **`schemas/` centralizado:** los modelos Pydantic son el contrato entre ingestion → retrieval → agents → salida. Tenerlos en un solo lugar evita definiciones duplicadas o inconsistentes entre módulos.

**`configs/` separado por entorno, en YAML.**
Los parámetros que cambian entre dev/staging/prod (modelo, umbrales, rutas) no deben vivir hardcodeados en el código ni mezclados con secretos. YAML permite diffear cambios de configuración en PRs y auditar qué cambió entre entornos sin tocar `src/`.

**`pipelines/` con `dvc.yaml` y `params.yaml`.**
Separa la *definición* del pipeline (qué pasos existen, qué dependen de qué) de la *implementación* (`src/`) y de los *parámetros* (`params.yaml`). Esto hace el pipeline reproducible: dado un commit y un set de parámetros, `dvc repro` reconstruye los mismos artefactos.

**`data/` solo con punteros `.dvc`, `README.md` y `sample/`.**
Los datos reales (potencialmente con información de clientes) nunca se commitean a git. Solo se versiona el puntero DVC (hash + ubicación remota). `sample/` contiene una muestra mínima y no sensible para que cualquiera pueda correr tests y desarrollo local sin acceso al dato real.

**`evals/` como carpeta de primer nivel, no dentro de `tests/`.**
Las evaluaciones de un agente LLM (golden set, métricas de calidad, comparación entre versiones de prompt/modelo) son un tipo de verificación distinto a las pruebas unitarias: son más lentas, pueden requerir llamadas a modelos, y sus resultados son métricas continuas en vez de pass/fail. Separarlas evita que unit tests rápidos (`make test`) se mezclen con evals costosas (`make eval`), y deja claro dónde vive el criterio de calidad del agente.

**`tests/` limitado a unitarios de herramientas/esquemas y smoke tests del agente.**
El objetivo no es probar la "inteligencia" del agente (eso es trabajo de `evals/`), sino que las piezas determinísticas (parsing, validación de schemas, tools) funcionen y que el agente no rompa en un caso mínimo (smoke test). Mantiene el CI rápido y confiable.

**`notebooks/` explícitamente aislado de `src/`.**
Los notebooks son para exploración desechable. La regla "nada de aquí se importa desde `src/`" evita que lógica de producción termine dependiendo de código sin tests, sin lint y difícil de revisar en un diff.

**`docs/` para arquitectura y ADRs.**
Las decisiones de diseño (por qué un chunking de cierto tamaño, por qué ese modelo, por qué esa arquitectura de agentes) se pierden en el historial de Slack o de PRs si no se documentan aparte. Un ADR por decisión relevante da trazabilidad sin inflar el código con comentarios.

**`scripts/` separado de `src/`.**
Contiene utilidades operativas (generar datos sintéticos, bajar el remoto de DVC) que no son parte de la librería importable del proyecto, así no se empaquetan ni se exponen como API.

**`.github/workflows/` para CI.**
Automatiza lint, tests y (opcionalmente) evals en cada PR, para que los problemas se detecten antes de mergear, no en producción.

**Archivos de configuración en la raíz (`.env.example`, `.gitignore`, `.pre-commit-config.yaml`, `Makefile`, `pyproject.toml`).**
- `.env.example` documenta qué variables de entorno/secretos son necesarios sin exponer valores reales.
- `.pre-commit-config.yaml` + `Makefile` estandarizan los comandos de lint/test/format para que todo el equipo (y el CI) use exactamente los mismos.
- `pyproject.toml` como única fuente de verdad de dependencias y metadata del paquete (en vez de `setup.py`/`requirements.txt` dispersos).

## Uso

```bash
make install   # instala el paquete en modo editable + pre-commit
make lint      # ruff check
make test      # pytest (unitarios)
make eval      # evaluación contra el golden set
make pipeline  # dvc repro (ingestion -> retrieval -> eval)
```
