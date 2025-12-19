(defsystem "tree-sitter-cl"
  :version "0.1.0"
  :author "Lem Project"
  :maintainer "Lem Project <https://github.com/lem-project>"
  :license "MIT"
  :homepage "https://github.com/lem-project/tree-sitter-cl"
  :source-control (:git "https://github.com/lem-project/tree-sitter-cl.git")
  :bug-tracker "https://github.com/lem-project/tree-sitter-cl/issues"
  :description "Common Lisp bindings for tree-sitter"
  :long-description "FFI bindings to tree-sitter, an incremental parsing library.
Supports parsing, AST traversal, and pattern queries."
  :depends-on ("cffi" "alexandria" "trivial-garbage" "babel")
  :pathname "src"
  :serial t
  :components ((:file "package")
               (:file "ffi")
               (:file "types")
               (:file "parser")
               (:file "node")
               (:file "query")
               (:file "language"))
  :in-order-to ((test-op (test-op "tree-sitter-cl/tests"))))

(defsystem "tree-sitter-cl/tests"
  :depends-on ("tree-sitter-cl" "rove")
  :pathname "tests"
  :components ((:file "main"))
  :perform (test-op (op c) (symbol-call :rove '#:run c)))
