FROM golang:1.24-alpine AS build

WORKDIR /src
COPY go.work ./
COPY backend/go.mod backend/go.sum ./backend/
COPY proto/gen/go/go.mod proto/gen/go/go.sum ./proto/gen/go/
RUN cd backend && go mod download

COPY backend ./backend
COPY proto/gen/go ./proto/gen/go
RUN cd backend && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/seville ./cmd/seville

FROM alpine:3.22
RUN addgroup -S seville && adduser -S -G seville seville
WORKDIR /app
COPY --from=build /out/seville /usr/local/bin/seville
USER seville
EXPOSE 8787
ENTRYPOINT ["seville"]
