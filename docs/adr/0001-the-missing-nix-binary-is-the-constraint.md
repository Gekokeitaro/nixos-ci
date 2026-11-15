# ADR 0001 — The missing `nix` binary is the constraint, not the operating system

**Date**: 2026-11-15

**Status**: Accepted. Supersedes the *context* of the 2026-05-26 entry "No Nix
CLI on the dev host" in [`../../DECISIONS.md`](../../DECISIONS.md); the decision
itself stands.

## Context

The 2026-05-26 entry justifies the ban on Nix CLI commands with "The development
machine is not NixOS". That sentence has become false in the way that matters: a
`nix` binary is available on macOS and on any Linux distribution, and this
repository is edited from more than one machine and more than one OS. What is
actually missing on the dev machine is `nix` itself; the operating system has
nothing to do with it. Several documents repeated the OS claim — `README.md`,
`AGENTS.md` and the `llamaswap-lxc` host `AGENTS.md` — so an agent editing from a
Linux machine without `nix` was told it was safe, and an agent editing from a
machine that happens to run NixOS was told it was not.

`DECISIONS.md` is frozen at its 300-line ceiling, so this correction is recorded
here instead of appending an entry.

## Decision

- The constraint is written as: **the dev machine has no `nix` installed;
  building and switching happen on the hosts.**
- The ban stays exactly as wide as before — no `nix`, `nix-build`, `nix-shell`,
  `nixos-rebuild` or any Nix CLI command from the dev machine — and it now names
  the missing binary as its cause.
- Validation stays the same: read the expressions and reason about them.

## Rationale

A rule that names the wrong cause invites the wrong exception. "Not NixOS" reads
as a property of the machine's distribution; "no `nix` installed" reads as a
property that a single `which nix` settles, and it survives a reinstall, a
different distro, or a WSL mount. The blast radius is unchanged: the same
commands remain forbidden, only the reason is corrected.
