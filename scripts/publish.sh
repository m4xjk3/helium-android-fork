#!/usr/bin/env bash
# Creates a GitHub repository and pushes this branch to it.
#
# Requires curl and a GitHub token with the "repo" scope:
#   export GITHUB_TOKEN=ghp_...
#
# Usage:
#   ./scripts/publish.sh            # private repo "helium-android"
#   ./scripts/publish.sh --public
#   ./scripts/publish.sh my-name

set -euo pipefail

repo="helium-android"
private=true
for arg in "$@"; do
  case "$arg" in
    --public) private=false ;;
    --private) private=true ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *) repo="$arg" ;;
  esac
done

: "${GITHUB_TOKEN:?set GITHUB_TOKEN with repo scope}"
[ -d .git ] || { echo "run from the repository root" >&2; exit 1; }

api() {
  curl -fsS -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: helium-android-publish" \
    -H "X-GitHub-Api-Version: 2022-11-28" "$@"
}

owner=$(api https://api.github.com/user | sed -n 's/.*"login": *"\([^"]*\)".*/\1/p' | head -n1)
echo "GitHub user: $owner"

payload=$(printf '{"name":"%s","private":%s,"description":"Unofficial Helium browser for Android with extension support"}' "$repo" "$private")
if api -o /dev/null -X POST https://api.github.com/user/repos \
      -H "Content-Type: application/json" -d "$payload"; then
  echo "Created repository $owner/$repo"
else
  echo "Repository $owner/$repo already exists (or create failed), pushing."
fi

url="https://github.com/$owner/$repo.git"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$url"
else
  git remote add origin "$url"
fi

basic=$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')
git -c "http.extraheader=AUTHORIZATION: basic $basic" push -u origin HEAD:main

# Never leave the token in .git/config.
git remote set-url origin "$url"

echo
echo "Pushed to $url"
echo "Next: add signing secrets, then run the Build workflow."
echo "See docs/BUILD_ANDROID.md"
