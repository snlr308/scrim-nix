{
  description = "Nix package for scrim, a minimal headless browser for AI agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Upstream has no flake; pinned to a release tag
    scrim-src = {
      url = "github:strelov1/scrim/v0.1.0";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      scrim-src,
    }:
    let
      version = "0.1.0";
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      scrimFor =
        pkgs:
        pkgs.callPackage ./package.nix {
          src = scrim-src;
          inherit version;
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        scrim = scrimFor pkgs;
        default = scrim;
      });

      overlays.default = final: _prev: { scrim = scrimFor final; };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
