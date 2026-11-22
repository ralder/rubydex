#!/usr/bin/env bash
set -euo pipefail

config="$HOME/.rake-compiler/config.yml"
mkdir -p "$(dirname "$config")"
: > "$config"

shopt -s nullglob
versions=()
for prefix in /opt/rubies/*; do
  configs=("$prefix"/lib/ruby/*/*-linux-musl/rbconfig.rb)
  if (( ${#configs[@]} != 1 )); then
    echo "Expected one musl rbconfig.rb in $prefix" >&2
    exit 1
  fi

  rbconfig="${configs[0]}"
  config_dir=${rbconfig%/*}
  platform=${config_dir##*/}
  version=$(awk -F'"' '
    /^  CONFIG\["MAJOR"\]/ { major = $4 }
    /^  CONFIG\["MINOR"\]/ { minor = $4 }
    /^  CONFIG\["TEENY"\]/ { teeny = $4 }
    END {
      if (major == "" || minor == "" || teeny == "") exit 1
      print major "." minor "." teeny
    }
  ' "$rbconfig")
  printf 'rbconfig-%s-%s: %s\n' "$platform" "$version" "$rbconfig" >> "$config"
  versions+=("$version")
done

bundle install
(
  IFS=:
  export RUBY_CC_VERSION="${versions[*]}"
  cibuildgem package --include-single-abi
)

# The existing release builds already provide the platform-independent gem.
gem_version=$(ruby -r ./lib/rubydex/version -e 'print Rubydex::VERSION')
rm "pkg/rubydex-$gem_version.gem"
