#!/usr/bin/env bash
set -euo pipefail

platform=$1
config="$HOME/.rake-compiler/config.yml"
mkdir -p "$(dirname "$config")"
: > "$config"

versions=()
for series in 3.2 3.3 3.4 4.0; do
  prefix="/opt/rubies/$series"
  mkdir -p "$prefix"
  crane export --platform "$platform" "ruby:$series-alpine3.23" - |
    tar -xf - -C "$prefix" --strip-components=2 usr/local

  LD_LIBRARY_PATH="$prefix/lib" "$prefix/bin/ruby" -rrbconfig -e '
    abort "Expected a musl Ruby" unless RUBY_PLATFORM.end_with?("-linux-musl")

    rbconfig = File.join(RbConfig::CONFIG.fetch("archdir"), "rbconfig.rb")
    puts "rbconfig-#{RUBY_PLATFORM}-#{RUBY_VERSION}: #{rbconfig}"
  ' >> "$config"
  versions+=("$(LD_LIBRARY_PATH="$prefix/lib" "$prefix/bin/ruby" -e 'print RUBY_VERSION')")
done

# Rake Compiler needs separate paths for the host Ruby and its target Rubies.
cp -a /opt/rubies/4.0/. /usr/local/
(
  IFS=:
  printf 'RUBY_CC_VERSION=%s\n' "${versions[*]}"
) >> "$GITHUB_ENV"
