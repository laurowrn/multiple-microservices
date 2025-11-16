FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o user_service ./

FROM scratch

WORKDIR /app

COPY --from=builder /app .

EXPOSE 3001

CMD ["./user_service"]