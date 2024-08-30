ifeq ($(OS),Windows_NT)
	LIB_EXT = dll
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		LIB_EXT = so
	endif
	ifeq ($(UNAME_S),Darwin)
		LIB_EXT = dylib
	endif
endif

all:
	@echo $(OSFLAG)

.PHONY: clean
clean:
	rm -rf ./lua/youtrack/lib.so ./lua/youtrack/deps

.PHONY: compile
compile:
	cargo build --release

.PHONY: out
out:
	mkdir -p lua/youtrack/deps
	cp ./target/release/libyoutrack_nvim.$(LIB_EXT) ./lua/youtrack/lib.so
	cp ./target/release/deps/*.rlib ./lua/youtrack/deps/

.PHONY: build
build: clean compile out
