{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    overlay = final: prev: {
      flakeify = prev.buildGoModule {
        pname = "sqlcquash";
        version = "0.1.0";
        src = ./.;
        vendorHash = "";
      };
    };
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [overlay];
        };
      in {
        packages = {
          inherit (pkgs) sqlcquash;
          default = pkgs.sqlcquash;
        };
      }
    )
    // {
      overlays.default = overlay;
    };
}
