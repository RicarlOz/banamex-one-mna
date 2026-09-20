# Banamex One

Proyecto de la Maestría en Inteligencia Artificial Aplicada del Tecnológico de Monterrey, en colaboración con Banamex, orientado a mejorar la consistencia de la atención al cliente mediante inteligencia artificial.

## Integrantes del proyecto

- Ricardo Sergio Gómez Cárdenas
- Josue Martín García Venegas
- Oliver Josué De León Milian
- **Sponsor:** Mitsuo Nakakawa

## Descripción del proyecto

Banamex One propone aprovechar la información disponible sobre los clientes, sus productos y sus interacciones con el banco para generar una perspectiva integral y actualizada de cada cliente. Para ello, se plantea desarrollar un proceso basado en modelos de lenguaje de gran escala (LLMs) y otros modelos que permita resumir, clasificar y presentar el estado actualizado de dichas interacciones.

El nombre ONE representa la visión central del proyecto: para el cliente, el banco es una sola entidad. Por lo tanto, su experiencia debe ser consistente independientemente de si interactúa con un ejecutivo, un chatbot, un conmutador telefónico u otro canal de atención.

## Planteamiento del problema

Los clientes interactúan con el banco a través de distintos canales físicos y digitales. Cada interacción genera información que, al consultarse de manera aislada, puede dificultar la comprensión del contexto del cliente y la continuidad de la atención.

El reto consiste en aprovechar esa información para ofrecer una visión unificada que permita a quienes atienden al cliente comprender sus interacciones previas, los productos relacionados y el estado de sus solicitudes.

## Objetivo general

Desarrollar un proceso basado en inteligencia artificial que transforme información estructurada y no estructurada de los clientes y sus interacciones en una perspectiva general, resumida y actualizada, que contribuya a brindar una experiencia consistente entre los canales de atención de Banamex.

## Objetivos específicos

- Integrar información de distintas fuentes sobre los clientes, sus productos y sus interacciones con el banco.
- Generar resúmenes que faciliten la comprensión del contexto de cada cliente.
- Clasificar las interacciones para facilitar su organización y consulta.
- Presentar el estado actualizado de las interacciones a partir de la información disponible.
- Facilitar la continuidad de la atención entre los diferentes canales del banco.

## Datos contemplados

De acuerdo con el planteamiento inicial, se contempla utilizar información estructurada y no estructurada de las siguientes fuentes:

| Fuente | Información contemplada |
| --- | --- |
| Canales digitales y físicos | Interacciones del cliente con el banco. |
| Productos bancarios | Apertura y cancelación de productos. |
| Llamadas telefónicas | Datos simulados (*dummy*) de carácter no estructurado. |
| Atención y seguimiento | Aclaraciones, quejas y bloqueos de productos. |

## Enfoque propuesto

El proceso contempla las siguientes etapas:

1. **Preparación de la información:** organizar los datos disponibles de las distintas fuentes.
2. **Procesamiento con modelos de IA:** utilizar LLMs y otros modelos para resumir y clasificar las interacciones.
3. **Consolidación del contexto:** reunir la información relevante y el estado de las interacciones en una perspectiva general del cliente.
4. **Consulta para la atención:** presentar el contexto consolidado de forma comprensible para quienes interactúan con el cliente.

La arquitectura, las herramientas y los modelos específicos se definirán durante el desarrollo del proyecto.

## Impacto esperado

Banamex One busca mejorar la experiencia del cliente al facilitar una atención informada y consistente entre canales. La disponibilidad de un contexto compartido puede reducir la necesidad de repetir información y ayudar a dar continuidad a las solicitudes, reforzando la percepción de interactuar con un solo banco.

## Estado del proyecto

El proyecto se encuentra en la etapa de planteamiento y definición del alcance. Este repositorio concentrará la documentación y los componentes desarrollados durante el proyecto.
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
