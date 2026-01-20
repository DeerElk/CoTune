# Protobuf Generated Code

Этот каталог содержит сгенерированный Go код из `../cotune.proto`.

## Генерация кода

Для генерации Go кода из proto файла выполните:

### Linux/macOS
```bash
cd go-backend
./generate_proto.sh
```

### Windows
```cmd
cd go-backend
generate_proto.bat
```

## Требования

- `protoc` (Protocol Buffers compiler) — https://grpc.io/docs/protoc-installation/
- `protoc-gen-go` плагин: `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest`
- `protoc-gen-go-grpc` плагин: `go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest`

## Структура

После генерации код находится в:
- `api/proto/cotune.pb.go` — сгенерированные структуры protobuf
- `api/proto/cotune_grpc.pb.go` — сгенерированный gRPC код

Импорт в Go: `github.com/cotune/go-backend/api/proto`

## Использование

Сгенерированный код используется в:
- `internal/api/proto/server.go` — Protobuf/gRPC сервер
- `cmd/daemon/main.go` — Инициализация IPC сервера
