# data/

Esta carpeta no contiene datos reales en el repo, solo:

- Punteros `.dvc` (versionados por DVC, apuntan al remoto de datos)
- `sample/` con una muestra mínima y no sensible para desarrollo local y tests

Los datos completos se descargan con `dvc pull` (ver `pipelines/` y `scripts/`).
