#!/usr/bin/env bash
# The build Workers Builds runs on every merge to main (docs/hosting.md
# § deploys on merge). It is deploy-worker.sh's build steps on a machine
# that has no Zola: fetch the pinned release, run the two generators, build,
# write the redirects, finalize the links. The deploy itself is the next
# command there, `npx wrangler deploy`. On the Mac, use
# scripts/deploy-worker.sh instead.
#
#   scripts/ci-build.sh                      fetch Zola 0.22.1 for Linux and build
#   ZOLA=/path/to/zola scripts/ci-build.sh   build with a Zola already here
set -euo pipefail
cd "$(dirname "$0")/.."

ZOLA_VERSION=0.22.1
# sha256 of zola-v0.22.1-x86_64-unknown-linux-gnu.tar.gz, so a changed
# release file stops the build rather than running.
ZOLA_SHA256=0ca09aa40376aaa9ddfb512ff9ad963262ef95edb0d0f2d5ec6961b6f5cf22ef

# "Recently edited" reads each page's last commit (scripts/zola_paths.py), so
# a shallow checkout would date every page today. Fetch the rest, or stop.
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  git fetch --unshallow --quiet origin
fi

if [ -z "${ZOLA:-}" ]; then
  dir="$(mktemp -d)"
  curl -fsSL -o "$dir/zola.tar.gz" \
    "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
  echo "${ZOLA_SHA256}  $dir/zola.tar.gz" | sha256sum -c -
  tar -xzf "$dir/zola.tar.gz" -C "$dir"
  ZOLA="$dir/zola"
fi
case "$("$ZOLA" --version)" in
  "zola ${ZOLA_VERSION}") ;;
  *) echo "need zola ${ZOLA_VERSION}, found: $("$ZOLA" --version)" >&2; exit 1 ;;
esac

python3 scripts/update_recently_edited.py
python3 scripts/generate_site_index.py
"$ZOLA" build
# Reads the archive's public API; if it cannot, the build stops here and the
# live site stays as it was.
python3 scripts/redirects.py
python3 scripts/finalize_links.py

# A build with no front page or no redirects is not one to publish.
test -s public/index.html
test -s public/_redirects
