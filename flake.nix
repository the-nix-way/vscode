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

        extensions = import ./extensions.nix;

        check = pkgs.writeScriptBin "check" (concatStrings (builtins.map (e: "nix build .#${e.publisher}.${e.name}\n") extensions));
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ check ];
        };

        overlays.default = self: super: {
          vscode-extensions = super.vscode-extensions // self.packages;
        };

        packages = builtins.listToAttrs (builtins.map
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
