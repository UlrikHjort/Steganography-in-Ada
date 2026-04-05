# ===========================================================================
#  Steganography -Makefile
# ===========================================================================

BINARY   := steg
PROJECT  := steg.gpr
CONFIG   := steg.cgpr

# Detect the system C compiler (prefer gcc, fall back to cc)
CC       := $(shell which gcc 2>/dev/null || which cc)

.PHONY: all config build clean distclean help

all: build

# ---------------------------------------------------------------------------
#  config -generate the GPRbuild compiler configuration
#  Always uses the system gcc for C so we avoid any IDE-bundled compiler.
# ---------------------------------------------------------------------------
config: $(CONFIG)

$(CONFIG):
	@echo "[config] Generating $(CONFIG) using C compiler: $(CC)"
	gprconfig --batch \
	  --config=Ada \
	  --config=C,,$(CC) \
	  --target=x86_64-linux-gnu \
	  -o $(CONFIG)
	@# Replace any non-system C compiler that gprconfig may have found
	@# (e.g. a CLion-bundled clang) with the one we actually want.
	sed -i 's|for Driver *("C") use ".*"|for Driver              ("C") use "$(CC)"|' $(CONFIG)
	@echo "[config] Done."

# ---------------------------------------------------------------------------
#  build -compile and link
# ---------------------------------------------------------------------------
build: $(CONFIG)
	@echo "[build] Building $(BINARY)..."
	gprbuild --config=$(CONFIG) -P $(PROJECT)
	@echo "[build] Binary: ./$(BINARY)"

# ---------------------------------------------------------------------------
#  clean -remove object files and the compiled binary
# ---------------------------------------------------------------------------
clean:
	@echo "[clean] Removing object files and binary..."
	gprclean --config=$(CONFIG) -P $(PROJECT) 2>/dev/null || true
	rm -rf obj/
	rm -f $(BINARY)

# ---------------------------------------------------------------------------
#  distclean -clean + remove the generated compiler config
# ---------------------------------------------------------------------------
distclean: clean
	@echo "[distclean] Removing $(CONFIG)..."
	rm -f $(CONFIG)

# ---------------------------------------------------------------------------
#  help
# ---------------------------------------------------------------------------
help:
	@echo "Targets:"
	@echo "  make           -configure (if needed) and build"
	@echo "  make config    -generate $(CONFIG)"
	@echo "  make build     -compile and link"
	@echo "  make clean     -remove objects and binary"
	@echo "  make distclean -clean + remove $(CONFIG)"
