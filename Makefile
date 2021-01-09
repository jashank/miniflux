APP := miniflux
VERSION := $(shell git rev-parse --short HEAD)
BUILD_DATE := `date +%FT%T%z`
LD_FLAGS := "-s -w -X 'miniflux.app/version.Version=$(VERSION)' -X 'miniflux.app/version.BuildDate=$(BUILD_DATE)'"
PKG_LIST := $(shell go list ./... | grep -v /vendor/)
DB_URL := postgres://postgres:postgres@localhost/miniflux_test?sslmode=disable

export GO111MODULE=on

.PHONY: generate
.PHONY: miniflux
.PHONY: linux-amd64
.PHONY: linux-armv8
.PHONY: linux-armv7
.PHONY: linux-armv6
.PHONY: linux-armv5
.PHONY: darwin-amd64
.PHONY: freebsd-amd64
.PHONY: openbsd-amd64
.PHONY: windows-amd64
.PHONY: netbsd-amd64
.PHONY: linux-x86
.PHONY: darwin-x86
.PHONY: freebsd-x86
.PHONY: netbsd-x86
.PHONY: openbsd-x86
.PHONY: windows-x86
.PHONY: build run clean test lint integration-test clean-integration-test

ifdef V
Q=
else
Q=@
endif

generate:
	${Q} go generate -mod=vendor

miniflux: generate
	${Q} go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP) main.go

linux-amd64: generate
	${Q} GOOS=linux GOARCH=amd64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-linux-amd64 main.go

linux-armv8: generate
	${Q} GOOS=linux GOARCH=arm64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-linux-armv8 main.go

linux-armv7: generate
	${Q} GOOS=linux GOARCH=arm GOARM=7 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-linux-armv7 main.go

linux-armv6: generate
	${Q} GOOS=linux GOARCH=arm GOARM=6 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-linux-armv6 main.go

linux-armv5: generate
	${Q} GOOS=linux GOARCH=arm GOARM=5 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-linux-armv5 main.go

darwin-amd64: generate
	${Q} GOOS=darwin GOARCH=amd64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-darwin-amd64 main.go

freebsd-amd64: generate
	${Q} GOOS=freebsd GOARCH=amd64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-freebsd-amd64 main.go

openbsd-amd64: generate
	${Q} GOOS=openbsd GOARCH=amd64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-openbsd-amd64 main.go

windows-amd64: generate
	${Q} GOOS=windows GOARCH=amd64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-windows-amd64 main.go

build: linux-amd64 linux-armv8 linux-armv7 linux-armv6 linux-armv5 darwin-amd64 freebsd-amd64 openbsd-amd64 windows-amd64

# NOTE: unsupported targets
netbsd-amd64: generate
	${Q} GOOS=netbsd GOARCH=amd64 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-netbsd-amd64 main.go
	
linux-x86: generate
	${Q} GOOS=linux GOARCH=386 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-linux-x86 main.go

darwin-x86: generate
	${Q} GOOS=darwin GOARCH=386 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-darwin-x86 main.go

freebsd-x86: generate
	${Q} GOOS=freebsd GOARCH=386 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-freebsd-x86 main.go

netbsd-x86: generate
	${Q} GOOS=netbsd GOARCH=386 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-netbsd-x86 main.go

openbsd-x86: generate
	${Q} GOOS=openbsd GOARCH=386 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-freebsd-x86 main.go

windows-x86: generate
	${Q} GOOS=windows GOARCH=386 go build -mod=vendor -ldflags=$(LD_FLAGS) -o $(APP)-windows-x86 main.go

run: generate
	${Q} go run -mod=vendor main.go -debug

clean:
	${Q} rm -f $(APP)-* $(APP)

test:
	go test -mod=vendor -cover -race -count=1 ./...

lint:
	${Q} golint -set_exit_status ${PKG_LIST}

integration-test:
	psql -U postgres -c 'drop database if exists miniflux_test;'
	psql -U postgres -c 'create database miniflux_test;'
	DATABASE_URL=$(DB_URL) go run -mod=vendor main.go -migrate
	DATABASE_URL=$(DB_URL) ADMIN_USERNAME=admin ADMIN_PASSWORD=test123 go run -mod=vendor main.go -create-admin
	go build -mod=vendor -o miniflux-test main.go
	DATABASE_URL=$(DB_URL) ./miniflux-test -debug >/tmp/miniflux.log 2>&1 & echo "$$!" > "/tmp/miniflux.pid"
	while ! echo exit | nc localhost 8080; do sleep 1; done >/dev/null
	go test -mod=vendor -v -tags=integration -count=1 miniflux.app/tests || cat /tmp/miniflux.log

clean-integration-test:
	${Q} kill -9 `cat /tmp/miniflux.pid`
	${Q} rm -f /tmp/miniflux.pid /tmp/miniflux.log
	${Q} rm miniflux-test
	${Q} psql -U postgres -c 'drop database if exists miniflux_test;'
