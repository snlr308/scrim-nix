# scrim-nix

Nix flake packaging [scrim](https://github.com/strelov1/scrim), a minimal
headless browser for AI agents.

- Upstream version: 0.1.0 (tag `v0.1.0`)
- Platforms: `x86_64-linux` (built and smoke-tested)
- Other platforms need a `librusty_v8` hash in `package.nix`

## Install

Flake-based NixOS or Home Manager config:

```nix
{
  inputs.scrim-nix = {
    url = "github:snlr308/scrim-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Home Manager module  
  # (with standalone Home Manager, add the module to `modules` or `imports`)
  home-manager.sharedModules = [ inputs.scrim-nix.homeManagerModules.default ];
  programs.scrim.enable = true;

  # Add agent skill
  # programs.scrim.skill.dirs = [ ".claude/skills" ".agents/skills" ];
  # programs.scrim.skill.enable = false; # binary only

  # ... or only the package, via the overlay
  # nixpkgs.overlays = [ inputs.scrim-nix.overlays.default ];
  # home.packages = [ pkgs.scrim ];

  # ... or the package directly
  # home.packages = [ inputs.scrim-nix.packages.${pkgs.stdenv.hostPlatform.system}.#scrim ];
}
```

**Try it without installing:**

```sh
nix run github:snlr308/scrim-nix -- fetch https://example.com
```

## How to use

### CLI

See [scrim](https://github.com/strelov1/scrim)

### Agent skill

- Agents load the skill when needed
- Or prompt: `/scrim URL something`
- Agents without skill support: Add a line in `AGENTS.md` or equivalent,
naming scrim and its purpose: *"For web pages, use the `scrim` CLI
(`scrim --help`)*

[`skills/scrim/SKILL.md`](skills/scrim/SKILL.md) covers when to prefer scrim,
the session workflow, and minor details. See ([agentskills.io/clients](https://agentskills.io/clients)) for the exact path per agent. Common paths are `~/.claude/skills` and `~/.agents/skills`. **With the Home Manager module** the skill is linked into every directory in `programs.scrim.skill.dirs` (default `[ ".claude/skills" ]`), and is removed when the package is removed.


## How it is built

- `rustPlatform.buildRustPackage` with `cargoHash` (not `cargoLock`).
- The v8 crate normally downloads a prebuilt `librusty_v8.a` at build time. The
  Nix sandbox has no network, so the archive is fetched with `fetchurl` and
  passed via `RUSTY_V8_ARCHIVE`.
- The install check runs upstream's CI smoke test against a local HTTP server:
  visible text is read, page JavaScript runs, hidden content stays hidden.

## Updating to a new upstream release

1. Change the tag in `flake.nix` (`scrim-src.url`) and `version`, then
   `nix flake update scrim-src`.
2. If upstream's `v8 = "=X.Y.Z"` pin moved, update `rustyV8Version` and its
   hash: `nix store prefetch-file <url printed by the build>`.
3. Set `cargoHash = lib.fakeHash;`, run `nix build`, paste the hash it reports.
4. Re-check the "Exit codes and `eval`" section of `skills/scrim/SKILL.md`
   against the new binary and update its "Checked against" version.

## License

- scrim-nix is MIT
- [scrim](https://github.com/strelov1/scrim) is MIT