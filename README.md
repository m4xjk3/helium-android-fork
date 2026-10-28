# Helium for Android

> Unofficial Android build of [Helium](https://helium.computer), based on
> [Titanium Browser for Android](https://github.com/jqssun/android-titanium-browser)
> and [Vanadium](https://github.com/GrapheneOS/Vanadium). Not affiliated with the
> Helium project.

Chromium-based browser for Android with full extension support: Chrome Web Store,
Opera Add-ons, Edge Add-ons, local CRX/ZIP and unpacked extensions.

**uBlock Origin is bundled and installed on first launch** (MV2, pinned version —
see `.gclient`).

Helium upstream ([imputnet/helium](https://github.com/imputnet/helium)) only ships
desktop builds. Android builds come from Chromium's `is_desktop_android` target,
which is what this fork uses. See the extension patch table in
[`docs/BUILD_ANDROID.md`](docs/BUILD_ANDROID.md).

## Installing extensions

- [Chrome Web Store](https://chromewebstore.google.com/) (recommended) — opens in
  desktop mode automatically;
- [Opera Add-ons](https://addons.opera.com/) and
  [Microsoft Edge Add-ons](https://microsoftedge.microsoft.com/addons/) — allowed
  by the off-store install patch;
- local `.crx`/`.zip` files;
- unpacked extension via `chrome://extensions` → **Developer mode** →
  **Load unpacked** (SAF picker).

To enable an extension in Incognito: `chrome://extensions` → **Details** →
**Allow in Incognito**.

## Building

Requirements, signing, secrets and the GitHub Actions workflow are described in
[`docs/BUILD_ANDROID.md`](docs/BUILD_ANDROID.md) (in Russian). Pinned component
versions are listed in [`docs/VERSIONS.md`](docs/VERSIONS.md).

Short version — publish this repo, then clone it with submodules:

```powershell
$env:GITHUB_TOKEN = "ghp_..."   # repo scope
./scripts/publish.ps1 -Public
```

```bash
git clone --recurse-submodules https://github.com/<you>/helium-android.git
cd helium-android
# add signing secrets, then run the "Build" workflow
```

Build output: `out/release/<version>-arm64-v8a.apk`, `...-armeabi-v7a.apk`,
`...-arm64-v8a.aab`.

## Differences from upstream Titanium

- package id `computer.helium.android`;
- user-visible strings rebranded to Helium at build time (`# brand: helium` in
  `patch.sh`);
- Helium app icon and Android 13+ themed icon (`res/`);
- bundled **uBlock Origin** instead of the Titanium extension
  (`fetch_ublock_origin` hook in `.gclient`);
- fork-friendly CI: manual runs, optional Vanadium update, Artifacts upload,
  ephemeral signing key fallback.

Internal `titanium` naming (GN targets, Java packages, config app) is kept on
purpose so the config integration keeps working.

## Credits

- [Vanadium](https://github.com/GrapheneOS/Vanadium) by GrapheneOS — the Android
  Chromium patchset this build is based on;
- [Titanium Browser for Android](https://github.com/jqssun/android-titanium-browser)
  — extension support patches, build scripts and CI;
- [Helium](https://github.com/imputnet/helium) — name, branding and design;
- [uBlock Origin](https://github.com/gorhill/uBlock) — bundled content blocker.

## License

GPL-2.0 for the downstream build scripts; imported patches keep their original
licenses (see `LICENSE` and the respective upstream repositories).
