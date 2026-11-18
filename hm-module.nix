# Home Manager module: installs scrim and, by default, a Claude Code skill that
# tells agents when and how to use it. Both go away with `enable = false` or
# with removing this flake.
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.scrim;
in
{
  options.programs.scrim = {
    enable = lib.mkEnableOption "scrim, a minimal headless browser for AI agents";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.scrim;
      defaultText = lib.literalExpression "scrim-nix.packages.\${system}.scrim";
      description = "The scrim package to install.";
    };

    claudeSkill.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Link a Claude Code skill to ~/.claude/skills/scrim/SKILL.md, so agents
        know scrim exists, when to prefer it, and its exit code quirks.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file.".claude/skills/scrim/SKILL.md" = lib.mkIf cfg.claudeSkill.enable {
      source = ./skills/scrim/SKILL.md;
    };
  };
}
