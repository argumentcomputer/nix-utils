{}:
{
  rustLibTemplate = {
    path = ./templates/rust-lib;
    description = "A rust library setup with a github action";
  };
  cLibTemplate = {
    path = ./templates/c-lib;
    description = "A simple C/C++ library setup with a github action";
  };
  leanTemplate = {
    path = ./templates/lean-package;
    description = "A simple Lean package setup";
  };
  nixGithubCI = {
    path = ./templates/nix-github-ci;
    description = "A Nix flakes github actions CI with cachix support.";
  };
}
