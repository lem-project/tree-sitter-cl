# tree-sitter-cl Makefile

.PHONY: all clean wrapper test

all: wrapper

# Build the C wrapper library
wrapper:
	$(MAKE) -C c-wrapper

clean:
	$(MAKE) -C c-wrapper clean

# Run tests (requires wrapper to be built first)
test: wrapper
	sbcl --noinform --non-interactive \
		--eval '(ql:quickload :tree-sitter-cl/tests)' \
		--eval '(asdf:test-system :tree-sitter-cl)'
