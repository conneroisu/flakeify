{
  pkgs,
  lib,
  # config,
  inputs,
  ...
}: let
  unstable-pkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    overlays = [];
  };
in {
  name = "flakeify";

  devcontainer = {
    enable = true;
    settings.customizations.vscode.extensions = [
      "github.copilot"
      "github.codespaces"
      "ms-python.vscode-pylance"
      "ms-python.python"
      "ms-python.isort"
      "golang.go"
      "redhat.vscode-yaml"
      "redhat.vscode-xml"
      "visualstudioexptteam.vscodeintellicode"
      "bradlc.vscode-tailwindcss"
      "christian-kohler.path-intellisense"
      "supermaven.supermaven"
      "jnoortheen.nix-ide"
      "mkhl.direnv"
      "tamasfe.even-better-toml"
      "eamodio.gitlens"
      "streetsidesoftware.code-spell-checker"
      "editorconfig.editorconfig"
    ];
  };
  languages = {
    nix.enable = true;
    go = {
      enable = true;
      package = unstable-pkgs.go;
    };
  };

  git-hooks = {
    hooks = {
      gofmt.enable = true;
      alejandra.enable = true;
    };
  };

  enterShell =
    ''
      git status
      git log HEAD..origin/main --oneline
      export REPO_ROOT=$(git rev-parse --show-toplevel)
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.tbb}/lib:${pkgs.llvmPackages.openmp}/lib:${pkgs.openblas}/lib:$LD_LIBRARY_PATH
      export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
      export OPENBLAS=${pkgs.openblas}
      print $SHELL
    ''
    + lib.optionalString pkgs.stdenv.isLinux ''
      export PHONEMIZER_ESPEAK_LIBRARY="$REPO_ROOT/.devenv/profile/lib/libespeak-ng.so"
    ''
    + lib.optionalString pkgs.stdenv.isDarwin ''
      export PHONEMIZER_ESPEAK_LIBRARY="$REPO_ROOT/.devenv/profile/lib/libespeak-ng.dylib";
    '';

  enterTest = ''
    echo "Running tests"
    nix flake check --no-pure-eval --all-systems
  '';

  cachix.enable = true;

  # https://devenv.sh/packages/
  packages =
    (with pkgs; [
      templ
      doppler
      buf
      alejandra
      isort
      sqldiff
      uv
      podman
      esbuild
      buf
      black
      pprof
      golangci-lint
      golangci-lint-langserver
      revive
      gomarkdoc
      gotests
      gotools
      grpcurl
      sqlc
      flyctl
      air
      espeak-ng
      wireguard-tools
      ffmpeg
      protols
      grpc-tools
      protoc-gen-go
      protoc-gen-go-grpc
      protoc-gen-doc
      clang
      libclang
      watchexec

      openssl.dev
      meson
      gfortran
      openblasCompat
      openblas
      ffmpeg
      pkg-config
      stdenv.cc.cc.lib # This provides libstdc++
      cudatoolkit
      zlib # Provides libz
      tbb # Intel Threading Building Blocks
      llvmPackages.openmp # OpenMP support
    ])
    ++ (
      if pkgs.stdenv.isDarwin
      then
        (with pkgs.darwin.apple_sdk; [
          frameworks.SystemConfiguration
        ])
      else []
    );

  scripts = {
    generate-all.exec = ''
      cd $REPO_ROOT
      go generate -v ./...
      cd -
    '';
  };
}
