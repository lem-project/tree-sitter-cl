# tree-sitter-cl

Common Lisp bindings for [tree-sitter](https://tree-sitter.github.io/tree-sitter/), an incremental parsing library.

## Features

- Full FFI bindings to tree-sitter C API
- CLOS wrapper classes with automatic memory management
- Query support with capture extraction
- Dynamic grammar loading from shared libraries
- Support for Nix-style grammar paths

## Requirements

- SBCL (other implementations may work but are untested)
- tree-sitter library (`libtree-sitter.so`)
- CFFI, Alexandria, trivial-garbage, Babel

### Native Dependencies

```bash
# Ubuntu/Debian
sudo apt install libtree-sitter-dev

# macOS
brew install tree-sitter

# Nix
nix-shell -p tree-sitter
```

## Installation

### With Quicklisp (coming soon)

```lisp
(ql:quickload :tree-sitter-cl)
```

### Manual

Clone this repository to your local-projects:

```bash
cd ~/quicklisp/local-projects
git clone https://github.com/lem-project/tree-sitter-cl.git
```

Then load:

```lisp
(ql:quickload :tree-sitter-cl)
```

## Quick Start

```lisp
(ql:quickload :tree-sitter-cl)

;; Check if tree-sitter is available
(ts:tree-sitter-available-p)
;; => T

;; Load a language grammar
(ts:load-language-from-system "json")

;; Parse some JSON
(ts:with-parser (parser "json")
  (let* ((source "{\"key\": [1, 2, 3]}")
         (tree (ts:parser-parse-string parser source))
         (root (ts:tree-root-node tree)))
    ;; Get node information
    (format t "Root type: ~A~%" (ts:node-type root))
    (format t "Children: ~A~%" (ts:node-child-count root))
    ;; Traverse children
    (dolist (child (ts:node-children root))
      (format t "  ~A: ~A-~A~%"
              (ts:node-type child)
              (ts:node-start-byte child)
              (ts:node-end-byte child)))))
```

## Query API

Tree-sitter queries allow pattern matching on syntax trees:

```lisp
;; Compile a query
(let* ((lang (ts:get-language "json"))
       (query (ts:query-compile lang "(string) @str (number) @num")))

  (ts:with-parser (parser "json")
    (let* ((source "{\"name\": \"Alice\", \"age\": 30}")
           (tree (ts:parser-parse-string parser source))
           (root (ts:tree-root-node tree))
           (captures (ts:query-captures query root)))

      (dolist (cap captures)
        (format t "~A: ~A~%"
                (ts:capture-name cap)
                (ts:node-type (ts:capture-node cap)))))))
```

## API Reference

### Parser

| Function | Description |
|----------|-------------|
| `(make-parser &optional language)` | Create a new parser |
| `(parser-set-language parser language)` | Set parser language |
| `(parser-parse-string parser string &optional old-tree)` | Parse a string |
| `(with-parser (var &optional language) &body body)` | Parser with automatic cleanup |

### Tree & Node

| Function | Description |
|----------|-------------|
| `(tree-root-node tree)` | Get root node of tree |
| `(node-type node)` | Get node type as string |
| `(node-start-byte node)` / `(node-end-byte node)` | Byte offsets |
| `(node-start-point node)` / `(node-end-point node)` | Row/column positions |
| `(node-child-count node)` | Number of children |
| `(node-children node)` | List of child nodes |
| `(node-parent node)` | Parent node |
| `(node-string node)` | S-expression representation |

### Query

| Function | Description |
|----------|-------------|
| `(query-compile language source)` | Compile query from S-expression string |
| `(query-captures query node)` | Get all captures |
| `(query-captures-in-range query node start end)` | Get captures in byte range |
| `(capture-name capture)` | Get capture name |
| `(capture-node capture)` | Get captured node |

### Language

| Function | Description |
|----------|-------------|
| `(load-language name path)` | Load grammar from specific path |
| `(load-language-from-system name)` | Load grammar from system paths |
| `(get-language name)` | Get registered language |
| `(list-languages)` | List registered language names |

## C Wrapper

Tree-sitter's C API returns `TSNode` structs by value (24 bytes), which CFFI cannot handle directly. This library includes a small C wrapper (`c-wrapper/ts-wrapper.c`) that provides pointer-based alternatives.

### Building the wrapper

**Using Make (recommended for development):**

```bash
make           # Build the wrapper
make test      # Build and run tests
make clean     # Clean build artifacts
```

The built library (`libts-wrapper.so` or `libts-wrapper.dylib`) will be placed in `c-wrapper/`, which is automatically added to CFFI's search path.

**Manual build:**

```bash
cd c-wrapper
make
```

**With Nix:**

```bash
nix build .#ts-wrapper
```

## Loading Grammars

### From System Path

```lisp
;; Searches LD_LIBRARY_PATH and common locations
(ts:load-language-from-system "json")
```

### From Specific Path

```lisp
(ts:load-language "json" "/path/to/libtree-sitter-json.so")
```

### Nix Integration

When using Nix, add grammar packages to `LD_LIBRARY_PATH`:

```nix
LD_LIBRARY_PATH = lib.makeLibraryPath [
  pkgs.tree-sitter
  pkgs.tree-sitter-grammars.tree-sitter-json
];
```

## Running Tests

```bash
# With Rove
ros run -e '(ql:quickload :tree-sitter-cl/tests)' -e '(rove:run :tree-sitter-cl/tests)'

# Or via ASDF
(asdf:test-system :tree-sitter-cl)
```

Note: Tests require tree-sitter library and JSON grammar to be available.

## License

MIT License. See [LICENSE](LICENSE).

## Acknowledgments

- [tree-sitter](https://tree-sitter.github.io/tree-sitter/) by Max Brunsfeld
- Inspired by tree-sitter bindings in other languages
