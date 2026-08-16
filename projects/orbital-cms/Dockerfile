# syntax=docker/dockerfile:1

FROM nixos/nix:2.34.2 AS build

WORKDIR /source
COPY projects/orbital-cms/ /source/
COPY projects/web-middleware/ /web-middleware/

RUN nix --extra-experimental-features "nix-command flakes" build \
      --override-input web-middleware path:/web-middleware \
      --out-link /tmp/orbital-cms \
      .#default \
 && nix --extra-experimental-features "nix-command flakes" build \
      --override-input web-middleware path:/web-middleware \
      --out-link /tmp/orbital-cms-migrate \
      .#migrate \
 && nix --extra-experimental-features "nix-command flakes" build \
      --override-input web-middleware path:/web-middleware \
      --out-link /tmp/cacert \
      .#cacert \
 && mkdir -p /runtime/bin /runtime/etc/ssl/certs \
 && cp -a --parents $(nix-store -qR /tmp/orbital-cms /tmp/orbital-cms-migrate) /runtime \
 && ln -s "$(readlink -f /tmp/orbital-cms)/bin/orbital-cms" /runtime/bin/orbital-cms \
 && ln -s "$(readlink -f /tmp/orbital-cms-migrate)/bin/orbital-cms-migrate" /runtime/bin/orbital-cms-migrate \
 && cp -L /tmp/cacert/etc/ssl/certs/ca-bundle.crt /runtime/etc/ssl/certs/ca-certificates.crt \
 && printf '%s\n' 'hosts: files dns' > /runtime/etc/nsswitch.conf \
 && printf '%s\n' 'orbital:x:65532:65532:Orbital CMS:/nonexistent:/sbin/nologin' > /runtime/etc/passwd \
 && printf '%s\n' 'orbital:x:65532:' > /runtime/etc/group

FROM scratch

COPY --from=build /runtime/ /

ENV HOST="0.0.0.0" \
    PORT="8080" \
    DATABASE_POOL_SIZE="8" \
    SHUTDOWN_TIMEOUT_SECONDS="30" \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

USER 65532:65532
EXPOSE 8080
CMD ["/bin/orbital-cms"]
