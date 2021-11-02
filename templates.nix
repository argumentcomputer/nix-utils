{}:
let
  rustLibTemplate = {
    path = ./templates/rust-lib;
    description = "A rust library setup with a github action";
  };
  cLibTemplate = {
    path = ./templates/c-lib;
    description = "A simple C/C++ library setup with a github action";
  };
in
{
  inherit rustLibTemplate cLibTemplate;
}
