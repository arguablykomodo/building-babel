{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    wasm4-nix.url = "github:rutrum/wasm4-nix";
    wasm4-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [ inputs.self.packages.${system}.default ];
        packages = [
          pkgs.zls
        ];
      };
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "building-babel";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = with pkgs; [
          zig
          inputs.wasm4-nix.packages.${system}.w4
        ];
        dontSetZigDefaultFlags = true;
        zigBuildFlags = [ "-Doptimize=ReleaseSmall" ];
      };
    };
}
