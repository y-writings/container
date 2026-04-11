{
  description = "Docker CLI/Compose + dev tools bundle for Codex Cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        lib = nixpkgs.lib;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: lib.getName pkg == "terraform";
        };

        supported = system == "x86_64-linux";

      in
      {
        packages =
          if !supported then
            { }
          else
            {
              devtools = pkgs.buildEnv {
                name = "devtools";
                pathsToLink = [ "/bin" ];
                paths = [
                  pkgs.markdown-oxide
                  pkgs.nodePackages.bash-language-server
                  pkgs.biome
                  pkgs.tombi
                  pkgs.terraform
                  pkgs.nodePackages.typescript
                  pkgs.nodePackages.typescript-language-server
                  pkgs.yaml-language-server
                ];
              };
            };
      }
    );
}
