.PHONY: build clean run test

# Target platform
GOOS ?= linux
GOARCH ?= amd64
CGO_ENABLED ?= 0

BINARY := cotune-bootstrap

build:
	GOOS=$(GOOS) \
	GOARCH=$(GOARCH) \
	CGO_ENABLED=$(CGO_ENABLED) \
	go build -o $(BINARY) main.go

clean:
	rm -f $(BINARY)

run: build
	./$(BINARY)

test:
	go test ./...
