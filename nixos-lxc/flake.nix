{
  description = "OS config entry point";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
    sops-nix,
    ...
  } @ inputs: {
    nixosConfigurations.nixos-ci = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        nvf.nixosModules.default
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];
    };
  };
}
