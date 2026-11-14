# MEMORY.md — nixos-ci

> Estado vivo de los hosts: qué hay desplegado, en qué máquina y qué toca ahí.
> **Léelo al empezar a trabajar en este repo y actualízalo al terminar.** Cómo
> funciona la configuración está en `AGENTS.md`; el porqué de las decisiones, en
> `DECISIONS.md`. El estado de los repos del workspace vive en el `MEMORY.md` de
> la raíz.

Última actualización: 2026-11-14.

## Hosts

| Host | Servicio | Desplegado | Estado |
|---|---|---|---|
| `nixos-ci` | compila imágenes LXC y corre los runners de Forgejo | configuración del repo | despliegue automático de `nixos-llamaswap-rocm` activo desde `main` |
| `llamaswap-lxc` | llama-swap + llama.cpp (ROCm) | llama.cpp `v0.9.0` (build 8642541) | sirviendo GGUF |
| `nixos-pi-agent` | sesiones de `pi` contra OmniRoute | configuración en `main` | despliegue manual; `models.json` pendiente |

`nixos-forgejo` aloja Forgejo con Actions activas y registro cerrado.
`nixos-ci` corre dos runners: `ci` (`host:host`, despliegue) y
`nixos-runner` (`docker`, trabajos en contenedor). El resto de hosts
(`nixos-n8n`, `nixos-n8n-runner`, `nixos-omniroute`, `nixos-postgresql`,
`nixos-hindsight`, `nixos-calibre-wa`) ejecuta la configuración del repo sin
estado propio que anotar aquí.

## llama.cpp

`v0.9.0` está desplegado y es la última release: nada que subir. La ruta del store
cambia con cada versión — se localiza con `ls -lut /nix/store | grep llamacpp` y se
toma la más nueva.

## Batería `llama-bench`

Qwen3.5-9B y Spark medidas; el detalle vive en el `MEMORY.md` de la raíz y en
`llama-bench-runner/MEMORY.md`. No hay mediciones de aceptación especulativa.

## Despliegue

- El workflow `.forgejo/workflows/deploy-llamaswap-rocm.yml` corre en el runner
  `ci` (`runs-on: host`) y despliega `nixos-llamaswap-rocm`:
  - push a `main` → `nixos-rebuild switch` contra el host;
  - push a `llamaswap-rocm` → `nixos-rebuild test` (compila sin activar).
- La clave de despliegue es el secreto sops `deploy-key` de `hosts/nixos-ci`;
  systemd la expone como credencial al servicio `forgejo-runner-ci`.
- `nixos-ci` no puede hacer `git pull` de GitHub (su clave no está autorizada):
  los pulls manuales se hacen desde el host de desarrollo o los hace el usuario.
  El runner de Forgejo hace su propio checkout, así que el despliegue no depende
  de ese pull.
- El resto de hosts se aplica a mano: el workflow solo se dispara desde `main`
  y `llamaswap-rocm`, así que un cambio en otro host no llega solo.

## Pendiente

1. Normalizar `hosts/nixos-pi-agent/config/models.json`: `baseUrl` tiene doble
   barra (`...:20128//v1`), la API key está en claro y `defaultModel` no aparece
   en la lista de modelos.
2. Contrastar el broker de n8n: el runner apunta al puerto `5678`, pero también
   se publica el `5679`.
3. Decidir qué hacer con `hosts/pihole-lxc/`: existe pero no tiene salida en
   `flake.nix` ni documentación propia.
4. Decidir si `.agents/` y `skills-lock.json` (sin seguimiento en este repo)
   pertenecen aquí o son una copia del workspace.
5. Modularizar las convenciones de los ficheros de modelos de
   `hosts/llamaswap-lxc/models/`; falta acordar la forma más simple.
