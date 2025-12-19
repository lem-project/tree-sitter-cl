# Makefile for tree-sitter C wrapper

CC ?= gcc
CFLAGS = -shared -fPIC -Wall -Wextra
LDFLAGS = -ltree-sitter

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    LIBEXT = dylib
    CFLAGS += -dynamiclib
else
    LIBEXT = so
endif

TARGET = libts-wrapper.$(LIBEXT)

.PHONY: all clean install

all: $(TARGET)

$(TARGET): ts-wrapper.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m 644 $(TARGET) $(DESTDIR)$(PREFIX)/lib/
