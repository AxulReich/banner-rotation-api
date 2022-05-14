export GO111MODULE=on
export GOSUMDB=off

GOPATH?=$(HOME)/go
LOCAL_BIN:=$(CURDIR)/bin
PROTOGEN_BIN:=$(LOCAL_BIN)/protogen
MINIMOCK_BIN:=$(LOCAL_BIN)/minimock
MINIMOCK_TAG:=3.0.10
GOLANGCI_BIN:=$(LOCAL_BIN)/golangci-lint
GOLANGCI_TAG:=1.42.1


# install golangci-lint binary
.PHONY: install-lint
install-lint:
ifeq ($(wildcard $(GOLANGCI_BIN)),)
	$(info #Downloading golangci-lint v$(GOLANGCI_TAG))
	GOBIN=$(LOCAL_BIN) go install github.com/golangci/golangci-lint/cmd/golangci-lint@v$(GOLANGCI_TAG)
GOLANGCI_BIN:=$(LOCAL_BIN)/golangci-lint
endif

# run diff lint like in pipeline
.PHONY: .lint
.lint: install-lint
	$(info #Running lint...)
	$(GOLANGCI_BIN) run --config=.golangci.yaml ./...

# install minimock binary
.PHONY: install-minimock
install-minimock:
ifeq ($(wildcard $(MINIMOCK_BIN)),)
	$(info #Downloading minimock v$(MINIMOCK_TAG))
	tmp=$$(mktemp -d) && cd $$tmp && pwd && go mod init temp && go get -d github.com/gojuno/minimock/v3/cmd/minimock@v$(MINIMOCK_TAG) && \
		go build -ldflags "-X 'main.version=$(MINIMOCK_TAG)' -X 'main.commit=test' -X 'main.buildDate=test'" -o $(LOCAL_BIN)/minimock github.com/gojuno/minimock/v3/cmd/minimock && \
		rm -rf $$tmp
endif

.PHONY: generate
.generate:
	protoc \
		-I vendor \
		--plugin=bin/protoc-gen-validate \
		--plugin=bin/protoc-gen-grpc \
		--plugin=bin/protoc-gen-grpc-gateway \
		--plugin=bin/protoc-gen-swagger \
		--plugin=bin/protoc-gen-go \
	    --proto_path=api \
		--proto_path=proto_dep \
		--go_out=pkg/api \
		--go-grpc_out=pkg/api \
		--grpc-gateway_out=logtostderr=true:pkg/api \
		--validate_out=lang=go:pkg/api \
		--swagger_out=logtostderr=true:pkg/api \
		api/*.proto

