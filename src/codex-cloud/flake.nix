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
        pkgs = import nixpkgs { inherit system; };

        supported = system == "x86_64-linux";

        supervisorPkg = pkgs.supervisor or pkgs.python3Packages.supervisor;

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
                  pkgs.bash
                  pkgs.git
                  pkgs.zsh
                  pkgs.ripgrep
                  pkgs.gh
                  pkgs.unzip
                  pkgs.socat
                  supervisorPkg
                  pkgs.acl
                  pkgs.curl
                  pkgs.cacert
                  pkgs.neovim
                  pkgs.mise
                  pkgs.opencode
                  pkgs.markdown-oxide
                  pkgs.nodePackages.bash-language-server
                  pkgs.biome
                  pkgs.tombi
                  pkgs.nodePackages.typescript
                  pkgs.nodePackages.typescript-language-server
                  pkgs.yaml-language-server

                  pkgs.docker-client
                  pkgs.docker-compose
                ];
              };
            };
      }
    );
}
