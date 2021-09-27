{}:
let
  rustLibTemplate = {
    path = ./templates/rust-lib;
    description = "A rust library setup with a github action";
  };
in
{
  inherit rustLibTemplate;
}
