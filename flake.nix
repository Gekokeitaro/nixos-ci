{
  description = "OS config entry point";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nvf.url = "github:NotAShelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
    sops-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    updateScript = import ./utils/update-llama-cpp.nix {inherit pkgs;};
  in {
    apps.${system}.update-llama-cpp = {
      type = "app";
      program = "${updateScript}/bin/update-llama-cpp";
    };

    nixosConfigurations = {
      nixos-ci = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nvf.nixosModules.default
          sops-nix.nixosModules.sops
          ./hosts/nixos-ci/configuration.nix
        ];
      };
      nixos-forgejo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nvf.nixosModules.default
          ./hosts/nixos-forgejo/configuration.nix
        ];
      };
      nixos-calibre-web-auto = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nvf.nixosModules.default
          ./hosts/calibre-lxc/configuration.nix
        ];
      };
      nixos-n8n = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nvf.nixosModules.default
          {nixpkgs.config.allowUnfree = true;}
          ./hosts/nixos-n8n/configuration.nix
        ];
      };
      nixos-llamaswap-vulkan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          isLlamacppRocm = false;
          hostName = "nixos-llamaswap-vulkan";
        };
        modules = [
          nvf.nixosModules.default
          ./hosts/llamaswap-lxc/configuration.nix
        ];
      };
      nixos-llamaswap-rocm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          # https://discourse.nixos.org/t/flakes-idiomatic-way-to-pass-inputs-to-configuration-nix/12379/2
          # specialArgs permite pasar valores arbitrarios.
          isLlamacppRocm = true;
          hostName = "nixos-llamaswap-rocm";
        };
        modules = [
          nvf.nixosModules.default
          ./hosts/llamaswap-lxc/configuration.nix
        ];
      };
      nixos-omniroute = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nvf.nixosModules.default
          ./hosts/nixos-omniroute/configuration.nix
        ];
      };
    };
  };
}
