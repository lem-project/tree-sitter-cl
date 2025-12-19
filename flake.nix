{
  description = "Common Lisp bindings for tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Quicklisp dependencies
        qlDeps = with pkgs.sbclPackages; [
          cffi
          alexandria
          trivial-garbage
          babel
          rove
        ];

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
            sha256 = "sha256-aKA5ZxdpuJaSpaBppkL3m0EzgDiT2NXCP3av7irNjvA=";
          };

          buildPhase = ''
            cd src
            gcc -shared -fPIC -o libtree-sitter-json.so parser.c
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp src/libtree-sitter-json.so $out/lib/
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
          ] ++ qlDeps;

          LD_LIBRARY_PATH = libPath;

          shellHook = ''
            export CL_SOURCE_REGISTRY="$PWD//:$CL_SOURCE_REGISTRY"
          '';
        };

        # For CI: run tests
        checks.default = pkgs.stdenv.mkDerivation {
          pname = "tree-sitter-cl-tests";
          version = "0.1.0";
          src = ./.;

          buildInputs = [
            pkgs.sbcl
            pkgs.tree-sitter
          ] ++ qlDeps;

          buildPhase = ''
            export HOME=$(mktemp -d)
            export LD_LIBRARY_PATH="${libPath}"
            export CL_SOURCE_REGISTRY="$PWD//"

            sbcl --non-interactive \
                 --eval '(require :asdf)' \
                 --eval '(asdf:load-system :tree-sitter-cl/tests)' \
                 --eval '(let ((result (rove:run :tree-sitter-cl/tests))) (unless result (uiop:quit 1)))'
          '';

          installPhase = ''
            mkdir -p $out
            echo "Tests passed" > $out/result.txt
          '';
        };

        packages = {
          inherit ts-wrapper tree-sitter-json-grammar;
        };
      });
}
