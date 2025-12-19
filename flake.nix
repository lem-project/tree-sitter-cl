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

        # trivial-glob (not in nixpkgs)
        trivial-glob-src = pkgs.fetchFromGitHub {
          owner = "fukamachi";
          repo = "trivial-glob";
          rev = "0c2675d9452ed164970f2fc4a0e41784ebee819a";
          sha256 = "sha256-XkeQXfKk7zcEuj4Q9eOve4d3hern0kyD2k3IamoZ6/w=";
        };

        # mallet linter
        mallet-src = pkgs.fetchFromGitHub {
          owner = "fukamachi";
          repo = "mallet";
          rev = "de89ea2c319c703ed3fa8889de70e2abf85a7ce8";
          sha256 = "sha256-ujxSrepDVNq7RJxCfPQeF3owf5aXLEIkTzqIeIx+89o=";
        };

        mallet = pkgs.stdenv.mkDerivation {
          pname = "mallet";
          version = "0.1.1";
          src = mallet-src;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          buildInputs = [
            pkgs.sbcl
          ] ++ (with pkgs.sbclPackages; [
            alexandria
            cl-ppcre
            eclector
          ]);

          buildPhase = ''
            export HOME=$(mktemp -d)
            export CL_SOURCE_REGISTRY="${trivial-glob-src}//:$PWD//"

            sbcl --noinform --non-interactive \
                 --eval '(require :asdf)' \
                 --eval '(asdf:load-system :mallet)' \
                 --eval '(asdf:make :mallet)'
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp mallet $out/bin/mallet-unwrapped
            makeWrapper $out/bin/mallet-unwrapped $out/bin/mallet \
              --set SBCL_HOME "${pkgs.sbcl}/lib/sbcl"
          '';
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

        checks = {
          # Run tests
          test = pkgs.stdenv.mkDerivation {
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

          # Run mallet linter
          lint = pkgs.stdenv.mkDerivation {
            pname = "tree-sitter-cl-lint";
            version = "0.1.0";
            src = ./.;

            buildInputs = [ mallet ];

            buildPhase = ''
              mallet src/ *.asd
            '';

            installPhase = ''
              mkdir -p $out
              echo "Lint passed" > $out/result.txt
            '';
          };
        };

        packages = {
          inherit ts-wrapper tree-sitter-json-grammar mallet;
        };
      });
}
