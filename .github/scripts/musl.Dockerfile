FROM ruby:3.2-alpine3.23 AS ruby32
FROM ruby:3.3-alpine3.23 AS ruby33
FROM ruby:3.4-alpine3.23 AS ruby34
FROM ruby:4.0-alpine3.23 AS ruby40

FROM rust:1.100.0-alpine3.23

RUN apk add --no-cache bash build-base clang21-dev gdbm-dev git gmp-dev libffi-dev linux-headers openssl-dev readline-dev yaml-dev zlib-dev

COPY --from=ruby32 /usr/local/ /opt/rubies/3.2/
COPY --from=ruby33 /usr/local/ /opt/rubies/3.3/
COPY --from=ruby34 /usr/local/ /opt/rubies/3.4/
# Rake Compiler needs separate paths for its host and target Ruby.
COPY --from=ruby40 /usr/local/ /opt/rubies/4.0/
COPY --from=ruby40 /usr/local/ /usr/local/

RUN gem update --system 4.1.0.beta2 --prerelease \
 && gem install cibuildgem -v 0.4.1 --no-document \
 && cargo install cargo-about --features cli --locked

ENV RELEASE=true
ENV RUSTFLAGS="-C target-feature=-crt-static"
