#!/usr/bin/make -f

export GO111MODULE=on

BUILD_DIR ?= $(CURDIR)/build
LOCAL_DIR ?= $(CURDIR)/local
CHORA_CMD := $(CURDIR)/cmd/chora

BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT := $(shell git log -1 --format='%H')

ifeq (,$(VERSION))
  VERSION := $(shell git describe --exact-match 2>/dev/null)
  ifeq (,$(VERSION))
    VERSION := $(BRANCH)-$(COMMIT)
  endif
endif

SDK_VERSION := $(shell go list -m github.com/cosmos/cosmos-sdk | sed 's:.* ::')

LEDGER_ENABLED ?= true

###############################################################################
###                            Build Tags/Flags                             ###
###############################################################################

# process build tags

build_tags = netgo

ifeq ($(LEDGER_ENABLED),true)
  ifeq ($(OS),Windows_NT)
    GCCEXE = $(shell where gcc.exe 2> NUL)
    ifeq ($(GCCEXE),)
      $(error gcc.exe not installed for ledger support, please install or set LEDGER_ENABLED=false)
    else
      build_tags += ledger
    endif
  else
    UNAME_S = $(shell uname -s)
    ifeq ($(UNAME_S),OpenBSD)
      $(warning OpenBSD detected, disabling ledger support (https://github.com/cosmos/cosmos-sdk/issues/1988))
    else
      GCC = $(shell command -v gcc 2> /dev/null)
      ifeq ($(GCC),)
        $(error gcc not installed for ledger support, please install or set LEDGER_ENABLED=false)
      else
        build_tags += ledger
      endif
    endif
  endif
endif

build_tags += $(BUILD_TAGS)
build_tags := $(strip $(build_tags))

# process linker flags

empty :=
whitespace := $(empty) $(empty)
comma := ,
build_tags_comma_sep := $(subst $(whitespace),$(comma),$(build_tags))

ldflags = \
	-X github.com/cosmos/cosmos-sdk/version.Name=chora \
	-X github.com/cosmos/cosmos-sdk/version.AppName=chora \
	-X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
	-X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
	-X github.com/cosmos/cosmos-sdk/version.BuildTags=$(build_tags_comma_sep)

ifeq ($(NO_STRIP),false)
  ldflags += -w -s
endif

ldflags += $(LD_FLAGS)
ldflags := $(strip $(ldflags))

# set build flags

BUILD_FLAGS := -tags '$(build_tags)' -ldflags '$(ldflags)'

ifeq ($(NO_STRIP),false)
  BUILD_FLAGS += -trimpath
endif

###############################################################################
###                             Build / Install                             ###
###############################################################################

all: build

build: go.sum go-version
	@mkdir -p $(BUILD_DIR)
	go build -mod=readonly -o $(BUILD_DIR) $(BUILD_FLAGS) $(CHORA_CMD)

install: go.sum go-version
	go install -mod=readonly $(BUILD_FLAGS) $(CHORA_CMD)

.PHONY: build install

###############################################################################
###                                Localnet                                 ###
###############################################################################

local:
	@./scripts/localnet.sh -h $(LOCAL_DIR)

.PHONY: local

###############################################################################
###                               Go Modules                                ###
###############################################################################

go.sum: go.mod
	@echo "Ensuring app dependencies have not been modified..."
	go mod verify
	go mod tidy

verify:
	@echo "Verifying all go module dependencies..."
	@find . -name 'go.mod' -type f -execdir go mod verify \;

tidy:
	@echo "Cleaning up all go module dependencies..."
	@find . -name 'go.mod' -type f -execdir go mod tidy \;

.PHONY: verify tidy

###############################################################################
###                             Lint / Format                               ###
###############################################################################

lint:
	@echo "Linting all go modules..."
	@find . -name 'go.mod' -type f -execdir golangci-lint run --out-format=tab \;

lint-fix: format
	@echo "Attempting to fix lint errors in all go modules..."
	@find . -name 'go.mod' -type f -execdir golangci-lint run --fix --out-format=tab --issues-exit-code=0 \;

format_filter = -name '*.go' -not -name 'statik.go' -type f

format:
	@echo "Formatting all go modules..."
	@find . $(format_filter) | xargs gofmt -s -w
	@find . $(format_filter) | xargs goimports -w -local github.com/chora-io/chora
	@find . $(format_filter) | xargs misspell -w

.PHONY: lint lint-fix format

###############################################################################
###                               Go Version                                ###
###############################################################################

GO_MAJOR_VERSION = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f1)
GO_MINOR_VERSION = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f2)
MIN_GO_MAJOR_VERSION = 1
MIN_GO_MINOR_VERSION = 22
GO_VERSION_ERROR = Golang version $(GO_MAJOR_VERSION).$(GO_MINOR_VERSION) is not supported, \
please update to at least $(MIN_GO_MAJOR_VERSION).$(MIN_GO_MINOR_VERSION)

go-version:
	@echo "Verifying go version..."
	@if [ $(GO_MAJOR_VERSION) -gt $(MIN_GO_MAJOR_VERSION) ]; then \
		exit 0; \
	elif [ $(GO_MAJOR_VERSION) -lt $(MIN_GO_MAJOR_VERSION) ]; then \
		echo $(GO_VERSION_ERROR); \
		exit 1; \
	elif [ $(GO_MINOR_VERSION) -lt $(MIN_GO_MINOR_VERSION) ]; then \
		echo $(GO_VERSION_ERROR); \
		exit 1; \
	fi

.PHONY: go-version

###############################################################################
###                                  Tools                                  ###
###############################################################################

tools: go-version
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/client9/misspell/cmd/misspell@latest
	go install golang.org/x/tools/cmd/goimports@latest

.PHONY: tools

###############################################################################
###                                  Tests                                  ###
###############################################################################

CURRENT_DIR=$(shell pwd)
GO_MODULES=$(shell find . -type f -name 'go.mod' -print0 | xargs -0 -n1 dirname | sort)

test: test-all

test-all:
	@for module in $(GO_MODULES); do \
		echo "Testing Module $$module"; \
		cd ${CURRENT_DIR}/$$module; \
		go test ./...; \
	done

test-app:
	@echo "Testing Module ."
	@go test ./... \
		-coverprofile=coverage-app.out -covermode=atomic

test-coverage:
	@cat coverage*.out | grep -v "mode: atomic" >> coverage.txt

test-clean:
	@go clean -testcache
	@find . -name 'coverage.txt' -delete
	@find . -name 'coverage*.out' -delete

.PHONY: test test-all test-app test-coverage test-clean

###############################################################################
###                              Documentation                              ###
###############################################################################

docs:
	@echo "Wait a few seconds and then visit http://localhost:6060/pkg/github.com/chora-io/chora/"
	godoc -http=:6060

.PHONY: docs

###############################################################################
###                                 Swagger                                 ###
###############################################################################

swagger:
	@./scripts/swagger.sh

.PHONY: swagger

###############################################################################
###                                 Clean                                   ###
###############################################################################

clean: test-clean
	@rm -rf $(BUILD_DIR)
	@rm -rf $(LOCAL_DIR)

.PHONY: clean
