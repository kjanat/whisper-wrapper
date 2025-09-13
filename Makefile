SHELL := /bin/bash

GO ?= go
LINT ?= golangci-lint

BINARY := whisper-wrapper
CMD_DIR := cmd/whisper-wrapper
OUT := bin/$(BINARY)
COMPDIR := completions
# Collect Go sources without using `go list -f` to avoid template parsing issues
SRC := $(shell find $(CMD_DIR) -type f -name '*.go')

.PHONY: all build install tidy fmt lint clean completions completion-bash completion-zsh completion-fish completion-powershell help

all: build

build: $(OUT)

$(OUT): go.mod $(SRC)
	@mkdir -p bin
	$(GO) build -o $(OUT) ./$(CMD_DIR)

install:
	$(GO) install ./$(CMD_DIR)

tidy:
	$(GO) mod tidy

fmt:
	$(GO) fmt ./...

lint:
	$(LINT) run

clean:
	rm -rf $(OUT) $(COMPDIR)

completions: completion-bash completion-zsh completion-fish completion-powershell

completion-bash: build
	@mkdir -p $(COMPDIR)
	$(OUT) completion bash > $(COMPDIR)/$(BINARY).bash

completion-zsh: build
	@mkdir -p $(COMPDIR)
	$(OUT) completion zsh > $(COMPDIR)/_$(BINARY)

completion-fish: build
	@mkdir -p $(COMPDIR)
	$(OUT) completion fish > $(COMPDIR)/$(BINARY).fish

completion-powershell: build
	@mkdir -p $(COMPDIR)
	$(OUT) completion powershell > $(COMPDIR)/$(BINARY).ps1

help:
	@echo "Targets:"
	@echo "  build            Build $(OUT)"
	@echo "  install          go install to GOBIN"
	@echo "  tidy             go mod tidy"
	@echo "  fmt              go fmt ./..."
	@echo "  lint             golangci-lint run"
	@echo "  completions      Generate completion scripts into $(COMPDIR)/"
	@echo "  clean            Remove build artifacts"
