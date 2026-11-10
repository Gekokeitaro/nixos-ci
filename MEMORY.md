# MEMORY.md — nixos-ci

> Estado vivo de los hosts: qué hay desplegado, en qué máquina y qué toca ahí.
> **Léelo al empezar a trabajar en este repo y actualízalo al terminar.** Cómo
> funciona la configuración está en `AGENTS.md`; el porqué de las decisiones, en
> `DECISIONS.md`. El estado de los repos del workspace vive en el `MEMORY.md` de
> la raíz.

Última actualización: 2026-11-10.

## Hosts

| Host | Servicio | Desplegado | Estado |
|---|---|---|---|
| `nixos-ci` | compila imágenes LXC y corre el runner de Forgejo | configuración del repo | sin incidencias conocidas |
| `llamaswap-lxc` | llama-swap + llama.cpp (ROCm) | llama.cpp `v0.9.0` (build 8642541) | sirviendo GGUF |
| `nixos-pi-agent` | sesiones de `pi` con integración n8n | configuración del repo | sin incidencias conocidas |

El resto de hosts (`nixos-forgejo`, `nixos-n8n`, `nixos-omniroute`, …) no tiene
estado propio que anotar aquí: o corre la configuración del repo, o depende de
decisiones que están en `DECISIONS.md`.

## llama.cpp

`v0.9.0` está desplegado y es la última release: nada que subir. La ruta del store
cambia con cada versión — se localiza con `ls -lut /nix/store | grep llamacpp` y se
toma la más nueva.

## Batería `llama-bench`

Estrenada el 2026-11-09 en `llamaswap-lxc` (AMD Radeon 680M, 13900 MiB, backend
ROCm) con `gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf`: `tg64` base 23.42 → 23.27 tras el
primer paso, lejos del umbral de corte (16.39). GPU sana. Quedan los pasos
restantes de la batería (procedimiento en el `AGENTS.md` de la raíz).

## Despliegue

- La compilación **no** la lanzo yo: la activa el usuario con el proyecto
  **nixos-forgejo** mientras ese flujo no esté automatizado.
- `nixos-ci` no puede hacer `git pull` de GitHub (su clave no está autorizada):
  los pulls se hacen desde el host de desarrollo o los hace el usuario.
- Los cambios llegan al host por pull manual; no hay despliegue automático.

## Pendiente

1. Revisar `AGENTS.md` y `DECISIONS.md` para que no dupliquen lo que ya dicen el
   `AGENTS.md` de la raíz y este fichero.
2. Valorar documentación propia para `hosts/llamaswap-lxc/` (hoy solo `README.md`).
3. Modularizar las convenciones de los ficheros de modelos de
   `hosts/llamaswap-lxc/models/`; falta acordar la forma más simple.
