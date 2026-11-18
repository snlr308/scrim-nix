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

  # then either the overlay ...
  nixpkgs.overlays = [ inputs.scrim-nix.overlays.default ];
  home.packages = [ pkgs.scrim ];

  # ... or the package directly
  home.packages = [ inputs.scrim-nix.packages.${pkgs.stdenv.hostPlatform.system}.scrim ];
}
```
**Try it without installing:**

```sh
nix run github:snlr308/scrim-nix -- fetch https://example.com
```

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

## License

- scrim-nix is MIT
- [scrim](https://github.com/strelov1/scrim) is MIT