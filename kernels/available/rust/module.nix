{
  self,
  system,
  config,
  lib,
  ...
}: let
  inherit (lib) types;

  kernelName = "rust";
  kernelOptions = {
    config,
    name,
    ...
  }: let
    args = {inherit self system lib config name kernelName;};
    kernelModule = import ./../../../modules/kernel.nix args;
  in {
    options =
      {
        requiredRuntimePackages = lib.mkOption {
          type = types.listOf types.package;
          default = [
            config.nixpkgs.legacyPackages.${system}.cargo
            config.nixpkgs.legacyPackages.${system}.gcc
            config.nixpkgs.legacyPackages.${system}.binutils-unwrapped
          ];
          description = ''
            A list of runtime packages required by ${kernelName} kernel.
          '';
        };

        evcxr = lib.mkOption {
          type = types.package;
          default = config.nixpkgs.legacyPackages.${system}.evcxr;
          description = lib.mdDoc ''
            An evaluation context for Rust.
          '';
        };

        rust-overlay = lib.mkOption {
          type = types.path;
          default = self.inputs.rust-overlay;
          example = ''
            self.inputs.rust-overlay
          '';
          description = lib.mdDoc ''
            An overlay for binary distributed rust toolchains. Adds `rust-bin` to nixpkgs which is needed for the Rust kernel.
          '';
        };
      }
      // kernelModule.options;
    config = lib.mkIf config.enable {
      kernelArgs =
        kernelModule.kernelArgs
        // {
          inherit (config) requiredRuntimePackages evcxr rust-overlay;
          pkgs = import config.nixpkgs {
            inherit system;
            overlays = [config.rust-overlay.overlays.default];
          };
        };
    };
  };
in {
  options.kernel.${kernelName} = lib.mkOption {
    type = types.attrsOf (types.submodule kernelOptions);
    default = {};
    example = ''
      {
        kernel.${kernelName}."example".enable = true;
      }
    '';
    description = lib.mdDoc ''
      A ${kernelName} kernel for IPython.
    '';
  };
}