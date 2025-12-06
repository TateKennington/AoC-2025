{
  description = "Simple Docker Flake project";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dev_deps = [
            pkgs.picat
            pkgs.neovim
            pkgs.coreutils
        ];

        image = pkgs.dockerTools.buildImage {
          name = "aoc-dev-container";
          tag = "latest";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = dev_deps;
          };
          config = {
            Cmd = [ "${pkgs.bash}/bin/bash" ];
            Env = [
                "HOME=/root"
            ];
          };
          created = "now";
        };
      in {
        packages.hello = image;

        # Add a run script
        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "run-container" ''
            ${pkgs.podman}/bin/podman load < ${image}
            ${pkgs.podman}/bin/podman run -it --rm -v "$(pwd):/aoc" -w /aoc aoc-dev-container
          '');
        };

        devShells.default =
          pkgs.mkShell { buildInputs = dev_deps; };
      });
}
