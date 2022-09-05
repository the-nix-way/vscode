{
  description = "Visual Studio Code extensions for Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          (self: super: {
            vsCodeExtensionHelper = { publisher, name, version, sha256 }:
              super.vscode-utils.buildVscodeMarketplaceExtension {
                mktplcRef = { inherit name publisher sha256 version; };
              };
          })
        ];

        pkgs = import nixpkgs {
          inherit overlays system;
        };

        inherit (pkgs.lib) mkMerge;
        inherit (pkgs.lib.strings) concatStrings;

        extensions = import ./extensions.nix { inherit (pkgs.lib) fakeHash; };

        check = pkgs.writeScriptBin "check" (concatStrings
          (builtins.map
            (e:
              ''
                echo "Building ${e.publisher}.${e.name}"
                nix build --quiet .#${e.publisher}.${e.name}
              '')
            extensions));

        listLocalExtensions = pkgs.writeScriptBin "list" (concatStrings
          (builtins.map
            (e:
              ''
                echo "${e.publisher}.${e.name}"
              '')
            extensions));
      in
      {
        apps = rec {
          default = local;

          local = {
            type = "app";
            program = "${listLocalExtensions}/bin/list";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ check ];
        };

        packages = pkgs.vscode-extensions // builtins.listToAttrs
          (builtins.map
            (e: {
              name = "${e.publisher}";
              value = {
                "${e.name}" = pkgs.vsCodeExtensionHelper {
                  inherit (e) publisher name version sha256;
                };
              };
            })
            extensions);
      }
    );
}
