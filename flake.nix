{
  description = "Visual Studio Code extensions for Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        ext = { publisher, name, version, sha256 }:
          pkgs.vscode-utils.buildVscodeMarketplaceExtension {
            mktplcRef = { inherit name publisher sha256 version; };
          };

        extensions = import ./extensions.nix;
      in
      {
        packages = builtins.listToAttrs (builtins.map
          (e: {
            name = "${e.publisher}";
            value = {
              "${e.name}" = ext {
                inherit (e) publisher name version sha256;
              };
            };
          })
          extensions);
      }
    );
}
