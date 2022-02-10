let
  pkgs = import <nixpkgs> { };
in 
with pkgs;
mkShell {
  name = "dev-environment";
  buildInputs = [ 
    nodejs-16_x
  ];
}
