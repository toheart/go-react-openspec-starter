FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/app ./cmd

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /bin/app /bin/app
COPY --from=builder /app/etc /etc/app
EXPOSE 8080
ENTRYPOINT ["/bin/app", "server"]
