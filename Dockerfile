FROM golang:1.26-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src
COPY go.mod go.sum ./
COPY internal/ internal/
COPY cmd/legacycoreaget/ cmd/legacycoreaget/
RUN CGO_ENABLED=0 go build -o /legacycoreaget ./cmd/legacycoreaget/

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=builder /legacycoreaget /usr/local/bin/legacycoreaget
RUN mkdir -p /data
EXPOSE 8443
ENTRYPOINT ["legacycoreaget"]
