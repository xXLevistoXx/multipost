#FROM golang:1.24-alpine AS builder
#RUN apk add --no-cache git
#WORKDIR /app
#COPY go.mod go.sum ./
#RUN go mod download
#COPY . .
#RUN go build -o multipost-go ./cmd/main.go
#
#FROM alpine:latest
#RUN apk add --no-cache ca-certificates
#WORKDIR /app
#COPY --from=builder /app/multipost-go .
#EXPOSE 8080
#CMD ["./multipost-go"]
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o multipost-go ./cmd/main.go

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/multipost-go .
EXPOSE 8080
CMD ["./multipost-go"]
