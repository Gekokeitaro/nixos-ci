{
  description = "OS config entry point";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nvf.url = "github:NotAShelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
    ...
  } @ inputs: {
    nixosConfigurations.nixos-llamaswap-vulkan = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        # https://discourse.nixos.org/t/flakes-idiomatic-way-to-pass-inputs-to-configuration-nix/12379/2
        # specialArgs permite pasar valores arbitrarios.
        isLlamacppRocm = false;
      };
      modules = [
        nvf.nixosModules.default
        ./configuration.nix
      ];
    };
    nixosConfigurations.nixos-llamaswap-rocm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        isLlamacppRocm = true;
      };
      modules = [
        nvf.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
