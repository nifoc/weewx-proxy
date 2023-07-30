{
  description = "weewx-proxy development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Tools

    flake-parts.url = "github:hercules-ci/flake-parts";

    flake-root.url = "github:srid/flake-root";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.gitignore.follows = "gitignore";
    };
  };

  outputs = inputs@{ flake-parts, gitignore, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      imports = [
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      perSystem = { pkgs, config, lib, self', ... }:
        let
          pname = "weewx-proxy";
          version = "0.0.1";

          erlang = pkgs.beam.interpreters.erlangR26;
          beamPackagesPrev = pkgs.beam.packagesWith erlang;
          elixir = beamPackagesPrev.elixir_1_15;

          beamPackages = beamPackagesPrev // rec {
            inherit erlang elixir;
            hex = beamPackagesPrev.hex.override { inherit elixir; };
            buildMix = beamPackagesPrev.buildMix.override { inherit elixir erlang hex; };
            mixRelease = beamPackagesPrev.mixRelease.override { inherit erlang elixir; };
          };

          inherit (pkgs.stdenv) isDarwin;
          inherit (gitignore.lib) gitignoreSource;
        in
        {
          treefmt = {
            inherit (config.flake-root) projectRootFile;
            flakeCheck = false;

            programs = {
              mix-format = {
                enable = true;
                package = elixir;
              };

              nixpkgs-fmt.enable = true;
              shfmt.enable = true;
            };
          };

          pre-commit = {
            check.enable = false;

            settings = {
              excludes = [ "mix.nix" ];

              hooks = {
                deadnix.enable = true;
                statix.enable = true;
                treefmt.enable = true;
              };
            };
          };

          packages.default = beamPackages.mixRelease {
            inherit pname version;

            src = gitignoreSource ./.;
            mixNixDeps = import ./mix.nix { inherit lib beamPackages; };
          };

          packages.container = pkgs.dockerTools.buildLayeredImage {
            name = pname;
            tag = "v${version}";
            config = {
              Env = [
                "LANG=C.UTF-8"
              ];
              ExposedPorts = { "4040/tcp" = { }; };
              Entrypoint = [ "${self'.packages.default}/bin/weewx_proxy" ];
              Cmd = [ "start" ];
            };
          };

          apps.default = { type = "app"; program = "${self'.packages.default}/bin/weewx_proxy"; };

          devShells.default = pkgs.mkShell {
            name = pname;

            nativeBuildInputs = [
              erlang
              elixir
            ] ++ lib.optionals isDarwin (with pkgs.darwin.apple_sdk.frameworks;
              [
                CoreFoundation
                CoreServices
              ]);

            packages = [
              beamPackages.elixir-ls
              pkgs.mix2nix
              pkgs.mosquitto
            ];

            inputsFrom = [
              config.flake-root.devShell
              config.treefmt.build.devShell
              config.pre-commit.devShell
            ];

            ERL_INCLUDE_PATH = "${erlang}/lib/erlang/usr/include";
            TREEFMT_CONFIG_FILE = config.treefmt.build.configFile;
          };
        };
    };
}
