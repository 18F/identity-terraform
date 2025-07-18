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
    git
    glab
    shfmt
    tflint
    nixfmt-rfc-style
  ];

  languages = {
    terraform = {
      enable = true;
    };
  };
}
