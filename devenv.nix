{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    detect-secrets
    git
    glab
    nixfmt-rfc-style
    shfmt
    terraform-docs
    tflint
  ];

  languages = {
    terraform = {
      enable = true;
    };
  };

  git-hooks.hooks = {
    detect-secrets = {
      enable = true;
      name = "detect-secrets";
      description = "Detects high entropy strings that are likely to be passwords.";
      entry = "detect-secrets-hook";
      language = "python";
      args = [
        "--baseline"
        ".secrets.baseline"
      ];
    };
    terraform-format.enable = true;
    terraform-docs = {
      enable = true;
      name = "terraform-docs";
      description = "Generate documentation for Terraform modules (via locally-installed CLI)";
      language = "system";
      entry = "terraform-docs";
      pass_filenames = false;
      types = [ "terraform" ];
    };
  };
}
