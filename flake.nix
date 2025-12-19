{
  description = "Common Lisp bindings for tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # trivial-glob (not in Quicklisp)
        trivial-glob-src = pkgs.fetchFromGitHub {
          owner = "fukamachi";
          repo = "trivial-glob";
          rev = "0c2675d9452ed164970f2fc4a0e41784ebee819a";
          sha256 = "sha256-XkeQXfKk7zcEuj4Q9eOve4d3hern0kyD2k3IamoZ6/w=";
        };

        # mallet linter source
        mallet-src = pkgs.fetchFromGitHub {
          owner = "fukamachi";
          repo = "mallet";
          rev = "de89ea2c319c703ed3fa8889de70e2abf85a7ce8";
          sha256 = "sha256-ujxSrepDVNq7RJxCfPQeF3owf5aXLEIkTzqIeIx+89o=";
        };

        # Build the C wrapper library
        ts-wrapper = pkgs.stdenv.mkDerivation {
          pname = "ts-wrapper";
          version = "0.1.0";
          src = ./c-wrapper;

          buildInputs = [ pkgs.tree-sitter ];

          buildPhase = ''
            gcc -shared -fPIC -o libts-wrapper.so ts-wrapper.c \
                -I${pkgs.tree-sitter}/include -L${pkgs.tree-sitter}/lib -ltree-sitter
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp libts-wrapper.so $out/lib/
          '';
        };

        # tree-sitter-json grammar for tests
        tree-sitter-json-grammar = pkgs.stdenv.mkDerivation {
          pname = "tree-sitter-json-grammar";
          version = "0.24.8";
          src = pkgs.fetchFromGitHub {
            owner = "tree-sitter";
            repo = "tree-sitter-json";
            rev = "v0.24.8";
            sha256 = "sha256-DNZC2cTy1C8OaMOpEHM6NoRtOIbLaBf0CLXXWCKODlw=";
          };

          buildPhase = ''
            gcc -shared -fPIC -o libtree-sitter-json.so src/parser.c
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp libtree-sitter-json.so $out/lib/
          '';
        };

        # Combined library path for runtime
        libPath = pkgs.lib.makeLibraryPath [
          pkgs.tree-sitter
          ts-wrapper
          tree-sitter-json-grammar
        ];

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.sbcl
            pkgs.tree-sitter
            pkgs.gcc
          ];

          LD_LIBRARY_PATH = libPath;

          shellHook = ''
            export CL_SOURCE_REGISTRY="$PWD//"
          '';
        };

        # For CI: provide library paths and sources
        packages = {
          inherit ts-wrapper tree-sitter-json-grammar;
          trivial-glob = trivial-glob-src;
          mallet-src = mallet-src;
        };

        # Export library path for CI
        lib = {
          inherit libPath trivial-glob-src mallet-src;
        };
      });
}
