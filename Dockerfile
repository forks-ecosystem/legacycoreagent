FROM golang:1.26-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src
COPY go.mod go.sum ./
COPY internal/ internal/
COPY cmd/legacycoreagent/ cmd/legacycoreagent/
RUN CGO_ENABLED=0 go build -o /legacycoreagent ./cmd/legacycoreagent/

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=builder /legacycoreagent /usr/local/bin/legacycoreagent
RUN mkdir -p /data
EXPOSE 8443
ENTRYPOINT ["legacycoreagent"]
