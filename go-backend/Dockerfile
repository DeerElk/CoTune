FROM golang:1.24.6 AS builder
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/cotune-daemon ./cmd/daemon

FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    iproute2 \
    bash \
    jq \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/cotune-daemon /app/cotune-daemon
RUN chmod +x /app/cotune-daemon

EXPOSE 8080
ENTRYPOINT ["/app/cotune-daemon"]

