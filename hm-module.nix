# Home Manager module: installs scrim and, by default, an agent skill
# (SKILL.md, Agent Skills format) that tells agents when and how to use it.
# Both go away with `enable = false` or with removing this flake.
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

    skill = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Link the scrim agent skill (when to prefer scrim, session workflow,
          exit code quirks) into every directory in `skill.dirs`.
        '';
      };

      dirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ".claude/skills" ];
        example = [
          ".claude/skills"
          ".agents/skills"
        ];
        description = ''
          Skill directories relative to $HOME; the skill lands in
          `<dir>/scrim/SKILL.md`. `.claude/skills` is read by Claude Code and
          OpenCode, `.agents/skills` by Codex and OpenCode. Check your agent's
          docs for others.
        '';
      };
    };
  };

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "scrim" "claudeSkill" "enable" ]
      [ "programs" "scrim" "skill" "enable" ]
    )
  ];

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file = lib.mkIf cfg.skill.enable (
      lib.listToAttrs (
        map (dir: lib.nameValuePair "${dir}/scrim/SKILL.md" { source = ./skills/scrim/SKILL.md; }) cfg.skill.dirs
      )
    );
  };
}
