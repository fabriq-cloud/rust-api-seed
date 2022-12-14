FROM rust:latest AS builder

ARG SERVICE_UID=10001

RUN apt update && apt upgrade -y
RUN apt install -y cmake

# unprivileged identity to run service as
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${SERVICE_UID}" \
    service

WORKDIR /app

COPY ./ .

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN update-ca-certificates

RUN cargo build --target x86_64-unknown-linux-musl --release

#############################################################x#######################################
## Final api container image
####################################################################################################
FROM alpine:latest AS api

# Import service user and group from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /app

# Install glibc
# RUN apk --update add libstdc++ curl ca-certificates
# RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
# RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk
# RUN apk add glibc-2.35-r0.apk

# Copy our build
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/api /app/api

# Use the unprivileged service user during execution.
USER service::service

CMD ["./api"]
