# Pinned versions

Everything the build depends on is pinned so that the same commit produces the
same browser, and updates are explicit.

| Component | Version | Where |
| --- | --- | --- |
| Chromium | `156.0.8078.73` | taken from `vanadium/args.gn` (`android_default_version_name`) by `build.sh` |
| Vanadium | tag `156.0.8078.73.0`, commit `8ae4b1b8b014862146ff9a09dc8c6fc6e9a0a978` | git submodule `vanadium` |
| uBlock Origin | `1.75.0` (`uBlock0_1.75.0.chromium.crx`, MV2) | `fetch_ublock_origin` hook in `.gclient` |
| Android package | `computer.helium.android` | `args.gn` |

## Updating

1. **Vanadium / Chromium**: check out a newer tag in the submodule, commit the
   gitlink, and make sure `build.sh` picks up the new Chromium version:
   ```bash
   cd vanadium
   git fetch --tags
   git checkout "$(git tag | sort -V | tail -n1)"
   cd ..
   git add vanadium
   git commit -m "vanadium: bump to <tag>"
   ```
   The workflow input `update_vanadium` does the same for a single run without
   committing.
2. **uBlock Origin**: change the URL in `.gclient` to
   `https://github.com/gorhill/uBlock/releases/download/<version>/uBlock0_<version>.chromium.crx`
   and update this table.
3. **Package id / branding**: see [`docs/BUILD_ANDROID.md`](BUILD_ANDROID.md).

## Reproducibility notes

- `.github/workflows/build.yml` never updates Vanadium unless asked.
- The bundled CRX is downloaded by URL at `gclient sync` time. If the URL ever
  disappears, download the CRX, commit it to a release/mirror, and point the hook
  there.
- Signing keys are not part of the repo. Without them, the build generates an
  ephemeral key, so such APKs cannot be updated in place.
