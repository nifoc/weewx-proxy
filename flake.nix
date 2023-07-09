{
  description = "weewx-proxy development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, gitignore, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, lib, self', ... }:
        let
          pname = "weewx-proxy";
          version = "0.0.1";

          erlang = pkgs.beam.interpreters.erlangR26;
          beamPackages = pkgs.beam.packagesWith erlang;
          elixir = beamPackages.elixir_1_15;

          inherit (pkgs.stdenv) isDarwin;
          inherit (gitignore.lib) gitignoreSource;
        in
        {
          devShells.default = pkgs.mkShell {
            packages = (with pkgs; [
              erlang
              elixir

              beamPackages.elixir-ls
              mix2nix
              mosquitto
            ]) ++ lib.optionals isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
            ]);

            ERL_INCLUDE_PATH = "${erlang}/lib/erlang/usr/include";
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
              ExposedPorts = { "4040/tcp" = { }; };
              Entrypoint = [ "${self'.packages.default}/bin/weewx_proxy" ];
              Cmd = [ "start" ];
            };
          };

          apps.default = { type = "app"; program = "${self'.packages.default}/bin/weewx_proxy"; };
        };
    };
}
