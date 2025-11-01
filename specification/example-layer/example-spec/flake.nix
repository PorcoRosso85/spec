{
  description = "example spec flake (skeleton)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # NOTE: no path inputs allowed. All inputs must be pin可能 (git url)。
  };

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-darwin" ];
    forAllSystems = f: builtins.listToAttrs (map (system: { name = system; value = f system; }) systems);
  in
  {
    # 任意: importで使わせたい正式なモジュール名。
    meta.cueModulePath = "example.module.path"; # TODO: 実名に置き換え

    # 1. packages.${system}.cueModule
    packages = forAllSystems (system: {
      cueModule = throw "TODO: build pure CUE module for ${system}";
    });

    # 2. apps.vendor
    apps = {
      vendor = {
        type = "app";
        program = ''
          echo "TODO vendor --mode=symlink|copy [--dry-run]"
        ''; # UX契約だけ先に宣言
      };
    };

    # 3. devShells.${system}.default
    devShells = forAllSystems (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.cue
          ];
        };
      }
    );
  };
}
